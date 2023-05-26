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
	}
	
	static let numberOfFutureCyclesReturned = 5
	
	private let networkService: NetworkService
	private let config: TezosNodeClientConfig
	private let betterCallDevClient: BetterCallDevClient
	private let dipDupClient: DipDupClient
	
	private var tempTransactions: [TzKTTransaction] = []
	private var tempTokenTransfers: [TzKTTokenTransfer] = []
	private var dispatchGroupTransactions = DispatchGroup()
	private let tokenBalanceQueue: DispatchQueue
	
	private var signalrConnection: HubConnection? = nil
	private var addressesToWatch: [String] = []
	private var newAddressesToWatch: [String] = []
	
	public var isListening = false
	
	@Published public var accountDidChange: String = ""
	
	
	
	// MARK: - Init
	
	/**
	Init a `TzKTClient` with a `NetworkService` and a `TezosNodeClientConfig` and a `BetterCallDevClient`.
	- parameter networkService: `NetworkService` used to manage network communication.
	- parameter config: `TezosNodeClientConfig` used to apss in settings.
	- parameter betterCallDevClient: `BetterCallDevClient` used to fetch more detailed errors about operation failures involving smart contracts.
	- parameter dipDupClient: `DipDupClient` used to fetch additional information about the tokens owned.
	*/
	public init(networkService: NetworkService, config: TezosNodeClientConfig, betterCallDevClient: BetterCallDevClient, dipDupClient: DipDupClient) {
		self.networkService = networkService
		self.config = config
		self.betterCallDevClient = betterCallDevClient
		self.tokenBalanceQueue = DispatchQueue(label: "TzKTClient.tokens", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
		self.dipDupClient = dipDupClient
	}
	
	
	
	
	
	// MARK: - Storage
	
	/**
	 Get the storage of a given contract and parse it to a supplied model type
	 - parameter forContract: The KT1 contract address to query
	 - parameter ofType: The Codable compliant model to parse the response as
	 - parameter completion: A completion block called, returning a Swift Result type
	 */
	public func getStorage<T: Codable>(forContract contract: String, ofType: T.Type, completion: @escaping ((Result<T, KukaiError>) -> Void)) {
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
	public func getBigMap<T: Codable>(forId id: String, ofType: T.Type, completion: @escaping ((Result<T, KukaiError>) -> Void)) {
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
	public func getBigMapKey<T: Codable>(forId id: String, key: String, ofType: T.Type, completion: @escaping ((Result<T, KukaiError>) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/bigmaps/\(id)/keys")
		url.appendQueryItem(name: "key", value: key)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: T.self, completion: completion)
	}
	
	
	
	// MARK: Search
	
	/**
	 Call https://api.tzkt.io/v1/suggest/accounts/... appending the supplied string, in an attempt to search for an account with a known alias
	 */
	public func suggestAccount(forString: String, completion: @escaping ((Result<TzKTAddress?, KukaiError>) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/suggest/accounts/\(forString)")
		url.appendQueryItem(name: "limit", value: 1)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTAddress].self) { result in
			guard let res = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			for obj in res {
				
				// TzKT may suggest something similar, we are only looking for exact matches
				if obj.alias == forString {
					completion(Result.success(obj))
					return
				}
			}
			
			// Only return error for a network failure, its likely this API will return no results
			completion(Result.success(nil))
		}
	}
	
	
	// MARK: Baking and Rewards
	
	/**
	 Call https://api.baking-bad.org/v2/bakers/ for a list of public bakers if on mainnet, else search for all accounts self delegating on testnet
	 */
	public func bakers(completion: @escaping ((Result<[TzKTBaker], KukaiError>) -> Void)) {
		
		// TzKT still relies on the baking bad API to deliver the public baker info on mainnet
		if config.networkType == .mainnet, let url = URL(string: "https://api.baking-bad.org/v2/bakers/") {
			networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTBaker].self, completion: completion)
			
		} else {
			var url = config.tzktURL
			url.appendPathComponent("v1/delegates")
			url.appendQueryItem(name: "select.values", value: "address,balance,stakingBalance")
			url.appendQueryItem(name: "active", value: "true")
			url.appendQueryItem(name: "sort.desc", value: "stakingBalance")
			url.appendQueryItem(name: "limit", value: 10)
			
			networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: Data.self) { result in
				guard let res = try? result.get() else {
					completion(Result.failure(result.getFailure()))
					return
				}
				
				if let json = try? JSONSerialization.jsonObject(with: res) as? [[Any]] {
					var tempArray: [TzKTBaker] = []
					for j in json {
						if let baker = TzKTBaker.fromTestnetArray(j) {
							tempArray.append(baker)
						}
					}
					
					completion(Result.success(tempArray))
					
				} else {
					completion(Result.failure(KukaiError.unknown(withString: "Unable to parse testnet baker array")))
				}
			}
		}
	}
	
	/**
	 Call https://api.baking-bad.org/v2/bakers/...?configs=true to get the config settings for the given baker
	 */
	public func bakerConfig(forAddress: String, completion: @escaping ((Result<TzKTBaker, KukaiError>) -> Void)) {
		guard let url = URL(string: "https://api.baking-bad.org/v2/bakers/\(forAddress)") else {
			completion(Result.failure(KukaiError.unknown()))
			return
		}
		
		var tempURL = url
		tempURL.appendQueryItem(name: "configs", value: "true")
		
		networkService.request(url: tempURL, isPOST: false, withBody: nil, forReturnType: TzKTBaker.self, completion: completion)
	}
	
	/**
	 Call https://api.tzkt.io/v1/rewards/delegators/...?limit=... to get the config settings for the given baker
	 */
	public func delegatorRewards(forAddress: String, limit: Int = 25, completion: @escaping ((Result<[TzKTDelegatorReward], KukaiError>) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/rewards/delegators/\(forAddress)")
		url.appendQueryItem(name: "limit", value: limit)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTDelegatorReward].self, completion: completion)
	}
	
	/**
	 Make many different calls to attempt to figure out the previous reward the user should have received, and the next potential reward
	 */
	public func estimateLastAndNextReward(forAddress: String, delegate: TzKTAccountDelegate, completion: @escaping ((Result<AggregateRewardInformation, KukaiError>) -> Void)) {
		let dispatchGroup = DispatchGroup()
		
		var currentCycles: [TzKTCycle] = []
		var currentDelegatorRewards: [TzKTDelegatorReward] = []
		var bakerConfigs: [String: TzKTBaker] = [:]
		var bakerPayoutAddresses: [String: TzKTAddress] = [:]
		var mostRecentTransaction: TzKTTransaction? = nil
		
		
		// Get cycles, find the current and preivous
		dispatchGroup.enter()
		dispatchGroup.enter()
		getCyclesAndRewards(forAddress: forAddress) { [weak self] result in
			guard let res = try? result.get() else {
				DispatchQueue.main.async { completion(Result.failure(KukaiError.unknown(withString: "failed to get or parse cycles"))) }
				return
			}
			
			// Store data about the fetched state
			currentCycles = res.cycles
			currentDelegatorRewards = res.rewards
			let tempUniqueBakers = self?.mostRecentUniqueBakers(fromDelegatorRewards: currentDelegatorRewards) ?? []
			let uniqueBakers = self?.uniqueAddresses(from: delegate, and: tempUniqueBakers) ?? []
			
			
			// fetch baker configs in a loop
			for bakerAddress in uniqueBakers {
				dispatchGroup.enter()
				self?.bakerConfig(forAddress: bakerAddress.address, completion: { bakerResult in
					guard let bakerRes = try? bakerResult.get() else {
						DispatchQueue.main.async { completion(Result.failure(KukaiError.unknown(withString: "failed to get baker config"))) }
						return
					}
					
					bakerConfigs[bakerAddress.address] = bakerRes
					dispatchGroup.leave()
				})
			}
			
			
			// Search for last tx received from any baker/payout-address in the list
			dispatchGroup.enter()
			self?.getLastBakerRewardTransaction(forAddress: forAddress, uniqueBakers: uniqueBakers, completion: { resultTx in
				guard let resTx = try? resultTx.get() else {
					bakerPayoutAddresses = [:]
					mostRecentTransaction = nil
					dispatchGroup.leave()
					return
				}
				
				bakerPayoutAddresses = resTx.paymentAddresses
				mostRecentTransaction = resTx.transaction
				dispatchGroup.leave()
			})
			
			dispatchGroup.leave()
			dispatchGroup.leave()
		}
		
		
		// Gather all data and process into something meaningful
		dispatchGroup.notify(queue: .global(qos: .background)) { [weak self] in
			
			// If we have the last transaction received. Use the list of cycles, delegatorRewards and baker configs, to see can we get the additional data
			var pReward: RewardDetails? = nil
			if let tx = mostRecentTransaction {
				let cycleIndexPaymentReceived = self?.cycleForLevel(cycles: currentCycles, level: tx.level)?.index ?? 0
				let amount = (tx.amount as? XTZAmount) ?? .zero()
				
				var alias = tx.sender.alias
				var avatarURL = TzKTClient.avatarURL(forToken: tx.sender.address)
				var fee = 0.0
				var indexOfCyclePaymentIsFor = cycleIndexPaymentReceived
				
				// If the tx came from the baker directly, grab the config and apply
				if let config = bakerConfigs[tx.sender.address] {
					alias = config.name
					avatarURL = TzKTClient.avatarURL(forToken: config.address)
					fee = config.fee
					indexOfCyclePaymentIsFor = (cycleIndexPaymentReceived - (config.payoutDelay - 1))
					
				}
				// If the tx came from a known payout address, match it to the baker address and grab the config
				else {
					for pair in bakerPayoutAddresses {
						if pair.value.address == tx.sender.address, let config = bakerConfigs[pair.key] {
							alias = config.name
							avatarURL = TzKTClient.avatarURL(forToken: config.address)
							fee = config.fee
							indexOfCyclePaymentIsFor = (cycleIndexPaymentReceived - (config.payoutDelay - 1))
						}
					}
				}
				
				// Group up data into something usuable
				pReward = RewardDetails(bakerAlias: alias, bakerLogo: avatarURL, paymentAddress: tx.sender.address, amount: amount, cycle: indexOfCyclePaymentIsFor, fee: fee, date: tx.date ?? Date(), meetsMinDelegation: true)
			}
			
			
			// Whether we have the previous transaction or not, try to estimate the previous transaction and the next
			var estimatedPreviousReward: RewardDetails? = nil
			var estimatedNextReward: RewardDetails? = nil
			
			// Check if we have enough rewards to bring us up to the current cycle
			guard currentDelegatorRewards.count > TzKTClient.numberOfFutureCyclesReturned,
				  let currentBakerConfig = bakerConfigs[delegate.address],
				  let inProgresCycleBakerConfig = bakerConfigs[currentDelegatorRewards[TzKTClient.numberOfFutureCyclesReturned].baker.address] else {
				
				let nextPossibleReward = self?.tryToGetFutureRewardFromLimitedData(bakerConfigs: bakerConfigs, rewards: currentDelegatorRewards, cycles: currentCycles)
				DispatchQueue.main.async { completion(Result.success(AggregateRewardInformation(previousReward: pReward, estimatedPreviousReward: nil, estimatedNextReward: nextPossibleReward))) }
				return
			}
			
			
			var configToUse = (currentBakerConfig.payoutDelay < inProgresCycleBakerConfig.payoutDelay) ? currentBakerConfig : inProgresCycleBakerConfig
			var previousRewardIndex = TzKTClient.numberOfFutureCyclesReturned + configToUse.payoutDelay
			
			
			// If we don't have enough objects to fetch, can't compute previous, early exit
			if currentDelegatorRewards.count < previousRewardIndex {
				let nextPossibleReward = self?.tryToGetFutureRewardFromLimitedData(bakerConfigs: bakerConfigs, rewards: currentDelegatorRewards, cycles: currentCycles)
				DispatchQueue.main.async { completion(Result.success(AggregateRewardInformation(previousReward: pReward, estimatedPreviousReward: nil, estimatedNextReward: nextPossibleReward))) }
				return
			}
			// If the selected cycle reward and the config baker don't match, then wallet has just changed baker and we need to use the other config
			else if currentDelegatorRewards[previousRewardIndex].baker.address != configToUse.address {
				configToUse = (currentBakerConfig.payoutDelay < inProgresCycleBakerConfig.payoutDelay) ? inProgresCycleBakerConfig : currentBakerConfig
				previousRewardIndex = TzKTClient.numberOfFutureCyclesReturned + configToUse.payoutDelay
				
				// Check we have enough again
				if currentDelegatorRewards.count < previousRewardIndex {
					let nextPossibleReward = self?.tryToGetFutureRewardFromLimitedData(bakerConfigs: bakerConfigs, rewards: currentDelegatorRewards, cycles: currentCycles)
					DispatchQueue.main.async { completion(Result.success(AggregateRewardInformation(previousReward: pReward, estimatedPreviousReward: nil, estimatedNextReward: nextPossibleReward))) }
					return
				}
			}
			
			let lastCompleteCycle = currentCycles[TzKTClient.numberOfFutureCyclesReturned + 1]
			estimatedPreviousReward = self?.rewardDetail(fromConfig: configToUse, rewards: currentDelegatorRewards, cycles: currentCycles, selectedIndex: previousRewardIndex, dateForDisplay: lastCompleteCycle.endDate ?? Date())
			
			let nextBakerAddress = currentDelegatorRewards[previousRewardIndex-1].baker.address
			guard let nextConfig = bakerConfigs[nextBakerAddress] else {
				// Unable to find baker config for next block, shouldn't be possible to hit here ... but life will find a way
				DispatchQueue.main.async { completion(Result.success(AggregateRewardInformation(previousReward: pReward, estimatedPreviousReward: estimatedPreviousReward, estimatedNextReward: nil))) }
				return
			}
			
			let currentInProgressCycle = currentCycles[TzKTClient.numberOfFutureCyclesReturned]
			estimatedNextReward = self?.rewardDetail(fromConfig: nextConfig, rewards: currentDelegatorRewards, cycles: currentCycles, selectedIndex: previousRewardIndex-1, dateForDisplay: currentInProgressCycle.endDate ?? Date())
			DispatchQueue.main.async { completion(Result.success(AggregateRewardInformation(previousReward: pReward, estimatedPreviousReward: estimatedPreviousReward, estimatedNextReward: estimatedNextReward))) }
		}
	}
	
	/// Helper for sitautions where we don't have enough rewards to get a past reward, but likely we can get a future reward
	private func tryToGetFutureRewardFromLimitedData(bakerConfigs: [String: TzKTBaker], rewards: [TzKTDelegatorReward], cycles: [TzKTCycle]) -> RewardDetails? {
		guard rewards.count > 0, let nextPossibleReward = rewards.last, let bakerConfig = bakerConfigs[nextPossibleReward.baker.address] else {
			return nil
		}
		
		let cycleItShouldBeRecieved = cycles[(rewards.count-1) + bakerConfig.payoutDelay]
		return rewardDetail(fromConfig: bakerConfig, rewards: rewards, cycles: cycles, selectedIndex: rewards.count-1, dateForDisplay: cycleItShouldBeRecieved.endDate ?? Date())
	}
	
	/// Helper to create a `RewardDetails` in a single line
	private func rewardDetail(fromConfig config: TzKTBaker, rewards: [TzKTDelegatorReward], cycles: [TzKTCycle], selectedIndex: Int, dateForDisplay: Date) -> RewardDetails {
		let fee = config.fee
		let cycle = cycles[selectedIndex]
		let alias = config.name
		let address = config.address
		let logo = TzKTClient.avatarURL(forToken: address)
		let reward = rewards[selectedIndex]
		let amount = reward.estimatedReward(withFee: fee, andRewardStruct: config.rewardStruct())
		
		return RewardDetails(bakerAlias: alias, bakerLogo: logo, paymentAddress: address, amount: amount, cycle: cycle.index, fee: fee, date: dateForDisplay, meetsMinDelegation: (reward.balance >= config.minDelegation))
	}
	
	/// Filter list of `TzKTDelegatorReward` and return the most recent unqiue bakers from the list (max 2, going no further back than 25 cycles)
	private func mostRecentUniqueBakers(fromDelegatorRewards: [TzKTDelegatorReward]) -> [TzKTAddress] {
		guard fromDelegatorRewards.count > 0 else {
			return []
		}
		
		var unique: [TzKTAddress] = []
		for (index, dReward) in fromDelegatorRewards.enumerated() {
			if unique.count == 0 {
				unique.append(dReward.baker)
				
			} else if !unique.contains(where: { $0.address == dReward.baker.address }) {
				unique.append(dReward.baker)
			}
			
			// Only searching for first 2
			if unique.count == 2 {
				break
			}
			
			// 25 cycles is more than enough to search back
			if index > 25 {
				break
			}
		}
		
		return unique
	}
	
	/// Combine the `Account`'s `TzKTAccountDelegate` and the uniqueBakers from `mostRecentUniqueBakers(...)` into a more manageable array of the same type
	private func uniqueAddresses(from delegate: TzKTAccountDelegate, and uniqueBakers: [TzKTAddress]) -> [TzKTAddress] {
		let delegateAddress = TzKTAddress(alias: delegate.alias, address: delegate.address)
		var unique: [TzKTAddress] = [delegateAddress]
		
		for address in uniqueBakers {
			if !unique.contains(where: { $0.address == address.address }) {
				unique.append(address)
			}
		}
		
		return unique
	}
	
	/// Get the last transaction received from any of the baker addresses directly, or any of the payment addresses. Also return the payment addresses so we can get the matching baker config for the transaction
	private func getLastBakerRewardTransaction(forAddress: String, uniqueBakers: [TzKTAddress], completion: @escaping ((Result<(paymentAddresses: [String: TzKTAddress], transaction: TzKTTransaction?), KukaiError>) -> Void)) {
		
		findPaymentAddresses(from: uniqueBakers) { [weak self] result in
			guard let res = try? result.get() else {
				completion(Result.failure(KukaiError.unknown(withString: "failed to get suggested address")))
				return
			}
			
			self?.getLastReward(forAddress: forAddress, uniqueBakers: uniqueBakers, payoutAddresses: res, completion: { resultTxs in
				guard let resTxs = try? resultTxs.get() else {
					completion(Result.failure(KukaiError.unknown(withString: "failed to get txs")))
					return
				}
				
				completion(Result.success( (paymentAddresses: res, transaction: resTxs.first) ))
			})
		}
	}
	
	/// Loop through list of addresses and use tzkt suggest API to try find matching payout addresses
	private func findPaymentAddresses(from addresses: [TzKTAddress], completion: @escaping ((Result<[String: TzKTAddress], KukaiError>) -> Void)) {
		let dispatchGroup = DispatchGroup()
		var paymentAddresses: [String: TzKTAddress] = [:]
		
		dispatchGroup.enter()
		for address in addresses {
			guard let alias = address.alias else {
				continue
			}
			
			dispatchGroup.enter()
			suggestAccount(forString: "\(alias) Payouts") { result in
				guard let res = try? result.get() else {
					dispatchGroup.leave()
					return
				}
				
				paymentAddresses[address.address] = res
				dispatchGroup.leave()
			}
		}
		dispatchGroup.leave()
		
		dispatchGroup.notify(queue: .global(qos: .background)) {
			completion(Result.success(paymentAddresses))
		}
	}
	
	/// Take all the baker addresses and payout addresses and find the last transaction (if any) received from any of them
	public func getLastReward(forAddress: String, uniqueBakers: [TzKTAddress], payoutAddresses: [String: TzKTAddress], completion: @escaping ((Result<[TzKTTransaction], KukaiError>) -> Void)) {
		var addressString = ""
		for baker in uniqueBakers {
			addressString += baker.address
			addressString += ","
		}
		
		for payoutAddress in payoutAddresses.values {
			addressString += payoutAddress.address
			addressString += ","
		}
		
		let _ = addressString.removeLast()
		
		var url = config.tzktURL
		url.appendPathComponent("v1/accounts/\(forAddress)/operations")
		url.appendQueryItem(name: "limit", value: 1)
		url.appendQueryItem(name: "type", value: "transaction")
		url.appendQueryItem(name: "sender.in", value: addressString)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTTransaction].self, completion: completion)
	}
	
	/// Combine fetching cycles and rewards into one function to simplify logic
	private func getCyclesAndRewards(forAddress: String, completion: @escaping ((Result<(cycles: [TzKTCycle], rewards: [TzKTDelegatorReward]), KukaiError>) -> Void)) {
		let dispatchGroup = DispatchGroup()
		
		var currentCycles: [TzKTCycle] = []
		var currentRewards: [TzKTDelegatorReward] = []
		
		dispatchGroup.enter()
		cycles { result in
			guard let res = try? result.get() else {
				completion(Result.failure(KukaiError.unknown(withString: "failed to get or parse cycles")))
				return
			}
			
			currentCycles = res
			dispatchGroup.leave()
		}
		
		dispatchGroup.enter()
		delegatorRewards(forAddress: forAddress, completion: { result in
			guard let res = try? result.get() else {
				completion(Result.failure(KukaiError.unknown(withString: "failed to get or parse rewards")))
				return
			}
			
			currentRewards = res
			dispatchGroup.leave()
		})
		
		dispatchGroup.notify(queue: .global(qos: .background)) {
			completion(Result.success((cycles: currentCycles, rewards: currentRewards)))
		}
	}
	
	
	
	// MARK: Network
	
	/**
	 Call https://api.tzkt.io/v1/cycles?limit=... to get the 10 most recent cycles
	 */
	public func cycles(limit: Int = 25, completion: @escaping ((Result<[TzKTCycle], KukaiError>) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/cycles")
		url.appendQueryItem(name: "limit", value: limit)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTCycle].self, completion: completion)
	}
	
	/**
	 Given a list of cycles, search through them to find what cycle a given block level appeared in
	 If leveled supplied is less than the firstLevel of the last cycle, return the last
	 */
	public func cycleForLevel(cycles: [TzKTCycle], level: Decimal) -> TzKTCycle? {
		guard cycles.count > 0 else {
			return nil
		}
		
		if let last = cycles.last, last.firstLevel > level {
			// Level is in the past, return last cycle we have
			return last
			
		} else if let first = cycles.first, first.lastLevel < level {
			// Delegation level is in the future, return nil
			return nil
			
		} else {
			for cycle in cycles {
				if cycle.lastLevel < level {
					return cycle
				}
			}
		}
		
		return nil
	}
	
	
	
	// MARK: - Block checker
	
	/**
	Query details about the given operation
	- parameter byHash: The operation hash to query.
	- parameter completion: A completion colsure called when the request is done.
	*/
	public func getOperation(byHash hash: String, completion: @escaping (([TzKTOperation]?, KukaiError?) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/operations/" + hash)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTOperation].self) { (result) in
			switch result {
				case .success(let operations):
					completion(operations, nil)
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Parse error: %@", "\(error)")
					completion(nil, KukaiError.internalApplicationError(error: error))
			}
		}
	}
	
	
	
	
	
	// MARK: - Account monitoring
	
	/**
	 Open a websocket connection to request a notification for any changes to the given account. The @Published var `accountDidChange` will be notified if something occurs
	 - parameter address: The Tz address of the account to monitor
	 */
	public func listenForAccountChanges(addresses: [String]) {
		addressesToWatch = addresses
		isListening = true
		
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
				
				if let data = obj.data {
					for addressObj in data {
						self?.accountDidChange = addressObj.address
					}
				}
				
			} catch (let error) {
				os_log("Failed to parse incoming websocket data: %@", log: .tzkt, type: .error, "\(error)")
				self?.signalrConnection?.stop()
				self?.isListening = false
				//completion(false, error, KukaiError.internalApplicationError(error: error))
			}
		})
		signalrConnection?.delegate = self
		signalrConnection?.start()
	}
	
	/**
	 Close the websocket from `listenForAccountChanges`
	 */
	public func stopListeningForAccountChanges() {
		os_log(.debug, log: .kukaiCoreSwift, "Cancelling listenForAccountChanges")
		signalrConnection?.stop()
		isListening = false
	}
	
	/**
	 Close the current connection and open another
	 */
	public func changeAddressToListenForChanges(addresses: [String]) {
		self.newAddressesToWatch = addresses
		self.stopListeningForAccountChanges()
	}
	
	
	
	
	
	// MARK: - Balances
	
	/**
	 Get the count of tokens the given address has balances for (excluding zero balances)
	 - parameter forAddress: The tz address to search for
	 - parameter completion: The completion block called with a `Result` containing the number or an error
	 */
	public func getBalanceCount(forAddress: String, completion: @escaping (Result<Int, KukaiError>) -> Void) {
		var url = config.tzktURL
		url.appendPathComponent("v1/tokens/balances/count")
		url.appendQueryItem(name: "account", value: forAddress)
		url.appendQueryItem(name: "balance.gt", value: 0)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: Int.self) { (result) in
			completion(result)
		}
	}
	
	/**
	 Tokens balances and metadata need to be fetch from a paginated API. THis function calls a sinlerequest or 1 page of balances / metadata
	 - parameter forAddress: The tz address to search for
	 - parameter offset: The starting position
	 - parameter completion: The completion block called with a `Result` containing an array of balances or an error
	 */
	public func getBalancePage(forAddress: String, offset: Int = 0, completion: @escaping ((Result<[TzKTBalance], KukaiError>) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/tokens/balances")
		url.appendQueryItem(name: "account", value: forAddress)
		url.appendQueryItem(name: "balance.gt", value: 0)
		url.appendQueryItem(name: "offset", value: offset * TzKTClient.Constants.tokenBalanceQuerySize)
		url.appendQueryItem(name: "limit", value: TzKTClient.Constants.tokenBalanceQuerySize)
		url.appendQueryItem(name: "sort.desc", value: "lastLevel")
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTBalance].self) { (result) in
			completion(result)
		}
	}
	
	/**
	 Get the account object from TzKT caontaining information about the address, its balance and baker
	 - parameter forAddress: The tz address to search for
	 - parameter completion: The completion block called with a `Result` containing an object or an error
	 */
	public func getAccount(forAddress: String, completion: @escaping ((Result<TzKTAccount, KukaiError>) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/accounts/\(forAddress)")
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: TzKTAccount.self) { (result) in
			completion(result)
		}
	}
	
	/**
	 Get all balances from one function call, by fetching the result from `getBalanceCount` and using that to decide how many pages should be called
	 - parameter forAddress: The tz address to search for
	 - parameter completion: The completion block called with a `Result` containing an object or an error
	 */
	public func getAllBalances(forAddress address: String, completion: @escaping ((Result<Account, KukaiError>) -> Void)) {
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
	
	/// Private function to fetch all the balance pages and stich together
	private func getAllBalances(forAddress address: String, numberOfPages: Int, completion: @escaping ((Result<Account, KukaiError>) -> Void)) {
		let dispatchGroup = DispatchGroup()
		
		var tzktAccount = TzKTAccount(balance: 0, delegate: TzKTAccountDelegate(alias: nil, address: "", active: false), delegationLevel: 0)
		var tokenBalances: [TzKTBalance] = []
		var liquidityTokens: [DipDupPositionData] = []
		var errorFound: KukaiError? = nil
		var groupedData: (tokens: [Token], nftGroups: [Token], recentNFTs: [NFT]) = (tokens: [], nftGroups: [], recentNFTs: [])
		
		
		dispatchGroup.enter()
		dispatchGroup.enter()
		
		// Get XTZ balance from TzKT Account
		self.getAccount(forAddress: address) { result in
			switch result {
				case .success(let account):
					tzktAccount = account
					
				case .failure(let error):
					errorFound = error
			}
			dispatchGroup.leave()
		}
		
		
		// Get Liquidity Tokens from DipDup
		self.dipDupClient.getLiquidityFor(address: address) { result in
			switch result {
				case .success(let graphResponse):
					liquidityTokens = graphResponse.data?.position ?? []
					
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
				groupedData = self?.groupBalances(tokenBalances, filteringOutLiquidityTokens: liquidityTokens) ?? (tokens: [], nftGroups: [], recentNFTs: [])
				let account = Account(walletAddress: address, xtzBalance: tzktAccount.xtzBalance, tokens: groupedData.tokens, nfts: groupedData.nftGroups, recentNFTs: groupedData.recentNFTs, liquidityTokens: liquidityTokens, delegate: tzktAccount.delegate, delegationLevel: tzktAccount.delegationLevel)
				
				completion(Result.success(account))
			}
		}
	}
	
	/// Private function to add balance pages together and group NFTs under their parent contracts
	private func groupBalances(_ balances: [TzKTBalance], filteringOutLiquidityTokens liquidityTokens: [DipDupPositionData]) -> (tokens: [Token], nftGroups: [Token], recentNFTs: [NFT]) {
		var tokens: [Token] = []
		var nftGroups: [Token] = []
		var recentNFTs: [NFT] = []
		var tempRecentNFTs: [TzKTBalance] = []
		var tempNFT: [String: [TzKTBalance]] = [:]
		
		for balance in balances {
			
			// Check if balance is a liquidityToken and ignore it
			// Liquidity baking is a standalone contract address. Hardcoding address for now, revisit how to query if it ever migrates to another token
			if balance.token.contract.address == "KT1AafHA1C1vk959wvHWBispY9Y2f3fxBUUo" {
				continue
			}
			
			// Quipuswap exchange contracts hold the token inside its storage, so check if the current balance, matches any of the exchange contracts
			if liquidityTokens.contains(where: { $0.exchange.address == balance.token.contract.address }) {
				continue
			}
			
			
			// If its an NFT, hold onto for later
			if balance.isNFT() {
				if tempRecentNFTs.count < 10 {
					tempRecentNFTs.append(balance)
				}
				
				var uniqueKey = balance.token.contract.address
				if let mintingTool = balance.token.metadata?.mintingTool {
					uniqueKey += mintingTool
				}
				
				if tempNFT[uniqueKey] == nil {
					tempNFT[uniqueKey] = [balance]
				} else {
					tempNFT[uniqueKey]?.append(balance)
				}
				continue
			}
			
			// Else create a Token object and put into array
			tokens.append(Token(from: balance.token, andTokenAmount: balance.tokenAmount))
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
				symbol: first.token.displaySymbol,
				tokenType: .nonfungible,
				faVersion: first.token.standard,
				balance: TokenAmount.zero(),
				thumbnailURL: TzKTClient.avatarURL(forToken: first.token.contract.address),
				tokenContractAddress: first.token.contract.address,
				tokenId: Decimal(string: first.token.tokenId) ?? 0,
				nfts: temp,
				mintingTool: first.token.metadata?.mintingTool
			)
			
			nftGroups.append(nftToken)
		}
		
		for nftBalance in tempRecentNFTs {
			recentNFTs.append(NFT(fromTzKTBalance: nftBalance))
		}
		
		return (tokens: tokens, nftGroups: nftGroups.sorted(by: { $0.id > $1.id }), recentNFTs: recentNFTs)
	}
	
	/**
	 In order to access the cached images, you need the URL it was downloaded from. This can either be found inside the `Token` objects returned as part of `Account` from the `fetchAccountInfo` func.
	 Or, if you need to use it seperately, given the token address you can use this function
	 - parameter forToken: The token address who's image you are looking for.
	 */
	public static func avatarURL(forToken token: String) -> URL? {
		guard let imageURL = URL(string: "https://services.tzkt.io/v1/avatars/\(token)") else {
			return nil
		}
		
		return imageURL
	}
	
	
	
	// MARK: - Transaction History
	
	public func fetchTransactions(forAddress address: String, limit: Int = 50, completion: @escaping (([TzKTTransaction]) -> Void)) {
		self.dispatchGroupTransactions = DispatchGroup()
		dispatchGroupTransactions.enter()
		dispatchGroupTransactions.enter()
		
		var url = config.tzktURL
		url.appendPathComponent("v1/accounts/\(address)/operations")
		url.appendQueryItem(name: "type", value: "delegation,origination,transaction,reveal")
		url.appendQueryItem(name: "micheline", value: 1)
		url.appendQueryItem(name: "limit", value: limit)
		
		tempTransactions = []
		tempTokenTransfers = []
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTTransaction].self) { [weak self] (result) in
			switch result {
				case .success(let transactions):
					self?.tempTransactions = transactions
					self?.queryFaTokenReceives(forAddress: address, lastId: self?.tempTransactions.last?.id)
					self?.dispatchGroupTransactions.leave()
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Parse error 1: %@", "\(error)")
					self?.dispatchGroupTransactions.leave()
					self?.dispatchGroupTransactions.leave()
			}
		}
		
		// When both done, add the arrays, re-sort and pass it to the parse function to create the transactionHistory object
		self.dispatchGroupTransactions.notify(queue: .main) { [weak self] in
			self?.tempTransactions.sort { $0.level > $1.level }
			
			completion(self?.tempTransactions ?? [])
		}
	}
	
	private func queryFaTokenReceives(forAddress address: String, lastId: Decimal?) {
		guard let id = lastId else {
			self.dispatchGroupTransactions.leave()
			return
		}
		
		var url = config.tzktURL
		url.appendPathComponent("v1/tokens/transfers")
		url.appendQueryItem(name: "anyof.from.to", value: address)
		url.appendQueryItem(name: "id.gt", value: id.description)
		url.appendQueryItem(name: "offset", value: 0)
		url.appendQueryItem(name: "sort.desc", value: "id")
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTTokenTransfer].self) { [weak self] (result) in
			switch result {
				case .success(let transactions):
					self?.tempTokenTransfers = transactions
					self?.mergeTokenTransfersWithTransactions()
					self?.dispatchGroupTransactions.leave()
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Parse error 2: %@", "\(error)")
					self?.dispatchGroupTransactions.leave()
			}
		}
	}
	
	private func mergeTokenTransfersWithTransactions() {
		var transactionsToRemove: [Int] = []
		var transfersToRemove: [Int] = []
		
		for (transferIndex, transfer) in self.tempTokenTransfers.enumerated() {
			for (transactionIndex, transaction) in self.tempTransactions.enumerated() {
				if transfer.transactionId == transaction.id && transaction.tokenTransfersCount == nil {
					self.tempTransactions[transactionIndex].tzktTokenTransfer = transfer
					self.tempTransactions[transactionIndex].target = transfer.to ?? transfer.token.contract // replace target == contract, with the final wallet destination (if available)
					transfersToRemove.append(transferIndex)
					
				} else if transfer.transactionId == transaction.id && transaction.tokenTransfersCount != nil {
					transactionsToRemove.append(transactionIndex)
				}
			}
		}
		self.tempTokenTransfers.remove(atOffsets: IndexSet(transfersToRemove))
		self.tempTransactions.remove(atOffsets: IndexSet(transactionsToRemove))
		
		for leftOverTransfer in self.tempTokenTransfers {
			self.tempTransactions.append( TzKTTransaction(from: leftOverTransfer) )
		}
		
		self.tempTokenTransfers = []
	}
	
	public func groupTransactions(transactions: [TzKTTransaction], currentWalletAddress: String) -> [TzKTTransactionGroup] {
		var tempTrans: [TzKTTransaction] = []
		var groups: [TzKTTransactionGroup] = []
		
		for tran in transactions {
			
			// Filter out internal operations
			if tran.hasInternals == false && (tran.sender.address != currentWalletAddress && tran.target?.address != currentWalletAddress) {
				continue
			}
			
			var processedTran = tran
			processedTran.processAdditionalData(withCurrentWalletAddress: currentWalletAddress)
			
			if tempTrans.count == 0 || tempTrans.first?.hash == tran.hash {
				tempTrans.append(processedTran)
				
			} else if tempTrans.first?.hash != tran.hash, let group = TzKTTransactionGroup(withTransactions: tempTrans, currentWalletAddress: currentWalletAddress) {
				groups.append(group)
				tempTrans = [processedTran]
			}
		}
		
		if tempTrans.count > 0, let group = TzKTTransactionGroup(withTransactions: tempTrans, currentWalletAddress: currentWalletAddress) {
			groups.append(group)
			tempTrans = []
		}
		
		return groups
	}
}

extension TzKTClient: HubConnectionDelegate {
	
	public func connectionDidOpen(hubConnection: HubConnection) {
		
		// Request to be subscribed to events belonging to the given account
		let subscription = AccountSubscription(addresses: addressesToWatch)
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
		
		if newAddressesToWatch.count > 0 {
			self.listenForAccountChanges(addresses: newAddressesToWatch)
			newAddressesToWatch = []
		}
	}
	
	public func connectionDidFailToOpen(error: Error) {
		os_log("Failed to open SignalR connection to listen for changes: %@", log: .tzkt, type: .error, "\(error)")
	}
}
