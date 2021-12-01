//
//  DipDupClient.swift
//  
//
//  Created by Simon Mcloughlin on 15/11/2021.
//

import Foundation

/**
 Class exposes functions to allow communication to the dedicated indexer platform DipDup ( https://dipdup.net/ ).
 DipDup is composed on many small, dedicated indexers, powered by GraphQL. This class tries to exposes userflow functions, allowing users to accomplish tasks without having to worry about the underlying complexities
 */
public class DipDupClient {
	
	// TODO: 
	// Currently no testnet instances, hardcoding internally for now. revisit when we have examples, and know how each service will be seperated
	private static var dexURL = URL(string: "https://dex.dipdup.net/v1/graphql")!
	
	/// The networking service used to fire requests
	private let networkService: NetworkService
	
	/// The config used for URL's and logging
	private let config: TezosNodeClientConfig
	
	/// Max enteries to return per request
	public static let dexMaxQuerySize = 100
	
	// Used for keeping track of recurrsive network calls progress
	private var exchangeQuery_currentOffset = 0
	private var exchangeQuery_tokens: [DipDupExchangesAndTokens] = []
	
	
	
	
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
	 Get a list of all the tokens available and on what excahnges (including their prices and pool data)
	 - parameter limit: Int, How many results to reuturn 100 Max)
	 - parameter offset: Int, How many positions to move the cursor
	 - parameter completion: Block returning a GraphQL response or an ErrorResponse
	 */
	public func getExchangesAndTokens(limit: Int = DipDupClient.dexMaxQuerySize, offset: Int = 0, completion: @escaping ((Result<GraphQLResponse<DipDupExchangesAndTokensResponse>, ErrorResponse>) -> Void)) {
		
		var query = """
		query {
			token(limit: \(limit), offset: \(offset), order_by: { exchanges_aggregate: {avg: {tezPool: desc}} }, where: {exchanges: {name: {_in: ["lb", "quipuswap"]}}}) {
				symbol,
				exchanges(where: {name: {_in: ["lb", "quipuswap"]}}) {
					name,
					tezPool,
					tokenPool,
					address,
					sharesTotal,
					midPrice,
					token {
						address,
						decimals,
						symbol,
						tokenId,
						standard
					}
				}
			}
		}
		"""
		
		query = query.replacingOccurrences(of: "\n", with: "")
		query = query.replacingOccurrences(of: "\t", with: "")
		
		let data = try? JSONEncoder().encode(["query": query])
		
		self.networkService.request(url: DipDupClient.dexURL, isPOST: true, withBody: data, forReturnType: GraphQLResponse<DipDupExchangesAndTokensResponse>.self) { result in
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
	
	/**
	 Recurrsively call `getExchangesAndTokens(...)` until we have found all the tokens
	 - parameter completion: Block returning a GraphQL response or an ErrorResponse
	 */
	public func getAllExchangesAndTokens(completion: @escaping ((Result<[DipDupExchangesAndTokens], ErrorResponse>) -> Void)) {
		getExchangesAndTokens(limit: DipDupClient.dexMaxQuerySize, offset: exchangeQuery_currentOffset) { [weak self] result in
			guard let res = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			self?.exchangeQuery_tokens.append(contentsOf: res.data?.token ?? [])
			self?.exchangeQuery_currentOffset += DipDupClient.dexMaxQuerySize
			
			if res.data?.token.count == DipDupClient.dexMaxQuerySize {
				self?.getAllExchangesAndTokens(completion: completion)
				
			} else {
				completion(Result.success(self?.exchangeQuery_tokens ?? []))
			}
		}
	}
	
	
	/**
	 Query a given addresses liquidity token balances
	 - parameter address: The TZ address to query for
	 - parameter completion: Block returning a GraphQL response or an ErrorResponse
	 */
	public func getLiquidityFor(address: String, completion: @escaping ((Result<GraphQLResponse<DipDupPosition>, ErrorResponse>) -> Void)) {
		var query = """
		query {
			position(where: {traderId: {_eq: "\(address)"}, sharesQty: {_gt: "0"}, exchange: {name: {_in: ["lb", "quipuswap"]}}}) {
				sharesQty,
				exchange {
					name,
					tezPool,
					tokenPool,
					address,
					sharesTotal,
					midPrice,
					token {
						address,
						decimals,
						symbol,
						tokenId,
						standard
					}
				}
			}
		}
		"""
		
		query = query.replacingOccurrences(of: "\n", with: "")
		query = query.replacingOccurrences(of: "\t", with: "")
		
		let data = try? JSONEncoder().encode(["query": query])
		
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
