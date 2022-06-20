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
		self.networkService.send(rpc: RPC.xtzBalance(forAddress: address), withBaseURL: config.primaryNodeURL) { (result) in
			switch result {
				case .success(let rpcAmount):
					let xtz = XTZAmount(fromRpcAmount: rpcAmount) ?? XTZAmount.zero()
					completion(Result.success(xtz))
				
				case .failure(let rpcError):
					completion(Result.failure(rpcError))
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
		self.networkService.send(rpc: RPC.getDelegate(forAddress: address), withBaseURL: config.primaryNodeURL, completion: completion)
	}
	
	
	
	// MARK: Estimate
	
	/**
	Take an array of operations and estimate the gas, storage, baker fee and burn fees required to inject it onto the network
	If the supplied operations contain suggested fees (e.g. from a dApp) this function will estimate the fee and pick which ever is higher
	- parameter operations: An array of `Operation`'s to be injected.
	- parameter wallet: The `Wallet` that will sign the operation
	- parameter completion: A callback containing an updated array of `Operation`'s with fees set correctly, or an error.
	*/
	public func estimate(operations: [Operation], withWallet wallet: Wallet, completion: @escaping ((Result<[Operation], KukaiError>) -> Void)) {
		
		if let constants = self.networkConstants {
			self.estimate(operations: operations, constants: constants, withWallet: wallet, completion: completion)
			
		} else {
			self.getNetworkInformation { [weak self] (success, error) in
				guard let constants = self?.networkConstants else {
					completion(Result.failure(error ?? KukaiError.unknown()))
					return
				}
				
				self?.estimate(operations: operations, constants: constants, withWallet: wallet, completion: completion)
			}
		}
	}
	
	/// Internal function to break up code and make it easier to read. Public function checks to see if the network constants are present, if not will query them and then estimate
	private func estimate(operations: [Operation], constants: NetworkConstants, withWallet wallet: Wallet, completion: @escaping ((Result<[Operation], KukaiError>) -> Void)) {
		getOperationMetadata(forWallet: wallet) { [weak self] (result) in
			switch result {
				case .success(let metadata):
					self?.feeEstimatorService.estimate(operations: operations, operationMetadata: metadata, constants: constants, withWallet: wallet, completion: completion)
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Unable to fetch metadata: %@", "\(error)")
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
		
		getOperationMetadata(forWallet: wallet) { [weak self] (result) in
			
			switch result {
				case .success(let metadata):
					let operationPayload = OperationFactory.operationPayload(fromMetadata: metadata, andOperations: operations, withWallet: wallet)
					self?.send(operationPayload: operationPayload, operationMetadata: metadata, withWallet: wallet, completion: completion)
				
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Unable to fetch metadata: %@", "\(error)")
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
	public func getOperationMetadata(forWallet wallet: Wallet, completion: @escaping ((Result<OperationMetadata, KukaiError>) -> Void)) {
		let dispatchGroup = DispatchGroup()
		
		var counter = 0
		var managerKey: String? = nil
		var blockchainHead = BlockchainHead(protocol: "", chainID: "", hash: "")
		var error: KukaiError? = nil
		
		
		// Get manager key
		dispatchGroup.enter()
		metadataQueue.async { [weak self] in
			if let url = self?.config.primaryNodeURL {
				self?.networkService.send(rpc: RPC.managerKey(forAddress: wallet.address), withBaseURL: url) { (result) in
					switch result {
						case .success(let value):
							managerKey = value
						
						case .failure(let err):
							error = err
					}
					
					dispatchGroup.leave()
				}
			} else {
				error = KukaiError.internalApplicationError(error: NetworkService.NetworkError.invalidURL)
				dispatchGroup.leave()
			}
		}
		
		
		// Get counter
		dispatchGroup.enter()
		metadataQueue.async { [weak self] in
			if let url = self?.config.primaryNodeURL {
				self?.networkService.send(rpc: RPC.counter(forAddress: wallet.address), withBaseURL: url) { (result) in
					switch result {
						case .success(let value):
							counter = Int(value) ?? 0
						
						case .failure(let err):
							error = err
					}
					
					dispatchGroup.leave()
				}
			} else {
				error = KukaiError.internalApplicationError(error: NetworkService.NetworkError.invalidURL)
				dispatchGroup.leave()
			}
		}
		
		
		// Get blockchain head
		dispatchGroup.enter()
		metadataQueue.async { [weak self] in
			if let url = self?.config.primaryNodeURL {
				self?.networkService.send(rpc: RPC.blockchainHead(), withBaseURL: url) { (result) in
					switch result {
						case .success(let value):
							blockchainHead = value
						
						case .failure(let err):
							error = err
					}
					
					dispatchGroup.leave()
				}
			} else {
				error = KukaiError.internalApplicationError(error: NetworkService.NetworkError.invalidURL)
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
	- parameter completion: A callback with a `Result` object, with either a `MichelsonPair` or an `Error`
	*/
	public func getContractStorage(contractAddress: String, completion: @escaping ((Result<MichelsonPair, KukaiError>) -> Void)) {
		self.networkService.send(rpc: RPC.contractStorage(contractAddress: contractAddress), withBaseURL: config.primaryNodeURL, completion: completion)
	}
	
	/**
	 Get the Michelson big map contents, from a given id
	 - parameter id: The big map id.
	 - parameter completion: A callback with a `Result` object, with either a `MichelsonPair` or an `Error`
	*/
	public func getBigMap(id: String, completion: @escaping ((Result<MichelsonPair, KukaiError>) -> Void)) {
		self.networkService.send(rpc: RPC.bigMap(id: id), withBaseURL: config.primaryNodeURL, completion: completion)
	}
	
	/**
	Get the Liquidity Baking pool data for each tuple passed in.
	- parameter forContracts: An array of tuples `(address: String, decimalPlaces: Int)` denoting the address of the contract, and the number of decimalPlaces it has
	- parameter completion: An empty callback to alert that the balances, if avialable, have bene fetched
	*/
	public func getLiquidityBakingPoolData(forContracts contracts: [(address: String, decimalPlaces: Int)], completion: @escaping ((Result<[String: LiquidityBakingData], KukaiError>) -> Void)) {
		let dispatchGroup = DispatchGroup()
		var errors: [KukaiError] = []
		
		var poolDict: [String: LiquidityBakingData] = [:]
		
		for contract in contracts {
			
			dispatchGroup.enter()
			os_log(.debug, log: .kukaiCoreSwift, "Fetching pool data for %@", contract.address)
			
			getLiquidityBakingData(forContract: contract) { result in
				switch result {
					case .success(let poolData):
						poolDict[contract.address] = poolData
						
					case .failure(let error):
						errors.append(error)
				}
				
				dispatchGroup.leave()
			}
		}
		
		dispatchGroup.notify(queue: .main) {
			if errors.count > 0 {
				completion(Result.failure(errors[0]))
			} else {
				completion(Result.success(poolDict))
			}
		}
	}
	
	/**
	Get the tokenPool available for the given Liquidity Baking token/xtz pair
	- parameter forContract: Tuple of `(address: String, decimalPlaces: Int)` denoting the address of the contract, and the number of decimalPlaces it has
	- parameter completion: A callback with a `Result` object, with either a `TokenAmount` or an `Error`
	*/
	public func getLiquidityBakingData(forContract contract: (address: String, decimalPlaces: Int), completion: @escaping ((Result<LiquidityBakingData, KukaiError>) -> Void)) {
		self.getContractStorage(contractAddress: contract.address) { (result) in
			switch result {
				case .success(let michelsonPair):
					
					if michelsonPair.args.count > 2,
					   let tPool = michelsonPair.argIndexAsValue(0)?.value,
					   let xPool = michelsonPair.argIndexAsValue(1)?.value,
					   let lqtTotal = michelsonPair.argIndexAsValue(2)?.value,
					   let tAddress = michelsonPair.argIndexAsValue(3)?.value,
					   let lAddress = michelsonPair.argIndexAsValue(4)?.value {
						
						let xtzPool = XTZAmount(fromRpcAmount: xPool) ?? XTZAmount.zero()
						let tokenPool = TokenAmount(fromRpcAmount: tPool, decimalPlaces: contract.decimalPlaces) ?? TokenAmount.zero()
						let totalLiquidity = TokenAmount(fromRpcAmount: lqtTotal, decimalPlaces: 0) ?? TokenAmount.zero()
						let tokenAddress = tAddress
						let liquidityAddress = lAddress
						
						completion(Result.success(LiquidityBakingData(xtzPool: xtzPool, tokenPool: tokenPool, totalLiquidity: totalLiquidity, tokenContractAddress: tokenAddress, liquidityTokenContractAddress: liquidityAddress)))
						
					} else if let tPool = michelsonPair.argIndexAsValue(0)?.value,
							  let xPool = michelsonPair.argIndexAsPair(1)?.argIndexAsValue(0)?.value,
							  let lqtTotal = michelsonPair.argIndexAsPair(1)?.argIndexAsPair(1)?.argIndexAsValue(0)?.value,
							  let tAddress = michelsonPair.argIndexAsPair(1)?.argIndexAsPair(1)?.argIndexAsPair(1)?.argIndexAsValue(0)?.value,
							  let lAddress = michelsonPair.argIndexAsPair(1)?.argIndexAsPair(1)?.argIndexAsPair(1)?.argIndexAsPair(1)?.argIndexAsValue(0)?.value {
						
						let xtzPool = XTZAmount(fromRpcAmount: xPool) ?? XTZAmount.zero()
						let tokenPool = TokenAmount(fromRpcAmount: tPool, decimalPlaces: contract.decimalPlaces) ?? TokenAmount.zero()
						let totalLiquidity = TokenAmount(fromRpcAmount: lqtTotal, decimalPlaces: 0) ?? TokenAmount.zero()
						let tokenAddress = tAddress
						let liquidityAddress = lAddress
						
						completion(Result.success(LiquidityBakingData(xtzPool: xtzPool, tokenPool: tokenPool, totalLiquidity: totalLiquidity, tokenContractAddress: tokenAddress, liquidityTokenContractAddress: liquidityAddress)))
						
					} else {
						completion(Result.failure(KukaiError.internalApplicationError(error: TezosNodeClientError.michelsonParsing)))
					}
					
				case .failure(let error):
					completion(Result.failure(error))
			}
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
			guard let url = self?.config.primaryNodeURL else {
				os_log(.debug, log: .kukaiCoreSwift, "Invalid server url: %@", self?.config.primaryNodeURL.absoluteString ?? "nil")
				completion(false, KukaiError.internalApplicationError(error: NetworkService.NetworkError.invalidURL))
				return
			}
			
			self?.networkService.send(rpc: RPC.networkVersion(), withBaseURL: url) { (result) in
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
			guard let url = self?.config.primaryNodeURL else {
				os_log(.debug, log: .kukaiCoreSwift, "Invalid server url: %@", self?.config.primaryNodeURL.absoluteString ?? "nil")
				completion(false, KukaiError.internalApplicationError(error: NetworkService.NetworkError.invalidURL))
				return
			}
			
			self?.networkService.send(rpc: RPC.networkConstants(), withBaseURL: url) { (result) in
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
