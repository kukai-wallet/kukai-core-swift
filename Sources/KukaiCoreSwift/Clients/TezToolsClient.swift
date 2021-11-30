//
//  TezToolsClient.swift
//  
//
//  Created by Simon Mcloughlin on 04/11/2021.
//

import Foundation
import os.log

/**
 Class to interact with https://teztools.io/ API (some documentation here: https://github.com/jmagly/build.teztools.io ).
 */
public class TezToolsClient {
	
	// TODO:
	// Currently no testnet avaialble, revisit in the future
	private static let baseURL = URL(string: "https://api.teztools.io/v1")!
	
	// Dedicateed API URLs
	private static let contractsURL = TezToolsClient.baseURL.appendingPathComponent("contracts")
	private static let pricesURL = TezToolsClient.baseURL.appendingPathComponent("prices")
	
	/// The last set of results returned from TezTools API
	public var tokens: [DefiToken] = []
	
	/// The networking service used to fire requests
	private let networkService: NetworkService
	
	/// The config used for URL's and logging
	private let config: TezosNodeClientConfig
	
	
	
	/**
	 Create instance of TezToolsClient
	 */
	public init(networkService: NetworkService, config: TezosNodeClientConfig) {
		self.networkService = networkService
		self.config = config
	}
	
	
	
	/**
	 Fetch all of the recorded Token and Price objects, combining together into `DefiToken` objects and returning as an array
	 - parameter completion: Block returning an array of DefiToken or an ErrorResponse
	 */
	public func fetchTokens(completion: @escaping ((Result<[DefiToken], ErrorResponse>) -> Void)) {
		networkService.request(url: TezToolsClient.contractsURL, isPOST: false, withBody: nil, forReturnType: TezToolTokenResponse.self) { [weak self] (tokenResult) in
			guard let tezToolTokens = try? tokenResult.get().contracts else {
				completion(Result.failure(tokenResult.getFailure()))
				return
			}
			
			self?.networkService.request(url: TezToolsClient.pricesURL, isPOST: false, withBody: nil, forReturnType: TezToolPriceResponse.self) { [weak self] (priceResult) in
				guard let tezToolPrices = try? priceResult.get().contracts else {
					completion(Result.failure(priceResult.getFailure()))
					return
				}
				
				self?.tokens = []
				
				for token in tezToolTokens {
					if let priceObj = tezToolPrices.first(where: { price in return price.uniqueTokenAddress() == token.uniqueTokenAddress() }) {
						self?.tokens.append(DefiToken(withToken: token, andPrice: priceObj))
					} else {
						self?.tokens.append(DefiToken(withToken: token))
					}
				}
				
				completion(Result.success(self?.tokens ?? []))
			}
		}
	}
}
