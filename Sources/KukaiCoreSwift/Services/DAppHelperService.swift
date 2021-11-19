//
//  DAppHelperService.swift
//  
//
//  Created by Simon Mcloughlin on 19/11/2021.
//

import Foundation
import Combine

/**
 A Helper service to simply combine multiple calls from other services, and/or map to specific responses, in order to expose a piece of functionality provided by a dApp
 */
public class DAppHelperService {
	
	private static var bag = Set<AnyCancellable>()
	
	
	/**
	 All functions related to Quipuswap
	 */
	public struct Quipuswap {
		
		/**
		 Use TzKTClient's methods of storage and bigmap queries, to extract any recorded pending rewards the user might be due, for providing liquidity to a pool
		 */
		public static func getPendingRewards(fromExchange exchange: String, forAddress address: String, tzKTClient: TzKTClient, completion: @escaping ((Result<XTZAmount, ErrorResponse>) -> Void)) {
			
			tzKTClient.getStorage(forContract: exchange, ofType: QuipuswapExchangeStorageResponse.self) { result in
				guard let res = try? result.get() else {
					completion(Result.failure(result.getFailure()))
					return
				}
				
				tzKTClient.getBigMapKey(forId: "\(res.storage.user_rewards)", key: address, ofType: QuipuswapExchangeBigMapKeyResponse.self) { result2 in
					guard let res2 = try? result2.get() else {
						completion(Result.failure(result2.getFailure()))
						return
					}
					
					if let keyObj = res2.first, let decimal = Decimal(string: keyObj.value.reward) {
						
						// Divide by a constant named 'ACCURANCY_MULTIPLIER' from https://github.com/madfish-solutions/quipuswap-sdk/blob/main/src/defaults.ts , to convert to mutez
						let mutez = (decimal / 1000000000000000).rounded(scale: 0, roundingMode: .down)
						let xtz = XTZAmount(fromRpcAmount: mutez) ?? .zero()
						
						completion(Result.success(xtz))
						return
					}
					
					completion(Result.success(XTZAmount.zero()))
				}
			}
		}
		
		/**
		 Wrapper around `getPendingRewards(..., completion: )` to make it easier to create bulk queries, through combine
		 */
		public static func getPendingRewards(fromExchange exchange: String, forAddress address: String, tzKTClient: TzKTClient) -> Future<(exchange: String, rewards: XTZAmount), ErrorResponse> {
			return Future<(exchange: String, rewards: XTZAmount), ErrorResponse> { promise in
				getPendingRewards(fromExchange: exchange, forAddress: address, tzKTClient: tzKTClient) { result in
					guard let res = try? result.get() else {
						promise(.failure(result.getFailure()))
						return
					}
					
					promise(.success( (exchange: exchange, rewards: res) ))
				}
			}
		}
		
		/**
		 Use TzKTClient's methods of storage and bigmap queries, to extract any recorded pending rewards the user might be due, for providing liquidity to a pool
		 */
		public static func getBulkPendingRewards(fromExchanges exchanges: [String], forAddress address: String, tzKTClient: TzKTClient, completion: @escaping ((Result<[(exchange: String, rewards: XTZAmount)], ErrorResponse>) -> Void)) {
			var futures: [Future<(exchange: String, rewards: XTZAmount), ErrorResponse>] = []
			
			for exchange in exchanges {
				futures.append(getPendingRewards(fromExchange: exchange, forAddress: address, tzKTClient: tzKTClient))
			}
			
			Publishers.MergeMany(futures).collect().sink { failure in
				completion(.failure(failure))
				
			} onSuccess: { results in
				completion(.success(results))
				
			} onComplete: {
				DAppHelperService.bag.removeAll()
				
			}.store(in: &DAppHelperService.bag)
		}
	}
}
