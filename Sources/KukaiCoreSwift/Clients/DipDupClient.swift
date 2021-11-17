//
//  DipDupClient.swift
//  
//
//  Created by Simon Mcloughlin on 15/11/2021.
//

import Foundation

public class DipDupClient {
	
	// Currently no testnet instances, hardcoding internally for now. revisit when we have examples, and know how each service will be seperated
	private static var dexURL = URL(string: "https://dex.dipdup.net/v1/graphql")!
	
	/// The networking service used to fire requests
	private let networkService: NetworkService
	
	/// The config used for URL's and logging
	private let config: TezosNodeClientConfig
	
	
	
	
	
	// MARK: - Init
	
	/**
	Init a `DipDupClient` with a `NetworkService` and a `TezosNodeClientConfig`.
	- parameter networkService: `NetworkService` used to manage network communication.
	- parameter config: `TezosNodeClientConfig` used to apss in settings.
	*/
	public init(networkService: NetworkService, config: TezosNodeClientConfig) {
		self.networkService = networkService
		self.config = config
	}
	
	
	
	
	
	// MARK: - Public functions
	
	/**
	 */
	public func getLiquidityFor(address: String, completion: @escaping ((Result<GraphQLResponse<DipDupPosition>, ErrorResponse>) -> Void)) {
		let queryDict = ["query": "query {position(where: {traderId: {_eq: \"\(address)\" }}) { sharesQty, token { symbol, address, decimals}, exchange { name, address, tezPool, tokenPool, sharesTotal}}}"]
		let data = try? JSONEncoder().encode(queryDict)
		
		self.networkService.request(url: DipDupClient.dexURL, isPOST: true, withBody: data, forReturnType: GraphQLResponse<DipDupPosition>.self) { result in
			guard let res = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			if res.containsErrors() {
				completion(Result.failure(ErrorResponse.error(string: res.errors?.first?.message ?? "unknown", errorType: .unknownError)))
			} else {
				completion(Result.success(res))
			}
		}
	}
}
