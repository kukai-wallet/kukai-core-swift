//
//  TzKTClient.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 18/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import SignalRClient
import os.log


/// TzKT is an indexer for Tezos, who's API allows developers to query details about wallets, and transactions
public class TzKTClient {
	
	/// Unique Errors that TzKTClient can throw
	public enum TzKTServiceError: Error {
		case invalidURL
		case parseError(String)
	}
	
	
	private let networkService: NetworkService
	private let config: TezosNodeClientConfig
	private let betterCallDevClient: BetterCallDevClient
	private var currentWalletAddress: String = ""
	private var supportedTokens: [Token] = []
	
	private var transactionHistory: [TimeInterval: [TzKTTransaction]] = [:]
	private var tempTransactions: [TzKTTransaction] = []
	private var dispatchGroupTransactions = DispatchGroup()
	
	private var signalrConnection: HubConnection? = nil
	private var addressToWatch: String = ""
	private var injectionNotificationCallback: ((Bool, Error?, ErrorResponse?) -> Void)? = nil
	
	
	
	
	// MARK: - Init
	
	/**
	Init a `TzKTClient` with a `NetworkService` and a `TezosNodeClientConfig` and a `BetterCallDevClient`.
	- parameter networkService: `NetworkService` used to manage network communication.
	- parameter config: `TezosNodeClientConfig` used to apss in settings.
	- parameter betterCallDevClient: `BetterCallDevClient` used to fetch more detailed errors about operation failures involving smart contracts.
	*/
	public init(networkService: NetworkService, config: TezosNodeClientConfig, betterCallDevClient: BetterCallDevClient) {
		self.networkService = networkService
		self.config = config
		self.betterCallDevClient = betterCallDevClient
	}
	
	
	
	
	
	// MARK: - Storage
	
