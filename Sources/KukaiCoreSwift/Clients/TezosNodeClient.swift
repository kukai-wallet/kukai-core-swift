//
//  TezosNodeClient.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 18/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import os.log

/// The TezosNodeClient offers methods for interacting with the Tezos node to fetch balances, send transactions etc.
/// The client will abstract away all the compelx tasks of remote forging, parsing, signing, preapply and injecting operations.
/// It will also convert amounts from the network into `Token` objects to make common tasks easier.
public class TezosNodeClient {
	
	// MARK: - Private Properties
	
	private let metadataQueue: DispatchQueue
	private let dexterQueriesQueue: DispatchQueue
	
	
	
	// MARK: - Public Properties
	
	/// The configuration object containing all the necessary settings to connect and communicate with the Tezos node
	public let config: TezosNodeClientConfig
	
	/// The `NetworkService` object that will perform all the networking calls
	public var networkService: NetworkService
	
	/// The `OperationService` object that will perform forging, parsing, signing, preapply and injections of operations
	public var operationService: OperationService
	
	/// The service responsible for calculating network fees on behalf of the user
	public var feeEstimatorService: FeeEstimatorService
	
	/// Available information about the version of the network, that the conected server is running. Call `tezosNodeClient.fetchNetworkInformation(...)` to populate
	public var networkVersion: NetworkVersion?
	
	/// Available information about the constants of the network, that the conected server is running. Call `tezosNodeClient.fetchNetworkInformation(...)` to populate
	public var networkConstants: NetworkConstants?
	
	/// Types of errors
	public enum TezosNodeClientError: Error {
		case noDexterExchangeAddressFound
		case michelsonParsing
	}
	
	
	
	
	
	// MARK: - Init
	
