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
		
		// MARK: - Quipuswap Constants
		
		/// Constant pulled from: https://github.com/madfish-solutions/quipuswap-sdk/blob/4c38ce4a44d7c15da197ecb28e6521f3ac8ff527/src/defaults.ts
		public static let FEE_FACTOR = 997
		
		/// Constant pulled from: https://github.com/madfish-solutions/quipuswap-sdk/blob/4c38ce4a44d7c15da197ecb28e6521f3ac8ff527/src/defaults.ts
		public static let VETO_PERIOD = Decimal(7889229)
		
		/// Constant pulled from:https://github.com/madfish-solutions/quipuswap-sdk/blob/4c38ce4a44d7c15da197ecb28e6521f3ac8ff527/src/defaults.ts
		public static let VOTING_PERIOD = Decimal(2592000)
		
		/// Constant pulled from: https://github.com/madfish-solutions/quipuswap-sdk/blob/4c38ce4a44d7c15da197ecb28e6521f3ac8ff527/src/defaults.ts
		public static let ACCURANCY_MULTIPLIER = Decimal(1000000000000000)
		
		
		
		// MARK: - Quipuswap Functions
		
		/**
		 Use TzKTClient's methods of storage and bigmap queries, to extract any recorded pending rewards the user might be due, for providing liquidity to a pool
		 */
		public static func getPendingRewards(fromExchange exchange: String, forAddress address: String, tzKTClient: TzKTClient, completion: @escaping ((Result<XTZAmount, ErrorResponse>) -> Void)) {
			
			tzKTClient.getStorage(forContract: exchange, ofType: QuipuswapExchangeStorageResponse.self) { result in
				guard let storageResult = try? result.get() else {
					completion(Result.failure(result.getFailure()))
					return
				}
				
				tzKTClient.getBigMapKey(forId: "\(storageResult.storage.user_rewards)", key: address, ofType: QuipuswapExchangeUserRewardsKeyResponse.self) { result2 in
					guard let rewardsResult = try? result2.get() else {
						completion(Result.failure(result2.getFailure()))
						return
					}
					
					tzKTClient.getBigMapKey(forId: "\(storageResult.storage.ledger)", key: address, ofType: QuipuswapExchangeLedgerKeyResponse.self) { result3 in
						guard let ledgerResult = try? result3.get() else {
							completion(Result.failure(result3.getFailure()))
							return
						}
						
						
						// Extract and parse all the relevant values from the 3 requests
						guard let rewardKey = rewardsResult.first,
							  let reward = Decimal(string: rewardKey.value.reward),
							  let rewardPaid = Decimal(string: rewardKey.value.reward_paid),
							  let ledgerKey = ledgerResult.first,
							  let shareBalance = Decimal(string: ledgerKey.value.balance),
							  let shareFrozenbalance = Decimal(string: ledgerKey.value.frozen_balance),
							  let periodFinish = storageResult.storage.date(from: storageResult.storage.period_finish),
							  let lastUpdateTime = storageResult.storage.date(from: storageResult.storage.last_update_time),
							  let storageReward = Decimal(string: storageResult.storage.reward),
							  let storageRewardPerSec = Decimal(string: storageResult.storage.reward_per_sec),
							  let storageRewardPerShare = Decimal(string: storageResult.storage.reward_per_share),
							  let storageTotalSupply = Decimal(string: storageResult.storage.total_supply) else {
								  completion(Result.success(XTZAmount.zero()))
								  return
						}
						
						
						// Custom logic from: https://github.com/madfish-solutions/quipuswap-sdk/blob/4c38ce4a44d7c15da197ecb28e6521f3ac8ff527/src/core.ts#L287
						var tempReward = reward
						if shareBalance > 0 {
							let now = Date()
							let rewardsTime = now > periodFinish ? periodFinish : now
							
							// Javascript timestamps are miliseconds, Swift are seconds, so require multiplying by 1000
							var newReward = Decimal(abs((rewardsTime.timeIntervalSince1970 * 1000) - (lastUpdateTime.timeIntervalSince1970 * 1000)))
							newReward = (newReward / 1000).rounded(scale: 0, roundingMode: .down)
							newReward = newReward * storageRewardPerSec
							
							if now > periodFinish {
								var periodsDuration = Decimal((now.timeIntervalSince1970 * 1000) - (periodFinish.timeIntervalSince1970 * 1000))
								periodsDuration = (periodsDuration / 100).rounded(scale: 0, roundingMode: .down)
								periodsDuration = (periodsDuration / Quipuswap.VOTING_PERIOD).rounded(scale: 0, roundingMode: .down)
								periodsDuration += 1
								periodsDuration = periodsDuration * Quipuswap.VOTING_PERIOD
								
								let rewardPerSec = ((storageReward * Quipuswap.ACCURANCY_MULTIPLIER) / abs(periodsDuration)).rounded(scale: 0, roundingMode: .down)
								
								newReward = Decimal((now.timeIntervalSince1970 * 1000) - (periodFinish.timeIntervalSince1970 * 1000))
								newReward = (newReward / 100).rounded(scale: 0, roundingMode: .down)
								newReward = abs(newReward)
								newReward = newReward * rewardPerSec
							}
							
							let rewardPerShare = storageRewardPerShare + ((newReward / storageTotalSupply).rounded(scale: 0, roundingMode: .down))
							let totalShares = shareBalance + shareFrozenbalance
							
							tempReward = reward + abs((totalShares * rewardPerShare) - rewardPaid)
						}
						
						// Temp reward should now contain the mutez of the users pending rewards
						tempReward = (tempReward / Quipuswap.ACCURANCY_MULTIPLIER).rounded(scale: 0, roundingMode: .down)
						let xtz = XTZAmount(fromRpcAmount: tempReward) ?? .zero()
						
						completion(Result.success(xtz))
						return
					}
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
