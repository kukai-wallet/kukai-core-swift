//
//  TzKTClient.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 18/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import SignalRClient
import Combine
import Kingfisher
import os.log


/// TzKT is an indexer for Tezos, who's API allows developers to query details about wallets, and transactions
public class TzKTClient {
	
	/// Unique Errors that TzKTClient can throw
	public enum TzKTServiceError: Error {
		case invalidURL
		case parseError(String)
	}
	
	public struct Constants {
		public static let tokenBalanceQuerySize = 10000
		public static let ipfsImageMappingCacheFileName = "tzktclient-ipfs-image-mapping-cache"
	}
	
	public struct ImageUrlCacheObj: Codable {
		public var thumbnail: URL?
		public var display: URL?
	}
	
	private let networkService: NetworkService
	private let config: TezosNodeClientConfig
	private let betterCallDevClient: BetterCallDevClient
	private var currentWalletAddress: String = ""
	private var supportedTokens: [Token] = []
	
	private var transactionHistory: [TimeInterval: [TzKTTransaction]] = [:]
	private var tempTransactions: [TzKTTransaction] = []
	private var dispatchGroupTransactions = DispatchGroup()
	private let tokenBalanceQueue: DispatchQueue
	
	private var signalrConnection: HubConnection? = nil
	private var addressToWatch: String = ""
	
	@Published public var accountDidChange: Bool = false
	
	
	
	// MARK: - Init
	
	/**
	Init a `TzKTClient` with a `NetworkService` and a `TezosNodeClientConfig` and a `BetterCallDevClient`.
	- parameter networkService: `NetworkService` used to manage network communication.
	- parameter config: `TezosNodeClientConfig` used to apss in settings.
	- parameter betterCallDevClient: `BetterCallDevClient` used to fetch more detailed errors about operation failures involving smart contracts.
	*/
	public init(networkService: NetworkService, config: TezosNodeClientConfig, betterCallDevClient: BetterCallDevClient) {
		self.networkService = networkService
		self.config = config
		self.betterCallDevClient = betterCallDevClient
		self.tokenBalanceQueue = DispatchQueue(label: "TzKTClient.tokens", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
	}
	
	
	
	
	
	// MARK: - Storage
	
	/**
	 Get the storage of a given contract and parse it to a supplied model type
	 - parameter forContract: The KT1 contract address to query
	 - parameter ofType: The Codable compliant model to parse the response as
	 - parameter completion: A completion block called, returning a Swift Result type
	 */
	public func getStorage<T: Codable>(forContract contract: String, ofType: T.Type, completion: @escaping ((Result<T, ErrorResponse>) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/contracts/\(contract)/storage")
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: T.self, completion: completion)
	}
	
	/**
	 Get the keys of a big map, by ID and parse it to a model
	 - parameter forId: The numeric ID of the big map
	 - parameter ofType: The Codable compliant model to parse the response as
	 - parameter completion: A completion block called, returning a Swift Result type
	 */
	public func getBigMap<T: Codable>(forId id: String, ofType: T.Type, completion: @escaping ((Result<T, ErrorResponse>) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/bigmaps/\(id)/keys")
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: T.self, completion: completion)
	}
	
	/**
	 Get the keys of a big map, but filtered to only one specific key. Parse the response as the supplied model
	 - parameter forId: The numeric ID of the big map
	 - parameter key: The key to filter by
	 - parameter ofType: The Codable compliant model to parse the response as
	 - parameter completion: A completion block called, returning a Swift Result type
	 */
	public func getBigMapKey<T: Codable>(forId id: String, key: String, ofType: T.Type, completion: @escaping ((Result<T, ErrorResponse>) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/bigmaps/\(id)/keys")
		url.appendQueryItem(name: "key", value: key)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: T.self, completion: completion)
	}
	
	
	
	
	
	// MARK: - Block checker
	
	/**
	Query details about the given operation
	- parameter byHash: The operation hash to query.
	- parameter completion: A completion colsure called when the request is done.
	*/
	public func getOperation(byHash hash: String, completion: @escaping (([TzKTOperation]?, ErrorResponse?) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/operations/" + hash)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTOperation].self) { (result) in
			switch result {
				case .success(let operations):
					completion(operations, nil)
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Parse error: %@", "\(error)")
					completion(nil, ErrorResponse.unknownParseError(error: error))
			}
		}
	}
	
	
	
	
	
	// MARK: - Account monitoring
	
	/**
	 Open a websocket connection to request a notification for any changes to the given account. The @Published var `accountDidChange` will be notified if something occurs
	 - parameter address: The Tz address of the account to monitor
	 */
	public func listenForAccountChanges(address: String) {
		addressToWatch = address
		
		var url = config.tzktURL
		url.appendPathComponent("v1/events")
		
		if config.loggingConfig.logNetworkSuccesses {
			signalrConnection = HubConnectionBuilder(url: url).withLogging(minLogLevel: .debug).build()
		} else {
			signalrConnection = HubConnectionBuilder(url: url).build()
		}
		
		
		// Register for SignalR operation events
		signalrConnection?.on(method: "accounts", callback: { [weak self] argumentExtractor in
			do {
				let obj = try argumentExtractor.getArgument(type: AccountSubscriptionResponse.self)
				os_log("Incoming object parsed: %@", log: .tzkt, type: .debug, "\(obj)")
				
				if obj.data != nil {
					self?.accountDidChange = true
				}
				
			} catch (let error) {
				os_log("Failed to parse incoming websocket data: %@", log: .tzkt, type: .error, "\(error)")
				self?.signalrConnection?.stop()
				//completion(false, error, ErrorResponse.unknownParseError(error: error))
			}
		})
		signalrConnection?.delegate = self
		signalrConnection?.start()
	}
	
	/**
	 Close the websocket from `listenForAccountChanges`
	 */
	public func stopListeningFOrAccountChanges() {
		os_log(.debug, log: .kukaiCoreSwift, "Cancelling listenForAccountChanges")
		signalrConnection?.stop()
	}
	
	
	
	
	
	// MARK: - Balances
	
	public func getBalanceCount(forAddress: String, completion: @escaping (Result<Int, ErrorResponse>) -> Void) {
		var url = config.tzktURL
		url.appendPathComponent("v1/tokens/balances/count")
		url.appendQueryItem(name: "account", value: forAddress)
		url.appendQueryItem(name: "balance.gt", value: 0)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: Int.self) { (result) in
			completion(result)
		}
	}
	