	/**
	 Get the storage of a given contract and parse it to a supplied model type
	 - parameter forContract: The KT1 contract address to query
	 - parameter ofType: The Codable compliant model to parse the response as
	 - parameter completion: A completion block called, returning a Swift Result type
	 */
	public func getStorage<T: Codable>(forContract contract: String, ofType: T.Type, completion: @escaping ((Result<T, ErrorResponse>) -> Void)) {
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
	public func getBigMap<T: Codable>(forId id: String, ofType: T.Type, completion: @escaping ((Result<T, ErrorResponse>) -> Void)) {
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
	public func getBigMapKey<T: Codable>(forId id: String, key: String, ofType: T.Type, completion: @escaping ((Result<T, ErrorResponse>) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/bigmaps/\(id)/keys")
		url.appendQueryItem(name: "key", value: key)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: T.self, completion: completion)
	}
	
	
	
	
	// MARK: - Block checker
	
	/**
	Query details about the given operation
	- parameter byHash: The operation hash to query.
	- parameter completion: A completion colsure called when the request is done.
	*/
	public func getOperation(byHash hash: String, completion: @escaping (([TzKTOperation]?, ErrorResponse?) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/operations/" + hash)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTOperation].self) { (result) in
			switch result {
				case .success(let operations):
					completion(operations, nil)
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Parse error: %@", "\(error)")
					completion(nil, ErrorResponse.unknownParseError(error: error))
			}
		}
	}
	
	/**
	Poll the TzKT APi until a record of the given operation is found
	- parameter ofHash: The operation hash to query.
	- parameter completion: A completion colsure called when the API returns a valid operation response, or an error indicating a problem with the service.
	*/
	public func waitForInjection(ofHash hash: String, fromAddress address: String, completion: @escaping ((Bool, Error?, ErrorResponse?) -> Void)) {
		addressToWatch = address
		injectionNotificationCallback = completion
		
		var url = config.tzktURL
		url.appendPathComponent("v1/events")
		
		if config.loggingConfig.logNetworkSuccesses {
			signalrConnection = HubConnectionBuilder(url: url).withLogging(minLogLevel: .debug).build()
		} else {
			signalrConnection = HubConnectionBuilder(url: url).build()
		}
		
		
		// Register for SignalR operation events
		signalrConnection?.on(method: "operations", callback: { [weak self] argumentExtractor in
			do {
				let obj = try argumentExtractor.getArgument(type: OperationSubscriptionResponse.self)
				os_log("Incoming object parsed: %@", log: .tzkt, type: .debug, "\(obj)")
				
				for op in obj.data ?? [] {
					if op.hash == hash {
						self?.signalrConnection?.stop()
						completion(true, nil, nil)
						return
					}
				}
				
			} catch (let error) {
				os_log("Failed to parse incoming operation: %@", log: .tzkt, type: .error, "\(error)")
				self?.signalrConnection?.stop()
				completion(false, error, ErrorResponse.unknownParseError(error: error))
			}
		})
		signalrConnection?.delegate = self
		signalrConnection?.start()
	}
	
	/**
	Cancel the polling operation from `waitForInjection`
	*/
	public func cancelWait() {
		os_log(.debug, log: .kukaiCoreSwift, "Cancelling waitForInjection")
		signalrConnection?.stop()
	}
	
	
	
	
	
	// MARK: - Transaction History
	
	/**
	Clear the in RAM copy of transaction history
	*/
	public func clearHistory() {
		transactionHistory = [:]
	}
	
	/**
	Get the current in RAM transation history, with optional filters
	- parameter filterByToken: only retuns transactions where the primary or secondary token is of this type.
	- parameter orFilterByAddress: only retuns transactions where the source or destination address matches this string
	- returns transactions grouped by day in a dictionary with a key of `TimeInterval`.
	*/
	public func currentTransactionHistory(filterByToken: Token?, orFilterByAddress: String?) -> [TimeInterval: [TzKTTransaction]] {
		
		// Anything involving the given token
		if let filterToken = filterByToken {
			return transactionHistory.mapValues {
				$0.filter {
					return ($0.secondaryToken?.symbol == filterToken.symbol || $0.token?.symbol == filterToken.symbol)
				}
			}.filter { !$0.value.isEmpty }
		}
		
		// Anything sent or recieved by the given address
		if let filterAddress = orFilterByAddress {
			return transactionHistory.mapValues {
				$0.filter {
					return ($0.sender.address == filterAddress || $0.target?.address == filterAddress || $0.newDelegate?.address == filterAddress)
				}
			}.filter { !$0.value.isEmpty }
		}
		
		// else return everything
		return transactionHistory
	}
	
	/**
	Query the lastest transaction history and store in RAM. Get access to the data via `currentTransactionHistory(...)`
	- parameter forAddress: the wallet address to query the history for.
	- parameter andSupportedTokens: a list of known tokens, used to add more detail to the transaction objects.
	- parameter completion: a closure indicating the request and processing has finished.
	*/
	public func refreshTransactionHistory(forAddress address: String, andSupportedTokens: [Token], completion: @escaping (() -> Void)) {
		self.currentWalletAddress = address
		self.supportedTokens = andSupportedTokens
		
		var url = config.tzktURL
		url.appendPathComponent("v1/accounts/\(address)/operations")
		url.appendQueryItem(name: "type", value: "delegation,origination,transaction,reveal")
		
		self.dispatchGroupTransactions = DispatchGroup()
		tempTransactions = []
		
		
		// Fetch "Account Transactions" from TZKT. Currently includes everything except Native Token Receives
		self.dispatchGroupTransactions.enter()
		self.dispatchGroupTransactions.enter()
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTTransaction].self) { [weak self] (result) in
			switch result {
				case .success(let transactions):
					self?.tempTransactions = transactions
					self?.queryNativeTokenReceives(forAddress: address, lastTransaction: self?.tempTransactions.last)
					self?.dispatchGroupTransactions.leave()
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Parse error full: %@", "\(error)")
					self?.dispatchGroupTransactions.leave()
					self?.dispatchGroupTransactions.leave()
			}
		}
		
		
		// When both done, add the arrays, re-sort and pass it to the parse function to create the transactionHistory object
		self.dispatchGroupTransactions.notify(queue: .main) { [weak self] in
			self?.tempTransactions.sort { $0.level > $1.level }
			
			self?.parseTransactions(self?.tempTransactions)
			self?.tempTransactions = []
			completion()
		}
	}
	
