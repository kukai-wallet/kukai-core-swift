//
//  BetterCallDevClient.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 27/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import Kingfisher
import os.log

/// BetterCallDev (BCD) is an indexing/smart contract debugging tool, used for the Tezos blockchain.
/// This class allows developers to interact with their API, to fetch data that would otherwise be impossible for a mobile app
public class BetterCallDevClient {
	
	/// Dedicated BCD errors
	public enum BetterCallDevClientError: Error {
		case invalidURL
		case parseError(String)
	}
	
	/// Constants for dealing with BCD API and cached data
	public struct Constants {
		public static let tokenBalanceQuerySize = 50
		public static let tokenMetadataFilename = "bcd-token_metadata"
		public static let parsedAccountFilename = "bcd-parsed_account"
		public static let accountHashFilename = "bcd-account_hash"
	}
	
	/// The networking service used to fire requests
	private let networkService: NetworkService
	
	/// The config used for URL's and logging
	private let config: TezosNodeClientConfig
	
	/// Queue used for fetching token balances
	private let tokenBalanceQueue: DispatchQueue
	
	/// Queue used for fetching token metadata
	private let metadataQueue: DispatchQueue
	
	/// Queue used for converting ipfs URLs into urls pointing to cached image assets
	private let nftImageURLQueue: DispatchQueue
	
	
	
	
	
	// MARK: - Init
	
	/**
	Init a `BetterCallDevClient` with a `NetworkService` and a `TezosNodeClientConfig`.
	- parameter networkService: `NetworkService` used to manage network communication.
	- parameter config: `TezosNodeClientConfig` used to apss in settings.
	*/
	public init(networkService: NetworkService, config: TezosNodeClientConfig) {
		self.networkService = networkService
		self.config = config
		self.tokenBalanceQueue = DispatchQueue(label: "BetterCallDevClient.tokens", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
		self.metadataQueue = DispatchQueue(label: "BetterCallDevClient.metadata", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
		self.nftImageURLQueue = DispatchQueue(label: "BetterCallDevClient.nft-image", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
	}
	
	
	
	
	
	// MARK: - Errors
	
	/**
	Primarily the `TzKTClient` is used to fetch details on operations. However for more complex calls involving smart contracts, TzKT will only return limited error message info.
	BetterCallDev includles all the details needed to display messages. This function allows developers to query the detailed error message.
	- parameter byHash: The hash String of the operation.
	- parameter completion: Called with the result.
	*/
	public func getMoreDetailedError(byHash hash: String, completion: @escaping ((BetterCallDevOperationError?, ErrorResponse?) -> Void)) {
		var url = config.betterCallDevURL
		url.appendPathComponent("v1/opg/" + hash)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [BetterCallDevOperation].self) { (result) in
			switch result {
				case .success(let operations):
					for op in operations {
						if let moreDetailedError = op.moreDetailedError() {
							completion(moreDetailedError, nil)
							return
						}
					}
					
					completion(nil, nil)
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Parse error: %@", "\(error)")
					completion(nil, ErrorResponse.unknownParseError(error: error))
			}
		}
	}
	
	
	
	
	
	// MARK: - Account / Balances
	
	/**
	Fetches `v1/account/<network>/<address>` and returns the result. `<network>` is handled automatically by the config object passed into the constructor.
	This call returns information about the wallet such as its XTZ balance.
	- parameter forAddress: The address of the wallet to fetch info for.
	- parameter completion: Called when call finished.
	*/
	public func account(forAddress address: String, completion: @escaping ((Result<BetterCallDevAccount, ErrorResponse>) -> Void)) {
		var url = config.betterCallDevURL
		url.appendPathComponent("v1/account/\(config.tezosChainName.rawValue)/\(address)")
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: BetterCallDevAccount.self, completion: completion)
	}
	
	/**
	Fetches `v1/account/<network>/<address>/count` and returns the result. `<network>` is handled automatically by the config object passed into the constructor.
	This call returns a list of every token contract address that the given wallet owns at least 1 of. The request also includes the number of instances the user owns.
	For fungible tokens, the number will always be 1. For non-fungible, the number will the count of how many of this NFT collection the user owns
	- parameter forAddress: The address of the wallet to fetch info for.
	- parameter completion: Called when call finished.
	*/
	public func accountTokenCount(forAddress address: String, completion: @escaping ((Result<[String: Int], ErrorResponse>) -> Void)) {
		var url = config.betterCallDevURL
		url.appendPathComponent("v1/account/\(config.tezosChainName.rawValue)/\(address)/count")
		url.appendQueryItem(name: "hide_empty", value: "true")
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [String: Int].self, completion: completion)
	}
	