	public func getBalancePage(forAddress: String, offset: Int = 0, completion: @escaping ((Result<[TzKTBalance], ErrorResponse>) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/tokens/balances")
		url.appendQueryItem(name: "account", value: forAddress)
		url.appendQueryItem(name: "balance.gt", value: 0)
		url.appendQueryItem(name: "offset", value: offset * TzKTClient.Constants.tokenBalanceQuerySize)
		url.appendQueryItem(name: "limit", value: TzKTClient.Constants.tokenBalanceQuerySize)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTBalance].self) { (result) in
			completion(result)
		}
	}
	
	public func getAccount(forAddress: String, completion: @escaping ((Result<TzKTAccount, ErrorResponse>) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/accounts/\(forAddress)")
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: TzKTAccount.self) { (result) in
			completion(result)
		}
	}
	
	public func getAllBalances(forAddress address: String, completion: @escaping ((Result<Account, ErrorResponse>) -> Void)) {
		getBalanceCount(forAddress: address) { [weak self] result in
			guard let tokenCount = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			// Calculate the number of pages that will needed to be queried to fetch all the token balances
			let numberOfPages = Int(tokenCount / TzKTClient.Constants.tokenBalanceQuerySize)
			let hasRemainder = (tokenCount % TzKTClient.Constants.tokenBalanceQuerySize) > 0
			let totalNumberOfPages = numberOfPages + (hasRemainder ? 1 : 0)
			
			// Call the private func for fetching and grouping balances
			self?.getAllBalances(forAddress: address, numberOfPages: totalNumberOfPages, completion: completion)
		}
	}
	
	private func getAllBalances(forAddress address: String, numberOfPages: Int, completion: @escaping ((Result<Account, ErrorResponse>) -> Void)) {
		let dispatchGroup = DispatchGroup()
		
		var xtzBalance = XTZAmount.zero()
		var tokenBalances: [TzKTBalance] = []
		var errorFound: ErrorResponse? = nil
		var groupedData: (tokens: [Token], nftGroups: [Token]) = (tokens: [], nftGroups: [])
		
		
		// Get XTZ balance from TzKT Account
		dispatchGroup.enter()
		self.getAccount(forAddress: address) { result in
			switch result {
				case .success(let account):
					xtzBalance = account.xtzBalance
					
				case .failure(let error):
					errorFound = error
			}
			dispatchGroup.leave()
		}
		
		
		// Cycle through the number of token balance requests needed to be performed (likely just 1)
		for index in 0..<numberOfPages {
			dispatchGroup.enter()
			tokenBalanceQueue.async { [weak self] in
				self?.getBalancePage(forAddress: address, offset: index, completion: { tokenResult in
					switch tokenResult {
						case .failure(let error):
							errorFound = error
							
						case .success(let balances):
							tokenBalances.append(contentsOf: balances)
					}
					
					dispatchGroup.leave()
				})
			}
		}
		
		// When all requests finished, return on main thread
		dispatchGroup.notify(queue: .main) { [weak self] in
			if let err = errorFound {
				completion(Result.failure(err))
				
			} else {
				groupedData = self?.groupBalances(tokenBalances) ?? (tokens: [], nftGroups: [])
				
				self?.fetchImageUrls(forTokens: groupedData.tokens, andNFTs: groupedData.nftGroups) { [weak self] updatedData in
					groupedData.tokens = updatedData.tokens
					groupedData.nftGroups = updatedData.nfts
					
					
					self?.downloadTokenIconsAndNFTGroups(tokens: groupedData.tokens, nftGroups: groupedData.nftGroups, completion: { success in
						let account = Account(walletAddress: address, xtzBalance: xtzBalance, tokens: groupedData.tokens, nfts: groupedData.nftGroups)
						
						// Finished, call completion success
						DispatchQueue.main.async { completion(Result.success(account)) }
					})
				}
			}
		}
	}
	
	private func groupBalances(_ balances: [TzKTBalance]) -> (tokens: [Token], nftGroups: [Token]) {
		var tokens: [Token] = []
		var nftGroups: [Token] = []
		var tempNFT: [String: [TzKTBalance]] = [:]
		
		for balance in balances {
			
			// If its an NFT, hold onto for later
			if balance.isNFT() {
				if tempNFT[balance.token.contract.address] == nil {
					tempNFT[balance.token.contract.address] = [balance]
				} else {
					tempNFT[balance.token.contract.address]?.append(balance)
				}
				continue
			}
			
			// Else create a Token object and put into array
			let token = Token(
				name: balance.token.metadata?.name ?? "",
				symbol: balance.token.metadata?.symbol ?? "",
				tokenType: .fungible,
				faVersion: balance.token.standard,
				balance: balance.tokenAmount,
				thumbnailURI: URL(string: balance.token.metadata?.thumbnailUri ?? ""),
				tokenContractAddress: balance.token.contract.address,
				tokenId: Decimal(string: balance.token.tokenId) ?? 0,
				nfts: []
			)
			
			tokens.append(token)
		}
		
		// Take NFT's, create actual NFT objects and add them to `Token` instances
		for nftArray in tempNFT.values {
			guard let first = nftArray.first else {
				continue
			}
			
			var temp: [NFT] = []
			for balance in nftArray {
				temp.append(NFT(fromTzKTBalance: balance))
			}
			
			let nftToken = Token(
				name: first.token.contract.alias ?? first.token.contract.address,
				symbol: first.token.metadata?.symbol ?? "",
				tokenType: .nonfungible,
				faVersion: first.token.standard,
				balance: TokenAmount.zero(),
				thumbnailURI: URL(string: first.token.metadata?.thumbnailUri ?? ""),
				tokenContractAddress: first.token.contract.address,
				tokenId: Decimal(string: first.token.tokenId) ?? 0,
				nfts: temp
			)
			
			let staticNFTData = OfflineConstants.dappDisplayName(forContractAddress: first.token.contract.address, onChain: config.tezosChainName)
			nftToken.thumbnailURL = staticNFTData.thumbnail
			
			nftGroups.append(nftToken)
		}
		
		return (tokens: tokens, nftGroups: nftGroups)
	}
	
	// NFT display and thumbnail URLS need to be processed, and extremely likely converted into URLs pointing to a cache server
	private func fetchImageUrls(forTokens tokens: [Token], andNFTs nfts: [Token], completion: @escaping (((tokens: [Token], nfts: [Token])) -> Void)) {
		let dispatchGroup = DispatchGroup()
		
		// Load the current cached images to avoid unnecessary fetching
		var imageURLsToCache: [String: ImageUrlCacheObj] = [:]
		if let cachedURLs = DiskService.read(type: [String: ImageUrlCacheObj].self, fromFileName: TzKTClient.Constants.ipfsImageMappingCacheFileName) {
			imageURLsToCache = cachedURLs
		}
		
		let updatedTokens: [Token] = tokens
		let updatedNFts: [Token] = nfts
		
		
		// Check for Token Icons
		dispatchGroup.enter()
		for (index, token) in updatedTokens.enumerated() {
			dispatchGroup.enter()
			
			// Load the cached version first if applicable
			guard imageURLsToCache[token.id] == nil else {
				updatedTokens[index].thumbnailURL = imageURLsToCache[token.id]?.thumbnail
				dispatchGroup.leave()
				continue
			}
			
			// Else fetch the mapped URL
			imageURL(fromIpfsUri: token.thumbnailURI) { [weak self] thumbnailURL in
				let newURL = (thumbnailURL == nil) ? self?.avatarURL(forToken: token.tokenContractAddress ?? "") : thumbnailURL
				
				imageURLsToCache[token.id]?.thumbnail = newURL
				updatedTokens[index].thumbnailURL = newURL
				dispatchGroup.leave()
			}
		}
		
		
		// Check for NFT thumbnails and display images
		dispatchGroup.enter()
		for (outerIndex, nftParent) in updatedNFts.enumerated() {
			for (innerIndex, nftChild) in (nftParent.nfts ?? []).enumerated() {
				dispatchGroup.enter()
				dispatchGroup.enter()
				
				// Load the cached versions first if applicable
				guard imageURLsToCache[nftChild.id] == nil else {
					let obj = imageURLsToCache[nftChild.id]
					updatedNFts[outerIndex].nfts?[innerIndex].displayURL = obj?.display
					updatedNFts[outerIndex].nfts?[innerIndex].thumbnailURL = obj?.thumbnail
					dispatchGroup.leave()
					dispatchGroup.leave()
					continue
				}
				
				
				// Else fetch the mapped URLs
				imageURL(fromIpfsUri: nftChild.displayURI) { displayURL in
					updatedNFts[outerIndex].nfts?[innerIndex].displayURL = displayURL
					imageURLsToCache[nftChild.id]?.display = displayURL
					dispatchGroup.leave()
				}
				
				imageURL(fromIpfsUri: nftChild.thumbnailURI) { thumbnailURL in
					updatedNFts[outerIndex].nfts?[innerIndex].thumbnailURL = thumbnailURL
					imageURLsToCache[nftChild.id]?.thumbnail = thumbnailURL
					dispatchGroup.leave()
				}
			}
		}
		
		dispatchGroup.leave()
		dispatchGroup.leave()
		
		// When all requests finished, return on main thread
		dispatchGroup.notify(queue: .main) {
			let _ = DiskService.write(encodable: imageURLsToCache, toFileName: TzKTClient.Constants.ipfsImageMappingCacheFileName)
			completion((tokens: updatedTokens, nfts: updatedNFts))
		}
	}
	
	public func deleteIpfsImageMappingCache() -> Bool {
		return DiskService.delete(fileName: TzKTClient.Constants.ipfsImageMappingCacheFileName)
	}
	
	/**
	 Convert the IPFS URI, into a cloudflare URL, pass this URL to the Kukai metadata cache service to extract info about the asset. If a non IPFS URI is passed in, it is simply returned
	 If all goes well, a URL to the asset cached on Kukai's server will be returned
	 - parameter fromIpfsUri: The IPFS URI to the given asset
	 - parameter ofSize: Optional, the size string of the asset to query (e.g. "150x150")
	 - parameter completion: Block returning a new URL if possible
	 */
	private func imageURL(fromIpfsUri uri: URL?, ofSize: String = "150x150", completion: @escaping ((URL?) -> Void)) {
		guard let uri = uri else {
			completion(nil)
			return
		}
		
		if String(uri.absoluteString.prefix(5)) == "https" {
			completion(uri)
			return
		}
		
		if String(uri.absoluteString.prefix(10)) == "data:image" {
			completion(uri)
			return
		}
		
		guard let cloudflareURL = ipfsURIToCloudflareURL(uri: uri) else {
			completion(nil)
			return
		}
		
		ipfsKukaiMetadata(url: cloudflareURL) { result in
			guard let metadata = try? result.get(),
				  let filename = metadata.Filename,
				  let ext = metadata.Extension,
				  let fileURL = URL(string: "https://backend.kukai.network/file/\(filename)_\(ofSize).\(ext)") else {
					  completion(nil)
					  return
				  }
			
			completion(fileURL)
		}
	}
	
	/**
	 Cloudflare provides an IPFS gateway, take the IPFS URL and reformat to work with cloudflares URL structure
	 */
	private func ipfsURIToCloudflareURL(uri: URL) -> URL? {
		if let strippedURI = uri.absoluteString.components(separatedBy: "ipfs://").last, let url = URL(string: "https://cloudflare-ipfs.com/ipfs/\(strippedURI)") {
			return url
		}
		
		return nil
	}
	
	/**
	 Get cached metadata file from Kukai's backend
	 */
	private func ipfsKukaiMetadata(url: URL, completion: @escaping ((Result<IpfsKukaiMetadata, ErrorResponse>) -> Void)) {
		guard let destinationURL = URL(string: "https://backend.kukai.network/file/info?src=\(url.absoluteString)") else {
			os_log("Invalid URL: %@", log: .bcd, type: .error, url.absoluteString)
			completion(Result.failure(ErrorResponse.unknownError()))
			return
		}
		
		networkService.request(url: destinationURL, isPOST: false, withBody: nil, forReturnType: IpfsKukaiMetadata.self) { result in
			switch result {
				case .success(let metadata):
					if metadata.Status == "ok" && metadata.Filename != nil && metadata.Extension != nil && metadata.Extension != "unknown" {
						completion(Result.success(metadata))
					} else {
						os_log("kukai metadata backend returned a status that was not \"ok\"", log: .bcd, type: .error)
						completion(Result.failure(ErrorResponse.unknownError()))
					}
					
				case .failure(let error):
					completion(Result.failure(error))
			}
		}
	}
	
	/**
	 In order to access the cached images, you need the URL it was downloaded from. This can either be found inside the `Token` objects returned as part of `Account` from the `fetchAccountInfo` func.
	 Or, if you need to use it seperately, given the token address you can use this function
	 - parameter forToken: The token address who's image you are looking for.
	 */
	public func avatarURL(forToken token: String) -> URL? {
		guard let imageURL = URL(string: "https://services.tzkt.io/v1/avatars/\(token)") else {
			return nil
		}
		
		return imageURL
	}
	
	/**
	 Use `Kingfisher` to bulk download the token icons for all the tokens the user owns, allowing them to be called much easier.
	 Developers can use https://github.com/onevcat/Kingfisher to display the images then throughout the app.
	 E.g.  `imageView.kf.setImage(with: URL)`
	 */
	private func downloadTokenIconsAndNFTGroups(tokens: [Token], nftGroups: [Token], completion: @escaping ((Bool) -> Void)) {
		var imageURLs: [URL] = []
		
		for token in tokens {
			if let url = token.thumbnailURL {
				imageURLs.append(url)
			}
		}
		
		for nftGroup in nftGroups {
			if let url = nftGroup.thumbnailURL {
				imageURLs.append(url)
			}
		}
		
		if imageURLs.count == 0 {
			completion(true)
			return
		}
		
		// Don't donwload real images during unit tests. Investigate mocking kingfisher
		if Thread.current.isRunningXCTest {
			completion(true)
			return
		}
		
		
		// Set expiration and pre-fetch
		ImageCache.default.diskStorage.config.expiration = .days(7)
		ImagePrefetcher(urls: imageURLs, options: nil, progressBlock: nil) { (skipped, failed, completed) in
			os_log(.debug, log: .bcd, "Token icons downloaded")
			
			if !skipped.isEmpty {
				os_log(.error, log: .bcd, "Some images skipped")
			}
			
			if !failed.isEmpty {
				os_log(.error, log: .bcd, "Some images failed")
			}
			
			completion(true)
			
		}.start()
	}
	
	
	
	
	
	// MARK: - Transaction History
	
	/**
	Clear the in RAM copy of transaction history
	*/
	public func clearHistory() {
		transactionHistory = [:]
	}
	
	/**
	Get the current in RAM transation history, with optional filters
	- parameter filterByToken: only retuns transactions where the primary or secondary token is of this type.
	- parameter orFilterByAddress: only retuns transactions where the source or destination address matches this string
	- returns transactions grouped by day in a dictionary with a key of `TimeInterval`.
	*/
	public func currentTransactionHistory(filterByToken: Token?, orFilterByAddress: String?) -> [TimeInterval: [TzKTTransaction]] {
		
		// Anything involving the given token
		if let filterToken = filterByToken {
			return transactionHistory.mapValues {
				$0.filter {
					return ($0.secondaryToken?.symbol == filterToken.symbol || $0.token?.symbol == filterToken.symbol)
				}
			}.filter { !$0.value.isEmpty }
		}
		
		// Anything sent or recieved by the given address
		if let filterAddress = orFilterByAddress {
			return transactionHistory.mapValues {
				$0.filter {
					return ($0.sender.address == filterAddress || $0.target?.address == filterAddress || $0.newDelegate?.address == filterAddress)
				}
			}.filter { !$0.value.isEmpty }
		}
		
		// else return everything
		return transactionHistory
	}
	
	/**
	Query the lastest transaction history and store in RAM. Get access to the data via `currentTransactionHistory(...)`
	- parameter forAddress: the wallet address to query the history for.
	- parameter andSupportedTokens: a list of known tokens, used to add more detail to the transaction objects.
	- parameter completion: a closure indicating the request and processing has finished.
	*/
	public func refreshTransactionHistory(forAddress address: String, andSupportedTokens: [Token], completion: @escaping (() -> Void)) {
		self.currentWalletAddress = address
		self.supportedTokens = andSupportedTokens
		
		var url = config.tzktURL
		url.appendPathComponent("v1/accounts/\(address)/operations")
		url.appendQueryItem(name: "type", value: "delegation,origination,transaction,reveal")
		
		self.dispatchGroupTransactions = DispatchGroup()
		tempTransactions = []
		
		
		// Fetch "Account Transactions" from TZKT. Currently includes everything except Native Token Receives
		self.dispatchGroupTransactions.enter()
		self.dispatchGroupTransactions.enter()
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTTransaction].self) { [weak self] (result) in
			switch result {
				case .success(let transactions):
					self?.tempTransactions = transactions
					self?.queryNativeTokenReceives(forAddress: address, lastTransaction: self?.tempTransactions.last)
					self?.dispatchGroupTransactions.leave()
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Parse error full: %@", "\(error)")
					self?.dispatchGroupTransactions.leave()
					self?.dispatchGroupTransactions.leave()
			}
		}
		
		
		// When both done, add the arrays, re-sort and pass it to the parse function to create the transactionHistory object
		self.dispatchGroupTransactions.notify(queue: .main) { [weak self] in
			self?.tempTransactions.sort { $0.level > $1.level }
			
			self?.parseTransactions(self?.tempTransactions)
			self?.tempTransactions = []
			completion()
		}
	}
	
	/**
	Private helper function to seperately query the FA token recieve events
	*/
	private func queryNativeTokenReceives(forAddress address: String, lastTransaction: TzKTTransaction?) {
		// Fetch Native Token Receives using a separate request
		var url = config.tzktURL
		url.appendPathComponent("v1/operations/transactions")
		url.appendQueryItem(name: "entrypoint", value: "transfer")
		url.appendQueryItem(name: "parameter.to", value: "\(address)")
		url.appendQueryItem(name: "initiator.null", value: nil) // filter out duplicates from Dexter send events
		url.appendQueryItem(name: "sort.desc", value: "level")
		
		if let transaction = lastTransaction {
			url.appendQueryItem(name: "timestamp.gt", value: "\(transaction.timestamp)")
		} else {
			url.appendQueryItem(name: "limit", value: "25")
		}
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTTransaction].self) { [weak self] (result) in
			switch result {
				case .success(let transactions):
					self?.tempTransactions.append(contentsOf: transactions)
					self?.dispatchGroupTransactions.leave()
	
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Transaction history native token error: %@", "\(error)")
					self?.dispatchGroupTransactions.leave()
			}
		}
	}
	
	/**
	Private helper function to parse and process the JSON data into more useful objects
	*/
	private func parseTransactions(_ transactions: [TzKTTransaction]?) {
		guard let transactions = transactions else {
			return
		}
		
		// Add additional data to transactions so that we can group / merge to make them easier to understand for users
		self.transactionHistory = [:]
		var transactionsToBeMerged: [TzKTTransaction] = []
		var transactionToAdd: TzKTTransaction? = nil
		
		// Loop through transactions to determine which need to be displayed, and which need to be merged
		for (index, transaction) in transactions.enumerated() {
			transaction.augmentTransaction(withUsersAddress: currentWalletAddress, andTokens: supportedTokens)
			transactionToAdd = nil
			
			// If there is another transaction, check if counters match. If so, store for merging with next transaction (or next again)
			if let nextTransaction = transactions[safe: index+1], transaction.counter == nextTransaction.counter {
				transactionsToBeMerged.append(transaction)
				continue
			}
			
			// If current transaction is .exchangeXtzToToken or .exchangeTokenToXTZ, grab missing info from `transactionsToBeMerged`
			if transaction.subType == .exchangeXTZToToken {
				guard let tokenReceiveTransaction = transactionsToBeMerged.last else {
					transactionsToBeMerged = []
					continue
				}
				
				transaction.secondaryToken = tokenReceiveTransaction.token
				transaction.secondaryAmount = tokenReceiveTransaction.amount
				
				// Clean merged list
				transactionsToBeMerged = []
				transactionToAdd = transaction
				
			} else if transaction.subType == .exchangeTokenToXTZ {
				guard transactionsToBeMerged.count == 2,
					  let subTransaction1 = transactionsToBeMerged[safe: 0],
					  let subTransaction1Token = subTransaction1.token,
					  let subTransaction2 = transactionsToBeMerged[safe: 1] else {
					transactionsToBeMerged = []
					continue
				}
				
				let xtzReceivedTransaction = subTransaction1Token.tokenType == .xtz ? subTransaction1 : subTransaction2
				let tokenDeductedTransaction = subTransaction1Token.tokenType == .xtz ? subTransaction2 : subTransaction1
				
				transaction.token = tokenDeductedTransaction.token
				transaction.amount = tokenDeductedTransaction.amount
				transaction.secondaryToken = xtzReceivedTransaction.token
				transaction.secondaryAmount = xtzReceivedTransaction.amount
				
				// Clean merged list
				transactionsToBeMerged = []
				transactionToAdd = transaction
				
			} else if transaction.subType == .approve {
				
				// Approves happen behind the scenes as a security measure for other operations (e.g. Exchanges).
				// User only cares about the network fee incured. Add to transaction before this one and skip displaying this operation
				if let previousTransaction = transactions[safe: index-1] {
					let tempTransaction = self.transactionHistory[previousTransaction.truncatedTimeInterval]?.last
					tempTransaction?.bakerFee += transaction.bakerFee
					tempTransaction?.storageFee += transaction.storageFee
					tempTransaction?.allocationFee += transaction.allocationFee
					
				} else {
					// If we can't find a previous transaction, then display the approve
					transactionToAdd = transaction
				}
				
			} else {
				transactionToAdd = transaction
			}
			
			
			// add to transaction history array
			guard let transToAdd = transactionToAdd else {
				continue
			}
			
			if self.transactionHistory[transToAdd.truncatedTimeInterval] == nil {
				self.transactionHistory[transToAdd.truncatedTimeInterval] = [transToAdd]
			} else {
				self.transactionHistory[transToAdd.truncatedTimeInterval]?.append(transToAdd)
			}
		}
	}
}

extension TzKTClient: HubConnectionDelegate {
	
	public func connectionDidOpen(hubConnection: HubConnection) {
		
		// Request to be subscribed to events belonging to the given account
		let subscription = AccountSubscription(addresses: [addressToWatch])
		signalrConnection?.invoke(method: "SubscribeToAccounts", subscription) { [weak self] error in
			if let error = error {
				os_log("Subscribe to account changes failed: %@", log: .tzkt, type: .error, "\(error)")
				self?.signalrConnection?.stop()
			} else {
				os_log("Subscribe to account changes succeeded, waiting for objects", log: .tzkt, type: .debug)
			}
		}
	}
	
	public func connectionDidClose(error: Error?) {
		os_log("SignalR connection closed: %@", log: .tzkt, type: .debug, String(describing: error))
	}
	
	public func connectionDidFailToOpen(error: Error) {
		os_log("Failed to open SignalR connection to listen for changes: %@", log: .tzkt, type: .error, "\(error)")
	}
}
