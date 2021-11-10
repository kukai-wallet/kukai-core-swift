//
//  File.swift
//  
//
//  Created by Simon Mcloughlin on 04/11/2021.
//

import Foundation
import os.log

public class TezToolsClient {
	
	private static let baseURL = URL(string: "https://api.teztools.io/v1")!
	private static let contractsURL = TezToolsClient.baseURL.appendingPathComponent("contracts")
	private static let pricesURL = TezToolsClient.baseURL.appendingPathComponent("prices")
	
	public var tokens: [DefiToken] = []
	
	/// The networking service used to fire requests
	private let networkService: NetworkService
	
	/// The config used for URL's and logging
	private let config: TezosNodeClientConfig
	
	public init(networkService: NetworkService, config: TezosNodeClientConfig) {
		self.networkService = networkService
		self.config = config
	}
	
	
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
				
				for token in tezToolTokens {
					if let priceObj = tezToolPrices.first(where: { price in return price.uniqueTokenAddress() == token.uniqueTokenAddress() }) {
						self?.tokens.append(DefiToken(withToken: token, andPrice: priceObj))
					} else {
						print("Didn't find matching price")
						self?.tokens.append(DefiToken(withToken: token))
					}
				}
				
				completion(Result.success(self?.tokens ?? []))
			}
		}
	}
}