	/**
	Fetches `v1/account/<network>/<address>/token_balances` and returns the result. `<network>` is handled automatically by the config object passed into the constructor.
	This call returns a page of up to 10 token balances, that the user owns. It will contain both fungible and non-fungible, there is no way to request these separately.
	- parameter forAddress: The address of the wallet to fetch info for.
	- parameter offset: The page number to request.
	- parameter completion: Called when call finished.
	*/
	public func tokenBalances(forAddress address: String, offset: Int = 0, completion: @escaping ((Result<BetterCallDevTokenBalances, ErrorResponse>) -> Void)) {
		var url = config.betterCallDevURL
		url.appendPathComponent("v1/account/\(config.tezosChainName.rawValue)/\(address)/token_balances")
		url.appendQueryItem(name: "offset", value: offset * BetterCallDevClient.Constants.tokenBalanceQuerySize)
		url.appendQueryItem(name: "size", value: BetterCallDevClient.Constants.tokenBalanceQuerySize)
		url.appendQueryItem(name: "sort_by", value: "balance")
		url.appendQueryItem(name: "hide_empty", value: "true")
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: BetterCallDevTokenBalances.self) { result in
			guard let balancesObj = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			var sanitisedBalances: [BetterCallDevTokenBalance] = []
			let zeroToken = TokenAmount.zero()
			for balance in balancesObj.balances {
				if balance.amount() > zeroToken {
					sanitisedBalances.append(balance)
				}
			}
			
			completion(Result.success(BetterCallDevTokenBalances(balances: sanitisedBalances, total: balancesObj.total)))
		}
	}
	
	
	
	
	
	// MARK: - Tokens
	
	/**
	Fetches `v1/tokens/<network>/metadata` and returns the result. `<network>` is handled automatically by the config object passed into the constructor.
	This call returns metadata information on the given token contract.
	- parameter forTokenAddress: The token address to query data for..
	- parameter completion: Called when call finished.
	*/
	public func tokenMetadata(forTokenAddress token: String, completion: @escaping ((Result<BetterCallDevTokenMetadata?, ErrorResponse>) -> Void)) {
		var url = config.betterCallDevURL
		url.appendPathComponent("v1/tokens/\(config.tezosChainName.rawValue)/metadata")
		url.appendQueryItem(name: "contract", value: token)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [BetterCallDevTokenMetadata].self) { result in
			switch result {
				case .failure(let error):
					completion(Result.failure(error))
					
				case .success(let metadataArray):
					completion(Result.success(metadataArray.first))
			}
		}
	}
	
	
	
	
	
	// MARK: - Contracts
	
	/**
	Fetches `v1/contract/<network>/<contract-address>` and returns the result. `<network>` is handled automatically by the config object passed into the constructor.
	This call returns information about the given contract address
	- parameter forContractAddress: The address of the contract to fetch info for.
	- parameter completion: Called when call finished.
	*/
	public func contractMetdata(forContractAddress contract: String, completion: @escaping ((Result<BetterCallDevContract, ErrorResponse>) -> Void)) {
		var url = config.betterCallDevURL
		url.appendPathComponent("v1/contract/\(config.tezosChainName.rawValue)/\(contract)")
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: BetterCallDevContract.self, completion: completion)
	}
	
	
	
	
	
	// MARK: - Custom helpers / wrappers
	
	/**
	Query the last cached `Acount` instance (if available)
	*/
	public func cachedAccountInfo() -> Account? {
		return DiskService.read(type: Account.self, fromFileName: BetterCallDevClient.Constants.parsedAccountFilename)
	}
	
	/**
	Getting the users balance, token balances and NFT's is a very complex and invloved task. Even using BCD it requires many many networking requests, to fetch the balances, fetch them all 1 page at a time, fetch the metadata etc.
	This one function queries everything, and caches all the data to speed up subsequent calls. Applications should use this to drive their UI for 99% of use cases.
	Due to the level of caching, it is safe to call this method somewhat frequently, but no more often that once per block on the chain.
	What it does:
		- Queries the users XTZ balance via `self.account(forAddress: ...)`
		- Queries the tokenCount and every page of token balances via `self.fetchTokenCountAndBalances(forAddress: ... )`
		- Computes a MD5 hash of this data and saves it. In future, if the MD5 matches the stored, further steps are ignored and the cachedData is returned
		- Queries and caches all metadata for unknown tokens via `self.fetchAllTokenMetadata(forTokenCount: ...)`
		- Separates out NFT's and groups them under their parent collection
		- Fetches Token icon images using `Kingfisher`
		- Creates a readable `Account` object out of all of this data for easier consumption
		- Caches the `Account` object so it can be retrieved by `cachedAccountInfo()` for instant loading next time the app is opened
	- parameter forAddress: The address to request all this information for.
	- parameter completion: Called when calls are finished.
	*/
	public func fetchAccountInfo(forAddress address: String, completion: @escaping ((Result<Account, ErrorResponse>) -> Void)) {
		let dispatchGroup = DispatchGroup()
		
		var error: ErrorResponse? = nil
		var bcdAccount: BetterCallDevAccount? = nil
		var tokenBalances: BetterCallDevTokenBalances? = nil
		var tokenMetadata: [String: BetterCallDevTokenMetadata]? = nil
		var groupedData: (tokens: [Token], nftGroups: [Token])? = nil
		var dataIsUnchanged = false
		
		
		dispatchGroup.enter()
		
		// Query XTZ balance
		self.account(forAddress: address) { result in
			guard let bcdAcc = try? result.get() else {
				error = result.getFailure()
				dispatchGroup.leave()
				return
			}
			
			bcdAccount = bcdAcc
			
			// Wait for account balance to come in, and then query balances and check for any updates
			self.fetchTokenCountAndBalances(forAddress: address) { [weak self] innerResult in
				guard let countAndBalances = try? innerResult.get() else {
					error = innerResult.getFailure()
					dispatchGroup.leave()
					return
				}
				
				tokenBalances = countAndBalances.balances
				
				// Compute MD5 hash of current data, to determine if the account data has changed, before performing more expensive account queries
				let tokenData = (try? JSONEncoder().encode(tokenBalances ?? BetterCallDevTokenBalances(balances: [], total: 0))) ?? Data()
				let dataString = "\(bcdAcc.balance)\(bcdAcc.lastAction)\( String(data: tokenData, encoding: .utf8) ?? "" )"
				let currentMD5String = dataString.md5()
				
				
				// If we have a previous hash, and a previous stored data file. Hash the current payload and see if there is any difference
				// If no difference, return current cached data
				// else continue fetching extra data, grouping tokens, fetching URLs and images etc.
				if DiskService.exists(fileName: BetterCallDevClient.Constants.accountHashFilename) != nil,
				   DiskService.exists(fileName: BetterCallDevClient.Constants.parsedAccountFilename) != nil,
				   let storedMD5 = DiskService.read(type: String.self, fromFileName: BetterCallDevClient.Constants.accountHashFilename),
				   currentMD5String == storedMD5 {
					
					os_log("MD5 hash matched stored MD5, returning cached data", log: .bcd, type: .debug)
					dataIsUnchanged = true
					dispatchGroup.leave()
					
				} else {
					
					// Write the MD5 hash for next query
					let cacheResult = DiskService.write(encodable: currentMD5String, toFileName: BetterCallDevClient.Constants.accountHashFilename)
					os_log("MD5 cache succeeded: %@", log: .bcd, type: .debug, "\(cacheResult)")
					
					// Query token metadata (if required or read from disk)
					self?.fetchAllTokenMetadata(forTokenCount: countAndBalances.count, completion: { [weak self] metaResult in
						guard let metadataArray = try? metaResult.get() else {
							error = metaResult.getFailure()
							dispatchGroup.leave()
							return
						}
						
						tokenMetadata = metadataArray
						groupedData = self?.groupTokens(tokenBalances: tokenBalances, tokenMetadata: tokenMetadata)
						
						self?.fetchNftURLs(forNFTs: groupedData?.nftGroups ?? []) { updatedNFTs in
							groupedData?.nftGroups = updatedNFTs
							dispatchGroup.leave()
						}
					})
				}
			}
		}
		
		
		// When all requests finished, parse/group/filter and return as an `Account`
		dispatchGroup.notify(queue: .main) { [weak self] in
			
			// Check if any errors were recorded
			if let err = error {
				completion(Result.failure(err))
				return
			}
			
			// Check if data was unchanged, and retrieve cache if so
			if dataIsUnchanged == true {
				var cachedAccount = self?.cachedAccountInfo()
				cachedAccount?.changedSinceLastFetch = false
				
				if let acc = cachedAccount {
					completion(Result.success(acc))
					os_log("Returning cached BCD account info", log: .bcd, type: .debug)
					return
				}
			}
			
			// Check if all required new data is ready to go
			guard let bcdAcc = bcdAccount, let bcdTokens = groupedData?.tokens, let bcdNfts = groupedData?.nftGroups else {
				completion(Result.failure(ErrorResponse.unknownError()))
				return
			}
			
			// Construct new object and return
			let account = Account(walletAddress: bcdAcc.address, xtzBalance: bcdAcc.balance, tokens: bcdTokens, nfts: bcdNfts)
			let _ = DiskService.write(encodable: account, toFileName: BetterCallDevClient.Constants.parsedAccountFilename)
			os_log("Returning new BCD account info", log: .bcd, type: .debug)
			
			completion(Result.success(account))
		}
	}
	
	/**
	Internal function used to group NFT's into collections
	*/
	private func groupTokens(tokenBalances: BetterCallDevTokenBalances?, tokenMetadata: [String: BetterCallDevTokenMetadata]?) -> (tokens: [Token], nftGroups: [Token]) {
		guard let tokenBalances = tokenBalances, let tokenMetadata = tokenMetadata else {
			return (tokens: [], nftGroups: [])
		}
		
		// Sort BCD balances in descending order
		var sortedBalances = tokenBalances.balances
		sortedBalances.sort(by: { a, b in
			a.amount() > b.amount()
		})
		
		
		// Placeholders while grouping
		var tokens: [Token] = []
		var nftGroups: [Token] = []
		var tempNFT: [String: [NFT]] = [:]
		
		
		// Loop through balances, group NFT's and create Token instances
		for bcdToken in sortedBalances {
			
			// Group individual NFT's by their parent contract. Will add them to a `Token` later from the metadata
			if bcdToken.isNFT() {
				let nft = NFT(fromBcdBalance: bcdToken)
				
				if tempNFT[bcdToken.contract] == nil {
					tempNFT[bcdToken.contract] = [nft]
				} else {
					tempNFT[bcdToken.contract]?.append(nft)
				}
				continue
			}
			
			
			// If not NFT, create `Token` instance
			var imageURL: URL? = nil
			var faVersion: FaVersion? = nil
			
			// Find corresponding Metadata object
			if let currentMetadata = tokenMetadata[bcdToken.contract] {
				imageURL = avatarURL(forToken: bcdToken.contract)
				faVersion = currentMetadata.faVersion
			}
			
			let token = Token(icon: imageURL, name: bcdToken.name ?? "", symbol: bcdToken.symbol ?? "", tokenType: .fungible, faVersion: faVersion, balance: bcdToken.amount(), tokenContractAddress: bcdToken.contract, nfts: nil)
			tokens.append(token)
		}
		
		
		// Take NFT's and add them to `Token` instances
		for nftContract in tempNFT.keys {
			if let meta = tokenMetadata[nftContract] {
				
				let staticNFTData = OfflineConstants.dappDisplayName(forContractAddress: meta.contract, onChain: config.tezosChainName)
				nftGroups.append(Token(icon: staticNFTData.thumbnail, name: staticNFTData.name, symbol: meta.symbol ?? "", tokenType: .nonfungible, faVersion: meta.faVersion, balance: TokenAmount.zero(), tokenContractAddress: meta.contract, nfts: tempNFT[nftContract]))
			}
		}
		
		return (tokens: tokens, nftGroups: nftGroups)
	}
	
	// NFT display and thumbnail URLS need to be processed, and extremely likely converted into URLs pointing to a cache server
	private func fetchNftURLs(forNFTs nfts: [Token], completion: @escaping (([Token]) -> Void)) {
		let dispatchGroup = DispatchGroup()
		
		let updatedTokens: [Token] = nfts
		
		for (outerIndex, nftParent) in updatedTokens.enumerated() {
			for (innerIndex, nftChild) in (nftParent.nfts ?? []).enumerated() {
				dispatchGroup.enter()
				dispatchGroup.enter()
				
				imageURL(fromIpfsUri: nftChild.displayURI) { displayURL in
					updatedTokens[outerIndex].nfts?[innerIndex].displayURL = displayURL
					dispatchGroup.leave()
				}
				
				imageURL(fromIpfsUri: nftChild.thumbnailURI) { thumbnailURL in
					updatedTokens[outerIndex].nfts?[innerIndex].thumbnailURL = thumbnailURL
					dispatchGroup.leave()
				}
			}
		}
		
		// When all requests finished, return on main thread
		dispatchGroup.notify(queue: .main) {
			completion(updatedTokens)
		}
	}
	
	/**
	Calls `self.accountTokenCount(forAddress: ...)` to get the list of tokens the user owns, and then queries all the balances in batches of 10
	- parameter forAddress: The wallet address to query info for.
	- parameter completion: Called when all calls finsihed.
	*/
	public func fetchTokenCountAndBalances(forAddress address: String, completion: @escaping ((Result<(count: [String: Int], balances: BetterCallDevTokenBalances), ErrorResponse>) -> Void)) {
		
		// First fetch all a list of all of the types of tokens this account owns
		self.accountTokenCount(forAddress: address) { [weak self] result in
			
			switch result {
				case .failure(let error):
					completion(Result.failure(error))
					
				case .success(let tokenCountDict):
					let totalTokens = tokenCountDict.values.reduce(0, +)
					
					// Calculate the number of pages that will needed to be queried to fetch all the token balances
					let numberOfPages = Int(totalTokens / BetterCallDevClient.Constants.tokenBalanceQuerySize)
					let hasRemainder = (totalTokens % BetterCallDevClient.Constants.tokenBalanceQuerySize) > 0
					let totalNumberOfPages = numberOfPages + (hasRemainder ? 1 : 0)
					
					// Create a loop to query all the balances in blocks. If successful, return the token count dictionary so all the metadata can be queried, and the balances
					self?.fetchTokenBalancePages(forAddress: address, numberOfPages: totalNumberOfPages, numberOfTokens: totalTokens) { innerResult in
						switch innerResult {
							case .failure(let error):
								completion(Result.failure(error))
							
							case .success(let balances):
								completion(Result.success((count: tokenCountDict, balances: balances)))
						}
					}
			}
		}
	}
	
	/**
	Helper method to wrap up querying every tokenBalance page, into a single function call
	*/
	private func fetchTokenBalancePages(forAddress address: String, numberOfPages: Int, numberOfTokens: Int, completion: @escaping ((Result<BetterCallDevTokenBalances, ErrorResponse>) -> Void)) {
		let dispatchGroup = DispatchGroup()
		
		var tokenBalances = BetterCallDevTokenBalances(balances: [], total: numberOfTokens)
		var errorFound: ErrorResponse? = nil
		
		// TODO: Need to experiment with this code to see if it automatically adheres to the HTTP Max simultaneous calls per server
		// Or if we need to add Semaphores into the code to force it to only run a certain number at a time
		// https://betterprogramming.pub/limit-concurrent-network-requests-with-dispatchsemaphore-in-swift-f313afd938c6
		//
		for index in 0..<numberOfPages {
			dispatchGroup.enter()
			tokenBalanceQueue.async { [weak self] in
				self?.tokenBalances(forAddress: address, offset: index, completion: { tokenResult in
					switch tokenResult {
						case .failure(let error):
							errorFound = error
						
						case .success(let balances):
							tokenBalances.balances.append(contentsOf: balances.balances)
					}
					
					dispatchGroup.leave()
				})
			}
		}
		
		
		// When all requests finished, return on main thread
		dispatchGroup.notify(queue: .main) {
			if let err = errorFound {
				completion(Result.failure(err))
				
			} else {
				completion(Result.success(tokenBalances))
			}
		}
	}
	
	/**
	Fetching all of the necessary token method data requires 2 things. 1) Query the token contract from BCD to be able to see the `FaVersion`. 2) Query the token metadata itself to find out the rest of the info.
	- parameter forTokenCount: The tokenCount return from `accountTokenCount(forAddress: ...)`.
	- parameter completion: Called after all calls finished.
	*/
	public func fetchAllTokenMetadata(forTokenCount tokenCount: [String: Int], completion: @escaping ((Result<[String: BetterCallDevTokenMetadata], ErrorResponse>) -> Void)) {
		let dispatchGroup = DispatchGroup()
		var metadata: [String: BetterCallDevTokenMetadata] = [:]
		var errorFound: ErrorResponse? = nil
		var metadataUpdated = false
		
		// Query existing stored metadata, and load into dictionary
		if let readResult = DiskService.read(type: [String: BetterCallDevTokenMetadata].self, fromFileName: BetterCallDevClient.Constants.tokenMetadataFilename) {
			metadata = readResult
			os_log(.debug, log: .bcd, "Metadata fetched from disk")
		}
		
		// Fetch contract faVersion and token metadata, for tokens not already present in Realm
		for token in tokenCount.keys {
			if metadata[token] != nil {
				continue
			}
			
			metadataUpdated = true
			dispatchGroup.enter()
			
			metadataQueue.async { [weak self] in
				// Query contract metadata so we can see if its FA1.2 or FA2
				self?.contractMetdata(forContractAddress: token, completion: { result in
					switch result {
						case .failure(let error):
							errorFound = error
							dispatchGroup.leave()
							
						case .success(let contractMetadata):
							let faVersion = contractMetadata.faVersionFromTags()
							
							// Store the FA version and query the token metadata
							self?.tokenMetadata(forTokenAddress: token, completion: { innerResult in
								switch innerResult {
									case .failure(let error):
										errorFound = error
									
									case .success(let tokenMetadata):
										tokenMetadata?.faVersion = faVersion
										
										// Add the FaVersion to the metadata and store
										if let meta = tokenMetadata {
											metadata[token] = meta
										} else {
											os_log(.debug, log: .bcd, "no token metadata found for: %@", token)
										}
								}
								
								dispatchGroup.leave()
							})
					}
				})
			}
		}
		
		
		// Notify on background thread when done, as we still need to process token images
		dispatchGroup.notify(queue: DispatchQueue.global(qos: .background)) {
			
			// Check if any critical errors encountered during metadata fetching, and exit early
			if let err = errorFound {
				DispatchQueue.main.async { completion(Result.failure(err)) }
				return
			}
			
			// Bulk Cache token icons, if doesn't already exist
			self.downloadAndCacheImages(forTokenCount: tokenCount, metadata: metadata, completion: { success in
				
				// Write fetched metadata to disk
				if metadataUpdated {
					let writeSuccess = DiskService.write(encodable: metadata, toFileName: BetterCallDevClient.Constants.tokenMetadataFilename)
					os_log(.debug, log: .bcd, "Metadata cache write success: %@", "\(writeSuccess)") // If it fails, can be queried again, no need to alert user and break UI flow
				}
				
				// Finished, call completion success
				DispatchQueue.main.async { completion(Result.success(metadata)) }
			})
		}
	}
	
	/**
	Use `Kingfisher` to bulk download the token icons for all the tokens the user owns, allowing them to be called much easier.
	Developers can use https://github.com/onevcat/Kingfisher to display the images then throughout the app.
	E.g.  `imageView.kf.setImage(with: URL)`
	- parameter forTokenCount: The tokenCount return from `accountTokenCount(forAddress: ...)`.
	- parameter completion: Called after all calls finished.
	*/
	public func downloadAndCacheImages(forTokenCount tokenCount: [String: Int], metadata: [String: BetterCallDevTokenMetadata], completion: @escaping ((Bool) -> Void)) {
		
		// Create all the image URL's we need (non-NFT's only)
		var imageURLs: [URL] = []
		for token in tokenCount.keys {
			
			// If token get Tzkt avatar URL, else check if the NFT group is in our offline cache and grab that
			var urlForAsset: URL? = nil
			if metadata[token]?.isNFT() == false {
				urlForAsset = avatarURL(forToken: token)
				
			} else if let nftThumbnail = OfflineConstants.dappDisplayName(forContractAddress: token, onChain: config.tezosChainName).thumbnail {
				urlForAsset = nftThumbnail
			}
			
			
			// Check if we got a URL, if so, add to cache
			if let imageURL = urlForAsset, !ImageCache.default.isCached(forKey: imageURL.absoluteString) {
				imageURLs.append(imageURL)
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
	Convert the IPFS URI, into a cloudflare URL, pass this URL to the Kukai metadata cache service to extract info about the asset. If a non IPFS URI is passed in, it is simply returned
	If all goes well, a URL to the asset cached on Kukai's server will be returned
	- parameter fromIpfsUri: The IPFS URI to the given asset
	- parameter ofSize: Optional, the size string of the asset to query (e.g. "150x150")
	- parameter completion: Block returning a new URL if possible
	*/
	public func imageURL(fromIpfsUri uri: URL?, ofSize: String = "150x150", completion: @escaping ((URL?) -> Void)) {
		guard let uri = uri else {
			completion(nil)
			return
		}
		
		if String(uri.absoluteString.prefix(5)) == "https" {
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
	Used to manually clear the images cached on disk, to force them to be refreshed next time.
	*/
	public func clearCachedImages() {
		ImageCache.default.clearMemoryCache()
		ImageCache.default.clearDiskCache()
	}
}






















// is NFT logic:
/*
isNFT(asset: TokenResponseType): boolean {
	if (!asset) { return false; }
	if (CONSTANTS.MAINNET) {
	  return !CONSTANTS.NFT_CONTRACT_OVERRIDES.includes(`${asset.contractAddress}:${asset.id}`);
	} else {
	  return (asset?.isBooleanAmount || asset?.decimals == 0) && !CONSTANTS.NFT_CONTRACT_OVERRIDES.includes(`${asset.contractAddress}`) ? true : false;
	}
  }
*/











// For tokens icons, for both:
// displayUri  and  thumbnailUri


// get cloudflare IPFS url
/*
let url: UR? = nil
if (uri.startsWith('ipfs://')) {
	url = `https://cloudflare-ipfs.com/ipfs/${uri.slice(7)}`;
} else {
	url = uri
}
*/



// fetch cache metadata from kukai backend:
// const cacheMeta = await this.fetchApi(`https://backend.kukai.network/file/info?src=${url}`);



// Do query, and then check for:
/*
if (data?.Status === 'ok' && data.Filename && data.Extension) {
  const asset: CachedAsset  = {
	filename: data.Filename,
	extension: data.Extension
  }

if (asset.extension !== 'unknown') {
		   return asset;
		 }
*/


// this gives back filename and extension, store these on metadata object instead of ipfs url
// also handling exceptions:

/*
// Exceptions
  if (data?.isBooleanAmount === undefined && typeof data?.isBooleanAmount === "string" && data?.isBooleanAmount === "true"
  ) {
	// mandala
	metadata.isBooleanAmount = true;
  }
  if (data?.symbol === "OBJKT") {
	if (!data.displayUri) {
	  // hicetnunc
	  metadata.displayUri = await this.uriToAsset(
		rawData.formats[0].uri
	  );
	}
	if (metadata?.displayUri) {
	  metadata.thumbnailUri = '';
	}
  }
*/



// fetching assets is done by:
/*
import mimes from 'mime-db/db.json'

size = '150x150';
baseUrl = 'https://backend.kukai.network/file';
mimeType = 'image/*';      							*/

if obj {
	this.mimeType = Object.keys(mimes).filter(key => !!mimes[key]?.extensions?.length).find((key) => mimes[key].extensions.includes((this.meta as CachedAsset)?.extension));
	this.src = `${this.baseUrl}/${this.meta.filename}_${this.size}.${this.meta.extension}`;
}
else if string {
	// use URL
} else {
	// use question mark icon
}
*/





// for NFT's
// App icons come from the offline static cache

// For indivual nft tokens, passing around tokenId string consisting of "<token-contract-address>:<token-id>"

// assign contract override for quicker looking up in static offline list











// Where app thumbnail doesn't exist, convert address string to image data:
/*
getThumbnailUrl(address: string): string {
	const pixels = decode(address.slice(0, 22), 5, 5);
	const canvas = document.createElement("canvas");
	canvas.width = canvas.height = 5;
	const ctx = canvas.getContext("2d");
	const imageData = ctx.createImageData(5, 5);
	imageData.data.set(pixels);
	ctx.putImageData(imageData, 0, 0);
	return canvas.toDataURL();
  }
*/