	/**
	Init a `TezosNodeClient` with a `TezosNodeClientConfig`.
	- parameter config: A configuration object containing all the necessary settings to connect and communicate with the Tezos node.
	*/
	public init(config: TezosNodeClientConfig = TezosNodeClientConfig(withDefaultsForNetworkType: .mainnet)) {
		self.metadataQueue = DispatchQueue(label: "TezosNodeClient.metadata", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
		self.dexterQueriesQueue = DispatchQueue(label: "TezosNodeClient.dexter", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil)
		self.config = config
		self.networkService = NetworkService(urlSession: config.urlSession, loggingConfig: config.loggingConfig)
		self.operationService = OperationService(config: config, networkService: self.networkService)
		self.feeEstimatorService = FeeEstimatorService(config: config, operationService: self.operationService, networkService: self.networkService)
	}
	
	
	
	// MARK: - Balance
	
	/**
	Gets the xtz balance for a given Address.
	- parameter forAddress: A Tezos network address, starting with `"tz1"`, `"tz2"`, `"tz3"` or `"kt1"`
	- parameter completion: A callback containing a new `Token` object matching the xtz standard, or an error.
	*/
	public func getBalance(forAddress address: String, completion: @escaping ((Result<XTZAmount, KukaiError>) -> Void)) {
		self.networkService.send(rpc: RPC.xtzBalance(forAddress: address), withNodeURLs: config.nodeURLs) { (result) in
			switch result {
				case .success(let rpcAmount):
					let xtz = XTZAmount(fromRpcAmount: rpcAmount) ?? XTZAmount.zero()
					completion(Result.success(xtz))
				
				case .failure(let rpcError):
					completion(Result.failure(rpcError))
			}
		}
	}
	
	/**
	Gets the staked xtz balance for a given Address.
	- parameter forAddress: A Tezos network address, starting with `"tz1"`, `"tz2"`, `"tz3"` or `"kt1"`
	- parameter completion: A callback containing a new `Token` object matching the xtz standard, or an error.
	*/
	public func getStakedBalance(forAddress address: String, completion: @escaping ((Result<XTZAmount, KukaiError>) -> Void)) {
		self.networkService.send(rpc: RPC.xtzStakedBalance(forAddress: address), withNodeURLs: config.nodeURLs) { (result) in
			switch result {
				case .success(let rpcAmount):
					let xtz = XTZAmount(fromRpcAmount: rpcAmount ?? "0") ?? XTZAmount.zero()
					completion(Result.success(xtz))
				
				case .failure(let rpcError):
					completion(Result.failure(rpcError))
			}
		}
	}
	
	/**
	Gets the unstaked xtz balance for a given Address.
	- parameter forAddress: A Tezos network address, starting with `"tz1"`, `"tz2"`, `"tz3"` or `"kt1"`
	- parameter completion: A callback containing a new `Token` object matching the xtz standard, or an error.
	*/
	public func getUnstakedBalance(forAddress address: String, completion: @escaping ((Result<XTZAmount, KukaiError>) -> Void)) {
		self.networkService.send(rpc: RPC.xtzUnstakedBalance(forAddress: address), withNodeURLs: config.nodeURLs) { (result) in
			switch result {
				case .success(let rpcAmount):
					let xtz = XTZAmount(fromRpcAmount: rpcAmount ?? "0") ?? XTZAmount.zero()
					completion(Result.success(xtz))
				
				case .failure(let rpcError):
					completion(Result.failure(rpcError))
			}
		}
	}
	
	/**
	Gets the finalisable xtz balance for a given Address.
	- parameter forAddress: A Tezos network address, starting with `"tz1"`, `"tz2"`, `"tz3"` or `"kt1"`
	- parameter completion: A callback containing a new `Token` object matching the xtz standard, or an error.
	*/
	public func getFinalisableBalance(forAddress address: String, completion: @escaping ((Result<XTZAmount, KukaiError>) -> Void)) {
		self.networkService.send(rpc: RPC.xtzFinalisableBalance(forAddress: address), withNodeURLs: config.nodeURLs) { (result) in
			switch result {
				case .success(let rpcAmount):
					let xtz = XTZAmount(fromRpcAmount: rpcAmount ?? "0") ?? XTZAmount.zero()
					completion(Result.success(xtz))
				
				case .failure(let rpcError):
					completion(Result.failure(rpcError))
			}
		}
	}
	
	/**
	Gets the XTZ, staked, unstaked and finalisable balance for a give address.
	- parameter forAddress: A Tezos network address, starting with `"tz1"`, `"tz2"`, `"tz3"` or `"kt1"`
	- parameter completion: A callback containing `(balance: XTZAmount, staked: XTZAmount, unstaked: XTZAmount, finalisable: XTZAmount)`
	*/
	public func getAllBalances(forAddress address: String, completion: @escaping ((Result<(balance: XTZAmount, staked: XTZAmount, unstaked: XTZAmount, finalisable: XTZAmount), KukaiError>) -> Void)) {
		var error: KukaiError? = nil
		var balance: XTZAmount = .zero()
		var staked: XTZAmount = .zero()
		var unstaked: XTZAmount = .zero()
		var finalisable: XTZAmount = .zero()
		
		let dispatchGroup = DispatchGroup()
		dispatchGroup.enter()
		dispatchGroup.enter()
		dispatchGroup.enter()
		dispatchGroup.enter()
		
		getBalance(forAddress: address) { result in
			guard let res = try? result.get() else {
				error = result.getFailure()
				dispatchGroup.leave()
				return
			}
			
			balance = res
			dispatchGroup.leave()
		}
		
		getStakedBalance(forAddress: address) { result in
			guard let res = try? result.get() else {
				error = result.getFailure()
				dispatchGroup.leave()
				return
			}
			
			staked = res
			dispatchGroup.leave()
		}
		
		getUnstakedBalance(forAddress: address) { result in
			guard let res = try? result.get() else {
				error = result.getFailure()
				dispatchGroup.leave()
				return
			}
			
			unstaked = res
			dispatchGroup.leave()
		}
		
		getFinalisableBalance(forAddress: address) { result in
			guard let res = try? result.get() else {
				error = result.getFailure()
				dispatchGroup.leave()
				return
			}
			
			finalisable = res
			dispatchGroup.leave()
		}
		
		
		// When all requests finished, return on main thread
		dispatchGroup.notify(queue: .main) {
			if let err = error {
				completion(Result.failure(err))
				
			} else {
				// TzKT and the RPC handle balances differently. TzKT returns the users entire balance and then requires the app to deduct the staked balance to get the "available" balance. It also does not return finalisable seperately
				// The node however returns the available balance, staked, and finalisable seperately.
				// The entire library has been built around the tzkt approach, assuming "balance" is available + staked. And seperately that staked will include finalisable.
				// The library contains multiple helpers, used everywhere, that deduct these values. So we need to artifically add them together here, so that calls to `account.avaialbleBalance` return the correct thing
				completion(Result.success((balance: (balance + staked + finalisable), staked: (staked + finalisable), unstaked: unstaked, finalisable: finalisable)))
			}
		}
	}
	
	
	
	// MARK: - Delegate
	
	/**
	Gets the delegate for the given address.
	- parameter forAddress: A Tezos network address, starting with `"tz1"`, `"tz2"`, `"tz3"` or `"kt1"`
	- parameter completion: A callback containing a String with the delegate/baker's address, or an error.
	*/
	public func getDelegate(forAddress address: String, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		self.networkService.send(rpc: RPC.getDelegate(forAddress: address), withNodeURLs: config.nodeURLs, completion: completion)
	}
	
	
	
	// MARK: Estimate
	
	/**
	Take an array of operations and estimate the gas, storage, baker fee and burn fees required to inject it onto the network
	If the supplied operations contain suggested fees (e.g. from a dApp) this function will estimate the fee and pick which ever is higher
	- parameter operations: An array of `Operation`'s to be injected.
	- parameter wallet: The `Wallet` that will sign the operation
	- parameter completion: A callback containing an updated array of `Operation`'s with fees set correctly, or an error.
	*/
	public func estimate(operations: [Operation], walletAddress: String, base58EncodedPublicKey: String, isRemote: Bool, completion: @escaping ((Result<FeeEstimatorService.EstimationResult, KukaiError>) -> Void)) {
		
		if let constants = self.networkConstants {
			self.estimate(operations: operations, constants: constants, walletAddress: walletAddress, base58EncodedPublicKey: base58EncodedPublicKey, isRemote: isRemote, completion: completion)
			
		} else {
			self.getNetworkInformation { [weak self] (success, error) in
				guard let constants = self?.networkConstants else {
					completion(Result.failure(error ?? KukaiError.unknown()))
					return
				}
				
				self?.estimate(operations: operations, constants: constants, walletAddress: walletAddress, base58EncodedPublicKey: base58EncodedPublicKey, isRemote: isRemote, completion: completion)
			}
		}
	}
	
	/// Internal function to break up code and make it easier to read. Public function checks to see if the network constants are present, if not will query them and then estimate
	private func estimate(operations: [Operation], constants: NetworkConstants, walletAddress: String, base58EncodedPublicKey: String, isRemote: Bool, completion: @escaping ((Result<FeeEstimatorService.EstimationResult, KukaiError>) -> Void)) {
		getOperationMetadata(forWalletAddress: walletAddress) { [weak self] (result) in
			switch result {
				case .success(let metadata):
					self?.feeEstimatorService.estimate(operations: operations, operationMetadata: metadata, constants: constants, walletAddress: walletAddress, base58EncodedPublicKey: base58EncodedPublicKey, isRemote: isRemote, completion: completion)
					
				case .failure(let error):
					Logger.kukaiCoreSwift.error("Unable to fetch metadata: \(error)")
					completion(Result.failure(error))
			}
		}
	}
	
	
	// MARK: - Send
	
	/**
	Send an array of `Operation`'s to the blockchain. Use `OperationFactory` to help create this array for common use cases.
	- parameter operations: An array of `Operation` subclasses to be sent to the network.
	- parameter withWallet: The `Wallet` instance that will sign the transactions.
	- parameter completion: A completion closure that will either return the opertionID of an injected operation, or an error.
	*/
	public func send(operations: [Operation], withWallet wallet: Wallet, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		getOperationMetadata(forWalletAddress: wallet.address) { [weak self] (result) in
			switch result {
				case .success(let metadata):
					let operationPayload = OperationFactory.operationPayload(fromMetadata: metadata, andOperations: operations, walletAddress: wallet.address, base58EncodedPublicKey: wallet.publicKeyBase58encoded())
					self?.send(operationPayload: operationPayload, operationMetadata: metadata, withWallet: wallet, completion: completion)
				
				case .failure(let error):
					Logger.kukaiCoreSwift.error("Unable to fetch metadata: \(error)")
					completion(Result.failure(error))
			}
		}
	}
	
	/**
	Send an already contrsutructed `OperationPayload` with the necessary `OperationMetadata` without having to fetch metadata again.
	- parameter operationPayload: An `OperationPayload` that has already been constructed (e.g. from the estimation call).
	- parameter operationMetadata: An `OperationMetaData` object containing all the info about the network that the call needs for forge -> inject.
	- parameter withWallet: The `Wallet` instance that will sign the transactions.
	- parameter completion: A completion closure that will either return the opertionID of an injected operation, or an error.
	*/
	public func send(operationPayload: OperationPayload, operationMetadata: OperationMetadata, withWallet wallet: Wallet, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		switch self.config.forgingType {
			case .local:
				self.operationService.localForgeSignPreapplyInject(operationMetadata: operationMetadata, operationPayload: operationPayload, wallet: wallet, completion: completion)
				
			case .remote:
				self.operationService.remoteForgeParseSignPreapplyInject(operationMetadata: operationMetadata, operationPayload: operationPayload, wallet: wallet, completion: completion)
		}
	}
	
	
	
	// MARK: - Blockchain Operations
	
	/**
	Get all the metadata necessary from the network to perform operations.
	- parameter forWallet: The `Wallet` object that will be sending the operations.
	- parameter completion: A callback that will be executed when the network requests finish.
	*/
	public func getOperationMetadata(forWalletAddress: String, completion: @escaping ((Result<OperationMetadata, KukaiError>) -> Void)) {
		let dispatchGroup = DispatchGroup()
		let config = self.config
		
		var counter = 0
		var managerKey: String? = nil
		var blockchainHead = BlockchainHead(protocol: "", chainID: "", hash: "")
		var error: KukaiError? = nil
		
		
		// Get manager key
		dispatchGroup.enter()
		metadataQueue.async { [weak self] in
			self?.networkService.send(rpc: RPC.managerKey(forAddress: forWalletAddress), withNodeURLs: config.nodeURLs) { (result) in
				switch result {
					case .success(let value):
						managerKey = value
					
					case .failure(let err):
						error = err
				}
				
				dispatchGroup.leave()
			}
		}
		
		
		// Get counter
		dispatchGroup.enter()
		metadataQueue.async { [weak self] in
			self?.networkService.send(rpc: RPC.counter(forAddress: forWalletAddress), withNodeURLs: config.nodeURLs) { (result) in
				switch result {
					case .success(let value):
						counter = Int(value) ?? 0
					
					case .failure(let err):
						error = err
				}
				
				dispatchGroup.leave()
			}
		}
		
		
		// Get blockchain head
		dispatchGroup.enter()
		metadataQueue.async { [weak self] in
			self?.networkService.send(rpc: RPC.blockchainHeadMinus3(), withNodeURLs: config.nodeURLs) { (result) in
				switch result {
					case .success(let value):
						blockchainHead = value
					
					case .failure(let err):
						error = err
				}
				
				dispatchGroup.leave()
			}
		}
		
		// When all requests finished, return on main thread
		dispatchGroup.notify(queue: .main) {
			if let err = error {
				completion(Result.failure(err))
				
			} else {
				completion(Result.success(OperationMetadata(managerKey: managerKey, counter: counter, blockchainHead: blockchainHead)))
			}
		}
	}
	
	/**
	Get the Michelson storage of a given contract from the blockchain.
	- parameter contractAddress: The address of the contract to query.
	- parameter completion: A callback with a `Result` object, with either a `[String: Any]` or an `Error`
	*/
	public func getContractStorage(contractAddress: String, completion: @escaping ((Result<[String: Any], KukaiError>) -> Void)) {
		self.networkService.send(rpc: RPC.contractStorage(contractAddress: contractAddress), withNodeURLs: config.nodeURLs) { result in
			switch result {
				case .success(let d):
					if let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
						completion(Result.success(json))
					} else {
						completion(Result.failure(KukaiError.internalApplicationError(error: TezosNodeClientError.michelsonParsing)))
					}
				
				case .failure(let err):
					completion(Result.failure(err))
			}
		}
	}
	
