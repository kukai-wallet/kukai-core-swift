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
	
	private let networkService: NetworkService
	private let config: TezosNodeClientConfig
	private let betterCallDevClient: BetterCallDevClient
	
	private var tempTransactions: [TzKTTransaction] = []
	private var dispatchGroupTransactions = DispatchGroup()
	private let tokenBalanceQueue: DispatchQueue
	
	private var signalrConnection: HubConnection? = nil
	private var addressToWatch: String = ""
	
	public var isListening = false
	
	@Published public var accountDidChange: Bool = false
	
	
	
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
		self.tokenBalanceQueue = DispatchQueue(label: "TzKTClient.tokens", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
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
	
	
	
	
	
	// MARK: - Account monitoring
	
	/**
	 Open a websocket connection to request a notification for any changes to the given account. The @Published var `accountDidChange` will be notified if something occurs
	 - parameter address: The Tz address of the account to monitor
	 */
	public func listenForAccountChanges(address: String) {
		addressToWatch = address
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
				
				if obj.data != nil {
					self?.accountDidChange = true
				}
				
			} catch (let error) {
				os_log("Failed to parse incoming websocket data: %@", log: .tzkt, type: .error, "\(error)")
				self?.signalrConnection?.stop()
				self?.isListening = false
				//completion(false, error, ErrorResponse.unknownParseError(error: error))
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
	
	
	
	
	
	// MARK: - Balances
	
	/**
	 Get the count of tokens the given address has balances for (excluding zero balances)
	 - parameter forAddress: The tz address to search for
	 - parameter completion: The completion block called with a `Result` containing the number or an error
	 */
	public func getBalanceCount(forAddress: String, completion: @escaping (Result<Int, ErrorResponse>) -> Void) {
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
	public func getBalancePage(forAddress: String, offset: Int = 0, completion: @escaping ((Result<[TzKTBalance], ErrorResponse>) -> Void)) {
		var url = config.tzktURL
		url.appendPathComponent("v1/tokens/balances")
		url.appendQueryItem(name: "account", value: forAddress)
		url.appendQueryItem(name: "balance.gt", value: 0)
		url.appendQueryItem(name: "offset", value: offset * TzKTClient.Constants.tokenBalanceQuerySize)
		url.appendQueryItem(name: "limit", value: TzKTClient.Constants.tokenBalanceQuerySize)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTBalance].self) { (result) in
			completion(result)
		}
	}
	
	/**
	 Get the account object from TzKT caontaining information about the address, its balance and baker
	 - parameter forAddress: The tz address to search for
	 - parameter completion: The completion block called with a `Result` containing an object or an error
	 */
	public func getAccount(forAddress: String, completion: @escaping ((Result<TzKTAccount, ErrorResponse>) -> Void)) {
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
	public func getAllBalances(forAddress address: String, completion: @escaping ((Result<Account, ErrorResponse>) -> Void)) {
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
	private func getAllBalances(forAddress address: String, numberOfPages: Int, completion: @escaping ((Result<Account, ErrorResponse>) -> Void)) {
		let dispatchGroup = DispatchGroup()
		
		var tzkTAccount = TzKTAccount(balance: 0, delegate: TzKTAccountDelegate(alias: nil, address: "", active: false))
		var tokenBalances: [TzKTBalance] = []
		var errorFound: ErrorResponse? = nil
		var groupedData: (tokens: [Token], nftGroups: [Token]) = (tokens: [], nftGroups: [])
		
		
		// Get XTZ balance from TzKT Account
		dispatchGroup.enter()
		self.getAccount(forAddress: address) { result in
			switch result {
				case .success(let account):
					tzkTAccount = account
					
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
				groupedData = self?.groupBalances(tokenBalances) ?? (tokens: [], nftGroups: [])
				let account = Account(walletAddress: address, xtzBalance: tzkTAccount.xtzBalance, tokens: groupedData.tokens, nfts: groupedData.nftGroups, bakerAddress: tzkTAccount.delegate?.address, bakerAlias: tzkTAccount.delegate?.alias)
				
				completion(Result.success(account))
			}
		}
	}
	
	/// Private function to add balance pages together and group NFTs under their parent contracts
	private func groupBalances(_ balances: [TzKTBalance]) -> (tokens: [Token], nftGroups: [Token]) {
		var tokens: [Token] = []
		var nftGroups: [Token] = []
		var tempNFT: [String: [TzKTBalance]] = [:]
		
		for balance in balances {
			
			// If its an NFT, hold onto for later
			if balance.isNFT() {
				if tempNFT[balance.token.contract.address] == nil {
					tempNFT[balance.token.contract.address] = [balance]
				} else {
					tempNFT[balance.token.contract.address]?.append(balance)
				}
				continue
			}
			
			// Else create a Token object and put into array
			let token = Token(
				name: balance.token.metadata?.name ?? "",
				symbol: balance.token.displaySymbol,
				tokenType: .fungible,
				faVersion: balance.token.standard,
				balance: balance.tokenAmount,
				thumbnailURL: balance.token.metadata?.thumbnailURL ?? avatarURL(forToken: balance.token.contract.address),
				tokenContractAddress: balance.token.contract.address,
				tokenId: Decimal(string: balance.token.tokenId) ?? 0,
				nfts: []
			)
			
			tokens.append(token)
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
				thumbnailURL: avatarURL(forToken: first.token.contract.address),
				tokenContractAddress: first.token.contract.address,
				tokenId: Decimal(string: first.token.tokenId) ?? 0,
				nfts: temp
			)
			
			nftGroups.append(nftToken)
		}
		
		return (tokens: tokens, nftGroups: nftGroups.sorted(by: { $0.id > $1.id }))
	}
	
	/**
	 In order to access the cached images, you need the URL it was downloaded from. This can either be found inside the `Token` objects returned as part of `Account` from the `fetchAccountInfo` func.
	 Or, if you need to use it seperately, given the token address you can use this function
	 - parameter forToken: The token address who's image you are looking for.
	 */
	public func avatarURL(forToken token: String) -> URL? {
		guard let imageURL = URL(string: "https://services.tzkt.io/v1/avatars/\(token)") else {
			return nil
		}
		
		return imageURL
	}
	
	
	
	// MARK: - Transaction History
	
	public func fetchTransactions(forAddress address: String, completion: @escaping (([TzKTTransaction]) -> Void)) {
		self.dispatchGroupTransactions = DispatchGroup()
		dispatchGroupTransactions.enter()
		dispatchGroupTransactions.enter()
		dispatchGroupTransactions.enter()
		
		var url = config.tzktURL
		url.appendPathComponent("v1/accounts/\(address)/operations")
		url.appendQueryItem(name: "type", value: "delegation,origination,transaction,reveal")
		url.appendQueryItem(name: "micheline", value: 1)
		url.appendQueryItem(name: "limit", value: 50)
		
		tempTransactions = []
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [TzKTTransaction].self) { [weak self] (result) in
			guard let self = self else { return }
			
			switch result {
				case .success(let transactions):
					self.tempTransactions = transactions
					self.queryFaTokenReceives(forAddress: address, lastId: self.tempTransactions.last?.id)
					self.dispatchGroupTransactions.leave()
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Parse error 1: %@", "\(error)")
					self.dispatchGroupTransactions.leave()
					self.dispatchGroupTransactions.leave()
					self.dispatchGroupTransactions.leave()
			}
		}
		
		
		// When both done, add the arrays, re-sort and pass it to the parse function to create the transactionHistory object
		self.dispatchGroupTransactions.notify(queue: .main) { [weak self] in
			self?.tempTransactions.sort { $0.level > $1.level }
			
			completion(self?.tempTransactions ?? [])
		}
	}
	
	private func queryFaTokenReceives(forAddress address: String, lastId: Int?) {
		guard let id = lastId else {
			self.dispatchGroupTransactions.leave()
			self.dispatchGroupTransactions.leave()
			return
		}
		
		var url1 = config.tzktURL
		url1.appendPathComponent("v1/operations/transactions")
		url1.appendQueryItem(name: "sender.ne", value: address)
		url1.appendQueryItem(name: "target.ne", value: address)
		url1.appendQueryItem(name: "initiator.ne", value: address)
		url1.appendQueryItem(name: "entrypoint", value: "transfer")
		url1.appendQueryItem(name: "parameter.to", value: address)
		url1.appendQueryItem(name: "id.gt", value: id)
		url1.appendQueryItem(name: "status", value: "applied")
		url1.appendQueryItem(name: "micheline", value: 1)
		
		var url2 = config.tzktURL
		url2.appendPathComponent("v1/operations/transactions")
		url2.appendQueryItem(name: "sender.ne", value: address)
		url2.appendQueryItem(name: "target.ne", value: address)
		url2.appendQueryItem(name: "initiator.ne", value: address)
		url2.appendQueryItem(name: "entrypoint", value: "transfer")
		url2.appendQueryItem(name: "parameter.[*].txs.[*].to_", value: address)
		url2.appendQueryItem(name: "id.gt", value: id)
		url2.appendQueryItem(name: "status", value: "applied")
		url2.appendQueryItem(name: "micheline", value: 1)
		
		
		networkService.request(url: url1, isPOST: false, withBody: nil, forReturnType: [TzKTTransaction].self) { [weak self] (result) in
			guard let self = self else { return }
			
			switch result {
				case .success(let transactions):
					self.tempTransactions.append(contentsOf: transactions)
					self.dispatchGroupTransactions.leave()
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Parse error 2: %@", "\(error)")
					self.dispatchGroupTransactions.leave()
			}
		}
		
		networkService.request(url: url2, isPOST: false, withBody: nil, forReturnType: [TzKTTransaction].self) { [weak self] (result) in
			guard let self = self else { return }
			
			switch result {
				case .success(let transactions):
					self.tempTransactions.append(contentsOf: transactions)
					self.dispatchGroupTransactions.leave()
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Parse error 3: %@", "\(error)")
					self.dispatchGroupTransactions.leave()
			}
		}
	}
	
	public func groupTransactions(transactions: [TzKTTransaction], currentWalletAddress: String) -> [TzKTTransactionGroup] {
		var tempTrans: [TzKTTransaction] = []
		var groups: [TzKTTransactionGroup] = []
		
		for tran in transactions {
			if tempTrans.count == 0 || tempTrans.first?.hash == tran.hash {
				tempTrans.append(tran)
				
			} else if tempTrans.first?.hash != tran.hash, let group = TzKTTransactionGroup(withTransactions: tempTrans, currentWalletAddress: currentWalletAddress) {
				groups.append(group)
				tempTrans = [tran]
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
		let subscription = AccountSubscription(addresses: [addressToWatch])
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
	}
	
	public func connectionDidFailToOpen(error: Error) {
		os_log("Failed to open SignalR connection to listen for changes: %@", log: .tzkt, type: .error, "\(error)")
	}
	
	public func changeAddressToListenForChanges(address: String) {
		addressToWatch = address
		
		let subscription = AccountSubscription(addresses: [])
		signalrConnection?.invoke(method: "SubscribeToAccounts", subscription) { [weak self] error in
			if let error = error {
				os_log("Remove account subscription failed: %@", log: .tzkt, type: .error, "\(error)")
				self?.signalrConnection?.stop()
				
			} else {
				os_log("Remove account subscription succeeded, requesting new subscription", log: .tzkt, type: .debug)
				
				
				let subscription = AccountSubscription(addresses: [address])
				self?.signalrConnection?.invoke(method: "SubscribeToAccounts", subscription) { [weak self] error in
					if let error = error {
						os_log("Subscribe to account changes failed: %@", log: .tzkt, type: .error, "\(error)")
						self?.signalrConnection?.stop()
					} else {
						os_log("Subscribe to account changes succeeded, waiting for objects", log: .tzkt, type: .debug)
					}
				}
			}
		}
	}
}