	/**
	Private helper function to seperately query the FA token recieve events
	*/
	private func queryNativeTokenReceives(forAddress address: String, lastTransaction: TzKTTransaction?) {
		// Fetch Native Token Receives using a separate request
		var url = config.tzktURL
		url.appendPathComponent("v1/operations/transactions")
		url.appendQueryItem(name: "entrypoint", value: "transfer")
		url.appendQueryItem(name: "parameter.to", value: "\(address)")
		url.appendQueryItem(name: "initiator.null", value: nil) // filter out duplicates from Dexter send events
		url.appendQueryItem(name: "sort.desc", value: "level")
		
		if let transaction = lastTransaction {
			url.appendQueryItem(name: "timestamp.gt", value: "\(transaction.timestamp)")
		} else {
			url.appendQueryItem(name: "limit", value: "25")
		}
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTTransaction].self) { [weak self] (result) in
			switch result {
				case .success(let transactions):
					self?.tempTransactions.append(contentsOf: transactions)
					self?.dispatchGroupTransactions.leave()
	
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Transaction history native token error: %@", "\(error)")
					self?.dispatchGroupTransactions.leave()
			}
		}
	}
	
	/**
	Private helper function to parse and process the JSON data into more useful objects
	*/
	private func parseTransactions(_ transactions: [TzKTTransaction]?) {
		guard let transactions = transactions else {
			return
		}
		
		// Add additional data to transactions so that we can group / merge to make them easier to understand for users
		self.transactionHistory = [:]
		var transactionsToBeMerged: [TzKTTransaction] = []
		var transactionToAdd: TzKTTransaction? = nil
		
		// Loop through transactions to determine which need to be displayed, and which need to be merged
		for (index, transaction) in transactions.enumerated() {
			transaction.augmentTransaction(withUsersAddress: currentWalletAddress, andTokens: supportedTokens)
			transactionToAdd = nil
			
			// If there is another transaction, check if counters match. If so, store for merging with next transaction (or next again)
			if let nextTransaction = transactions[safe: index+1], transaction.counter == nextTransaction.counter {
				transactionsToBeMerged.append(transaction)
				continue
			}
			
			// If current transaction is .exchangeXtzToToken or .exchangeTokenToXTZ, grab missing info from `transactionsToBeMerged`
			if transaction.subType == .exchangeXTZToToken {
				guard let tokenReceiveTransaction = transactionsToBeMerged.last else {
					transactionsToBeMerged = []
					continue
				}
				
				transaction.secondaryToken = tokenReceiveTransaction.token
				transaction.secondaryAmount = tokenReceiveTransaction.amount
				
				// Clean merged list
				transactionsToBeMerged = []
				transactionToAdd = transaction
				
			} else if transaction.subType == .exchangeTokenToXTZ {
				guard transactionsToBeMerged.count == 2,
					  let subTransaction1 = transactionsToBeMerged[safe: 0],
					  let subTransaction1Token = subTransaction1.token,
					  let subTransaction2 = transactionsToBeMerged[safe: 1] else {
					transactionsToBeMerged = []
					continue
				}
				
				let xtzReceivedTransaction = subTransaction1Token.tokenType == .xtz ? subTransaction1 : subTransaction2
				let tokenDeductedTransaction = subTransaction1Token.tokenType == .xtz ? subTransaction2 : subTransaction1
				
				transaction.token = tokenDeductedTransaction.token
				transaction.amount = tokenDeductedTransaction.amount
				transaction.secondaryToken = xtzReceivedTransaction.token
				transaction.secondaryAmount = xtzReceivedTransaction.amount
				
				// Clean merged list
				transactionsToBeMerged = []
				transactionToAdd = transaction
				
			} else if transaction.subType == .approve {
				
				// Approves happen behind the scenes as a security measure for other operations (e.g. Exchanges).
				// User only cares about the network fee incured. Add to transaction before this one and skip displaying this operation
				if let previousTransaction = transactions[safe: index-1] {
					let tempTransaction = self.transactionHistory[previousTransaction.truncatedTimeInterval]?.last
					tempTransaction?.bakerFee += transaction.bakerFee
					tempTransaction?.storageFee += transaction.storageFee
					tempTransaction?.allocationFee += transaction.allocationFee
					
				} else {
					// If we can't find a previous transaction, then display the approve
					transactionToAdd = transaction
				}
				
			} else {
				transactionToAdd = transaction
			}
			
			
			// add to transaction history array
			guard let transToAdd = transactionToAdd else {
				continue
			}
			
			if self.transactionHistory[transToAdd.truncatedTimeInterval] == nil {
				self.transactionHistory[transToAdd.truncatedTimeInterval] = [transToAdd]
			} else {
				self.transactionHistory[transToAdd.truncatedTimeInterval]?.append(transToAdd)
			}
		}
	}
}

extension TzKTClient: HubConnectionDelegate {
	
	public func connectionDidOpen(hubConnection: HubConnection) {
		
		// Request to be subscribed to events belonging to the given account
		let operationSubscription = OperationSubscription(address: addressToWatch, types: "transaction,origination,delegation")
		signalrConnection?.invoke(method: "SubscribeToOperations", operationSubscription) { [weak self] error in
			if let error = error {
				os_log("Subscribe to operations failed: %@", log: .tzkt, type: .error, "\(error)")
				self?.signalrConnection?.stop()
			} else {
				os_log("Subscribe to operations succeeded, waiting for objects", log: .tzkt, type: .debug)
			}
		}
	}
	
	public func connectionDidClose(error: Error?) {
		
	}
	
	public func connectionDidFailToOpen(error: Error) {
		if let completion = injectionNotificationCallback {
			completion(false, error, ErrorResponse.unknownError())
		}
	}
}
