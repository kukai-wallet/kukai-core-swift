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
}
