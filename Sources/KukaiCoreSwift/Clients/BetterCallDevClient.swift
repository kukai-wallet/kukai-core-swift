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
		public static let tokenBalanceQuerySize = 10
		public static let tokenMetadataFilename = "bcd-token_metadata"
		public static let parsedAccountFilename = "bcd-parsed_account"
	}
	
	/// The networking service used to fire requests
	private let networkService: NetworkService
	
	/// The config used for URL's and logging
	private let config: TezosNodeClientConfig
	
	/// Queue used for fetching token balances
	private let tokenBalanceQueue: DispatchQueue
	
	/// Queue used for fetching token metadata
	private let metadataQueue: DispatchQueue
	
	
	
	
	
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
		url.appendQueryItem(name: "offset", value: offset)
		url.appendQueryItem(name: "size", value: BetterCallDevClient.Constants.tokenBalanceQuerySize)
		url.appendQueryItem(name: "sort_by", value: "balance")
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: BetterCallDevTokenBalances.self, completion: completion)
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
	This one request queries everything, and caches all the data to speed up subsequent calls. Applications should use this to drive their UI for 99% of use cases.
	Due to the level of caching, it is safe to call this method somewhat frequently, but no more often that once per block on the chain.
	What it does:
		- Queries the users XTZ balance via `self.account(forAddress: ...)`
		- Queries the tokenCount and every page of token balances via `self.fetchTokenCountAndBalances(forAddress: ... )`
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
		
		
		// Query XTZ balance
		dispatchGroup.enter()
		self.account(forAddress: address) { result in
			switch result {
				case .failure(let err):
					error = err
				
				case .success(let bcdAcc):
					bcdAccount = bcdAcc
			}
			
			dispatchGroup.leave()
		}
		
		
		// Query token balances
		dispatchGroup.enter()
		self.fetchTokenCountAndBalances(forAddress: address) { [weak self] result in
			switch result {
				case .failure(let err):
					error = err
					dispatchGroup.leave()
					
				case .success(let countAndBalances):
					tokenBalances = countAndBalances.balances
					
					
					// Query token metadata (if required or read from disk)
					self?.fetchAllTokenMetadata(forTokenCount: countAndBalances.count, completion: { [weak self] innerResult in
						switch innerResult {
							case .failure(let err):
								error = err
							
							case .success(let metadataArray):
								tokenMetadata = metadataArray
								groupedData = self?.groupTokens(tokenBalances: tokenBalances, tokenMetadata: tokenMetadata)
						}
						dispatchGroup.leave()
					})
			}
		}
		
		
		
		// When all requests finished, parse/group/filter and return as an `Account`
		dispatchGroup.notify(queue: .main) {
			if let err = error {
				completion(Result.failure(err))
				return
			}
			
			guard let bcdAcc = bcdAccount, let bcdTokens = groupedData?.tokens, let bcdNfts = groupedData?.nftGroups else {
				completion(Result.failure(ErrorResponse.unknownError()))
				return
			}
			
			let account = Account(walletAddress: bcdAcc.address, xtzBalance: bcdAcc.balance, tokens: bcdTokens, nfts: bcdNfts)
			let _ = DiskService.write(encodable: account, toFileName: BetterCallDevClient.Constants.parsedAccountFilename)
			
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
			
			// Group individual NFT's by thier parent contract. Will add them to a `Token` later from the metadata
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
				imageURL = currentMetadata.imageURL
				faVersion = currentMetadata.faVersion
			}
			
			let token = Token(icon: imageURL, name: bcdToken.name ?? "", symbol: bcdToken.symbol ?? "", tokenType: .fungible, faVersion: faVersion, balance: bcdToken.amount(), tokenContractAddress: bcdToken.contract, nfts: nil)
			tokens.append(token)
		}
		
		
		// Take NFT's and add them to `Token` instances
		for nftContract in tempNFT.keys {
			if let meta = tokenMetadata[nftContract] {
				nftGroups.append(Token(icon: meta.imageURL, name: meta.name, symbol: meta.symbol ?? "", tokenType: .nonfungible, faVersion: meta.faVersion, balance: TokenAmount.zero(), tokenContractAddress: meta.contract, nfts: tempNFT[nftContract]))
			}
		}
		
		
		return (tokens: tokens, nftGroups: nftGroups)
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
										tokenMetadata?.imageURL = self?.imageURL(forToken: token)
										
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
			
			// Only fetch icon for token that has valid metadata (nil if can't be found), and is not an NFT as they don't have token icons
			guard metadata[token]?.isNFT() == false, let imageURL = imageURL(forToken: token) else {
				continue
			}
			
			if !ImageCache.default.isCached(forKey: imageURL.absoluteString) {
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
		ImageCache.default.diskStorage.config.expiration = .never
		ImagePrefetcher(urls: imageURLs, options: nil, progressBlock: nil) { (skipped, failed, completed) in
			os_log(.debug, log: .bcd, "Baker images downloaded")
			
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
	public func imageURL(forToken token: String) -> URL? {
		guard let imageURL = URL(string: "https://services.tzkt.io/v1/avatars/\(token)") else {
			return nil
		}
		
		return imageURL
	}
	
	/**
	Used to manually clear the images cached on disk, to force them to be refreshed next time.
	*/
	public func clearCachedImages() {
		ImageCache.default.clearMemoryCache()
		ImageCache.default.clearDiskCache()
	}
}