	/**
	 Get the Michelson big map contents, from a given id
	 - parameter id: The big map id.
	 - parameter completion: A callback with a `Result` object, with either a `[String: Any]` or an `Error`
	*/
	public func getBigMap(id: String, completion: @escaping ((Result<[String: Any], KukaiError>) -> Void)) {
		self.networkService.send(rpc: RPC.bigMap(id: id), withNodeURLs: config.nodeURLs) { result in
			switch result {
				case .success(let d):
					if let json = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
						completion(Result.success(json))
					} else {
						completion(Result.failure(KukaiError.internalApplicationError(error: TezosNodeClientError.michelsonParsing)))
					}
					
				case .failure(let err):
					completion(Result.failure(err))
			}
		}
	}
	
	/**
	 Get the address of the CPMM contract and the 2 tokens (tzBTC and SIRS) that it manages
	 - parameter completion: A callback with a `Result` object, with either a `(cpmm: String, tzbtc: String, sirs: String)` or an `Error`
	*/
	public func getLiquidityBakingAddresses(completion: @escaping ((Result<(cpmm: String, tzbtc: String, sirs: String), KukaiError>) -> Void)) {
		let configUrls = config.nodeURLs
		self.networkService.send(rpc: RPC.liquidtyBakingContractAddress(), withNodeURLs: configUrls) { [weak self] result in
			guard let res = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			self?.networkService.send(rpc: RPC.contractStorage(contractAddress: res), withNodeURLs: configUrls, completion: { innerResult in
				guard let innerRes = try? innerResult.get(),
					let json = try? JSONSerialization.jsonObject(with: innerRes) as? [String: Any],
					let argsArray = json["args"] as? [Any],
					argsArray.count > 4,
					let address1Obj = argsArray[3] as? [String: String],
					let address1 = address1Obj["string"],
					let address2Obj = argsArray[4] as? [String: String],
					let address2 = address2Obj["string"]
				else {
					completion(Result.failure(innerResult.getFailure()))
					return
				}
				
				let tuple = (cpmm: res, tzbtc: address1, sirs: address2)
				completion(Result.success(tuple))
			})
		}
	}
	
	/**
	Query the server for the `NetworkVersion` and `NetworkConstants`, and store the responses in the tezosNodeClient properties `networkVersion` and `networkConstants`,
	so they can be referred too by the application without having to constantly query t he server.
	- parameter completion: A callback with a `Bool` indicating success and an optional `Error`
	*/
	public func getNetworkInformation(completion: @escaping ((Bool, KukaiError?) -> Void)) {
		let dispatchGroup = DispatchGroup()
		var error: KukaiError? = nil
		
		dispatchGroup.enter()
		dexterQueriesQueue.async { [weak self] in
			guard let config = self?.config else {
				Logger.kukaiCoreSwift.info("Invalid nodeURLs")
				completion(false, KukaiError.internalApplicationError(error: NetworkService.NetworkError.invalidURL))
				return
			}
			
			self?.networkService.send(rpc: RPC.networkVersion(), withNodeURLs: config.nodeURLs) { (result) in
				switch result {
					case .success(let value):
						self?.networkVersion = value
						
					case .failure(let err):
						error = err
				}
				
				dispatchGroup.leave()
			}
		}
		
		dispatchGroup.enter()
		dexterQueriesQueue.async { [weak self] in
			guard let config = self?.config else {
				Logger.kukaiCoreSwift.info("Invalid nodeURLs")
				completion(false, KukaiError.internalApplicationError(error: NetworkService.NetworkError.invalidURL))
				return
			}
			
			self?.networkService.send(rpc: RPC.networkConstants(), withNodeURLs: config.nodeURLs) { (result) in
				switch result {
					case .success(let value):
						self?.networkConstants = value
						
					case .failure(let err):
						error = err
				}
				
				dispatchGroup.leave()
			}
		}
		
		
		dispatchGroup.notify(queue: .main) {
			completion(error == nil, error)
		}
	}
}
