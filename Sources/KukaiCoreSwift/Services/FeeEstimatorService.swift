//
//  FeeEstimatorService.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 18/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import os.log

/// An object allowing developers to automatically estimate the necessary fee per Operation to ensure it will be accpeted by a Baker.
/// This avoids the need to ask users to enter a fee, which is not a very user friendly approach as most users wouldn't know what is required.
public class FeeEstimatorService {
	
	/// The real signature is not needed for estimation, use the default "Zero Signature" instead
	public static let defaultSignature = [UInt8](repeating: 0, count: 64)
	public static let defaultSignatureHex = String(repeating: "0", count: 128)
	
	
	
	// MARK: - Types
	
	/// Constants needed to compute a fee
	public struct FeeConstants {
		static let nanoTezPerMutez: Int = 1000
		static let minimalFee: NanoTez = 100_000
		static let feePerGasUnit: NanoTez = 100
		static let feePerStorageByte: NanoTez = 1000
		static let baseFee = XTZAmount(fromNormalisedAmount: 0.0001)
	}
	
	/// Estimations can be slightly off, use safety margins to ensure they are high enough
	let gasSafetyMargin = 500 // bumped up from 100, as now it seems emptying an account requires 400 more gas
	
	/// Various possible errors that can occur during an Estimation
	public enum FeeEstimatorServiceError: Error {
		case tezosNodeClientNotPresent
		case unableToSetupRunOperation
		case invalidNumberOfFeesReturned
		case failedToCopyOperations
		case estimationRemoteError(errors: [OperationResponseInternalResultError]?)
	}
	
	
	
	// MARK: - Public Properties
	
	/// The configuration object containing all the necessary settings to connect and communicate with the Tezos node
	public let config: TezosNodeClientConfig
	
	/// The `OperationService` object that will perform forging, parsing, signing, preapply and injections of operations
	public let operationService: OperationService
	
	/// The `NetworkService` that will handle the remote communication.
	public let networkService: NetworkService
	
	
	/**
	Create a FeeEstimatorService that will allow developers to automatically create fees on the users behalf
	- parameter operationService: The `OperationService` used to perform the forging.
	- parameter networkService: The `NetworkService` that will handle the remote communication.
	*/
	public init(config: TezosNodeClientConfig = TezosNodeClientConfig(withDefaultsForNetworkType: .mainnet), operationService: OperationService, networkService: NetworkService) {
		self.config = config
		self.operationService = operationService
		self.networkService = networkService
	}
	
	
	/**
	Pass in an array of `Operation` subclasses (use `OperationFacotry` to create) to have the library estimate the cost of sending the transaction. Function will use local or remote forging based off config passed in.
	If the supplied operations contain suggested fees (e.g. from a dApp) this function will estimate the fee and pick which ever is higher
	- parameter operations: An array of `Operation` subclasses to be estimated.
	- parameter operationMetadata: An `OperationMetadata` object containing necessary info about the current blockchain state.
	- parameter networkConstants: A `NetworkConstants` used to provide information about the current network requirements.
	- parameter withWallet: The `Wallet` object used for signing the transaction.
	- parameter completion: A callback containing the same operations passed in, modified to include fees.
	*/
	public func estimate(operations: [Operation], operationMetadata: OperationMetadata, constants: NetworkConstants, withWallet wallet: Wallet, completion: @escaping ((Result<[Operation], KukaiError>) -> Void)) {
		
		// Make a copy of the operations before they are modified
		guard let opJson = try? JSONEncoder().encode(operations), let opsCopy = try? JSONDecoder().decode([Operation].self, from: opJson) else {
			completion(Result.failure(KukaiError.internalApplicationError(error: FeeEstimatorServiceError.failedToCopyOperations)))
			return
		}
		
		
		let operationPayload = OperationFactory.operationPayload(fromMetadata: operationMetadata, andOperations: operations, withWallet: wallet)
		
		// Before estimating, set the maximum gas and storage to ensure the operation suceeds (excluding any errors such as invalid address, insufficnet funds etc)
		let maxGasAndStorage = OperationFees(transactionFee: XTZAmount.zero(), gasLimit: constants.maxGasPerOperation(), storageLimit: constants.maxStoragePerOperation())
		operationPayload.contents.forEach { $0.operationFees = maxGasAndStorage }
		
		switch self.config.forgingType {
			case .local:
				TaquitoService.shared.forge(operationPayload: operationPayload) { [weak self] forgedResult in
					self?.handleForge(forgeResult: forgedResult, operationPayload: operationPayload, operationMetadata: operationMetadata, constants: constants, wallet: wallet, originalOps: opsCopy, completion: completion)
				}
				
			case .remote:
				operationService.remoteForge(operationMetadata: operationMetadata, operationPayload: operationPayload, wallet: wallet) { [weak self] forgedResult in
					self?.handleForge(forgeResult: forgedResult, operationPayload: operationPayload, operationMetadata: operationMetadata, constants: constants, wallet: wallet, originalOps: opsCopy, completion: completion)
				}
		}
	}
	
	/// Shared function to run whether forged locally or remote
	private func handleForge(forgeResult: Result<String, KukaiError>,
							 operationPayload: OperationPayload,
							 operationMetadata: OperationMetadata,
							 constants: NetworkConstants,
							 wallet: Wallet,
							 originalOps: [Operation],
							 completion: @escaping ((Result<[Operation], KukaiError>) -> Void))
	{
		switch forgeResult {
			case .success(let hexString):
				var mutablePayload = operationPayload
				mutablePayload.addSignature(FeeEstimatorService.defaultSignature, signingCurve: wallet.privateKeyCurve())
				let runOperationPayload = RunOperationPayload(chainID: operationMetadata.chainID, operation: mutablePayload)
				
				self.estimate(runOperationPayload: runOperationPayload, operations: mutablePayload.contents, constants: constants, forgedHex: hexString, originalOps: originalOps, completion: completion)
			
			case .failure(let error):
				completion(Result.failure(error))
				return
		}
	}

	/// Breaking out part of the estimation process to keep code cleaner
	private func estimate(runOperationPayload: RunOperationPayload, operations: [Operation], constants: NetworkConstants, forgedHex: String, originalOps: [Operation], completion: @escaping ((Result<[Operation], KukaiError>) -> Void)) {
		guard let rpc = RPC.runOperation(runOperationPayload: runOperationPayload) else {
			os_log(.error, log: .kukaiCoreSwift, "Unable to create runOperation RPC, cancelling event")
			completion(Result.failure(KukaiError.internalApplicationError(error: FeeEstimatorServiceError.unableToSetupRunOperation)))
			return
		}
		
		self.networkService.send(rpc: rpc, withBaseURL: config.primaryNodeURL) { [weak self] (result) in
			var operationResponseToProcess: OperationResponse? = nil
			var errorToProcess: KukaiError? = nil
			
			switch result {
				case .success(let operationResponse):
					operationResponseToProcess = operationResponse
					
				case .failure(let error):
					
					// There are some situations where a estimation (simulation) will ignore fees that need to be paid and return a success, regardless of if the operation is possible with that send amount + fee
					// There are types of fees where this doesn't work. For example burn fees, which are charged by the network itself.
					// So if, for example, a user is trying to send all of their XTZ to an unrevealed destination, and we are trying to figure out the cost, the estimation will fail with an insufficnet funds error.
					// The error will return with the correct amount of gas and storage, but the error forces it into here.
					// So in an attempt to prevent this affecting users, we are trying to solve this hueristically, by saying if we get an insufficent_funds error, and we are trying to send a non-zero amount of XTZ,
					// ignore the error and attempt to parse. Returning the result to the client, where they must examine the fee and decide if an amount needs to be deducted from the sending amount
					if error.rpcErrorString == "contract.balance_too_low",
					   operations.count <= 2,
					   operations.last is OperationTransaction,
					   (operations.last as? OperationTransaction)?.amount != "0",
					   let jsonObjectWithError = try? JSONDecoder().decode(OperationResponse.self, from: error.responseJSON?.data(using: .utf8) ?? Data())
					{
						operationResponseToProcess = jsonObjectWithError
					} else {
						errorToProcess = error
					}
			}
			
			guard let opToProcess = operationResponseToProcess else {
				os_log(.error, log: .kukaiCoreSwift, "Unable to estimate: %@", "\(errorToProcess?.description ?? "-")")
				completion(Result.failure(errorToProcess ?? KukaiError.unknown()))
				return
			}
			
			// Extract gas, storage, burn, allocation etc, fees from the response body
			guard let fees = self?.extractFees(fromOperationResponse: opToProcess, forgedHash: forgedHex, withConstants: constants) else {
				completion(Result.failure(KukaiError.internalApplicationError(error: FeeEstimatorServiceError.invalidNumberOfFeesReturned)))
				return
			}
			
			// Make sure we have created a `OperationFees` for each operation
			if fees.count != operations.count {
				completion(Result.failure(KukaiError.internalApplicationError(error: FeeEstimatorServiceError.invalidNumberOfFeesReturned)))
				return
			}
			
			// Operations can come in with suggested fees (e.g. when using a dApp through something like Beacon).
			// We always do an estimation and pick which ever is higher, the supplied suggested fees (which should always be worst case, but can be flawed), or the result of the estimation
			var lastOpFee: OperationFees = OperationFees(transactionFee: .zero(), gasLimit: 0, storageLimit: 0)
			var operationFeesToUse: [OperationFees] = []
			if originalOps.map({ $0.operationFees.gasLimit }).reduce(0, +) > fees.map({ $0.gasLimit }).reduce(0, +) {
				lastOpFee = self?.calcFeeFromSuggestedOperations(operations: originalOps, constants: constants, forgedHex: forgedHex) ?? OperationFees.zero()
				operationFeesToUse = originalOps.map({ $0.operationFees })
				
			} else {
				lastOpFee = fees.last ?? OperationFees.zero()
				operationFeesToUse = fees
			}
			
			
			// Set gas, storage and network fees on each operation, but only add transaction fee to last operation.
			// The entire chain of operations can fail due to one in the middle failing. If that happens, only fees attached to operations that were processed, gets debited
			for (index, op) in operations.enumerated() {
				op.operationFees = operationFeesToUse[index]
				
				if index == operations.count-1 {
					op.operationFees.transactionFee = lastOpFee.transactionFee
					op.operationFees.networkFees = lastOpFee.networkFees
					
				} else {
					op.operationFees.transactionFee = .zero()
				}
			}
			
			completion(Result.success(operations))
		}
	}
	
	private func calcFeeFromSuggestedOperations(operations: [Operation], constants: NetworkConstants, forgedHex: String) -> OperationFees {
		let totalGas = operations.map({ $0.operationFees.gasLimit }).reduce(0, +)
		let totalStorage = operations.map({ $0.operationFees.storageLimit }).reduce(0, +)
		
		return calcTransactionFee(totalGas: totalGas, opCount: operations.count, totalStorage: totalStorage, forgedHash: forgedHex, constants: constants)
	}
	
	/**
	Create an array of `OperationFees` from an `OperationResponse`.
	- parameter fromOperationResponse: The `OperationResponse` resulting from an RPC call to `.../run_operation`.
	- parameter forgedHash: The forged hash string resulting from a call to `TezosNodeClient.forge(...)`
	- returns: An array of `OperationFees`
	*/
	public func extractFees(fromOperationResponse operationResponse: OperationResponse, forgedHash: String, withConstants constants: NetworkConstants) -> [OperationFees] {
		var opFees: [OperationFees] = []
		var totalGas = 0
		var totalStorage = 0
		var totalAllocationFee = XTZAmount.zero()
		
		for (index, content) in operationResponse.contents.enumerated() {
			var opGas = 0
			var opStorage = 0
			var opAllocationStorage = 0 // Needs to be included in `storage_limit`, but ignored as a burn fee because it is an "allocation fee"
			var opAllocationFee = XTZAmount.zero()
			
			let results = extractAndParseAttributes(fromResult: content.metadata.operationResult, withConstants: constants)
			opGas = results.consumedGas + gasSafetyMargin
			opStorage = results.storageBytesUsed
			opAllocationFee = results.allocationFee
			
			totalGas += results.consumedGas + gasSafetyMargin
			totalStorage += results.storageBytesUsed
			totalAllocationFee += results.allocationFee
			
			// If we are allocating an address, we need to include it as storage on our operation
			if results.allocationFee > XTZAmount.zero() {
				opAllocationStorage = constants.bytesForReveal()
			}
			
			if let innerOperationResults = content.metadata.internalOperationResults {
				for innerResult in innerOperationResults {
					let results = extractAndParseAttributes(fromResult: innerResult.result, withConstants: constants)
					opGas += results.consumedGas + gasSafetyMargin
					opStorage += results.storageBytesUsed
					opAllocationFee += results.allocationFee
					
					totalGas += results.consumedGas + gasSafetyMargin
					totalStorage += results.storageBytesUsed
					totalAllocationFee += results.allocationFee
					
					// If we are allocating an address, we need to include it as storage on our operation
					if results.allocationFee > XTZAmount.zero() {
						opAllocationStorage += constants.bytesForReveal()
					}
				}
			}
			
			// If last
			if index == operationResponse.contents.count-1 {
				opFees.append( createLimitsAndTotalFeeObj(totalGas: totalGas, opGas: opGas, opCount: operationResponse.contents.count, totalStorage: totalStorage, opStorage: opStorage, forgedHash: forgedHash, constants: constants, allocationStorage: opAllocationStorage, totalAllocationFee: totalAllocationFee) )
				
			} else {
				opFees.append( createLimitsOnlyFeeObj(gas: opGas, storage: opStorage, allocationStorage: opAllocationStorage) )
			}
		}
		
		return opFees
	}
	
	/// Create an instance of `OperationFees` for a non-last operation, with no fee, but accurate gas + storage
	private func createLimitsOnlyFeeObj(gas: Int, storage: Int, allocationStorage: Int) -> OperationFees {
		return OperationFees(transactionFee: .zero(), gasLimit: gas, storageLimit: storage + allocationStorage)
	}
	
	/// Create an instance of `OperationFees` in order to calculate a transaction fee. Used to calculate the overall transaction fee
	private func calcTransactionFee(totalGas: Int, opCount: Int, totalStorage: Int, forgedHash: String, constants: NetworkConstants) -> OperationFees {
		let gasFee = feeForGas(totalGas)
		let storageFee = feeForStorage(forgedHash, numberOfOperations: opCount)
		let burnFee = feeForBurn(totalStorage, withConstants: constants)
		let networkFees = [[OperationFees.NetworkFeeType.burnFee: burnFee, OperationFees.NetworkFeeType.allocationFee: .zero()]]
		
		return OperationFees(transactionFee: FeeConstants.baseFee + gasFee + storageFee, networkFees: networkFees, gasLimit: 0, storageLimit: 0)
	}
	
	/// Create an instance of `OperationFees` for a last operation, with its corresponding gas + storage, but fees for the entire list of operations
	private func createLimitsAndTotalFeeObj(totalGas: Int, opGas: Int, opCount: Int, totalStorage: Int, opStorage: Int, forgedHash: String, constants: NetworkConstants, allocationStorage: Int, totalAllocationFee: XTZAmount) -> OperationFees {
		let gasFee = feeForGas(totalGas)
		let storageFee = feeForStorage(forgedHash, numberOfOperations: opCount)
		let burnFee = feeForBurn(totalStorage, withConstants: constants)
		let networkFees = [[OperationFees.NetworkFeeType.burnFee: burnFee, OperationFees.NetworkFeeType.allocationFee: totalAllocationFee]]
		
		return OperationFees(transactionFee: FeeConstants.baseFee + gasFee + storageFee, networkFees: networkFees, gasLimit: opGas, storageLimit: opStorage + allocationStorage)
	}
	
	/// Private helper to process `OperationResponseResult` block. Complicated operations will contain many of these.
	private func extractAndParseAttributes(fromResult result: OperationResponseResult?, withConstants constants: NetworkConstants) -> (consumedGas: Int, storageBytesUsed: Int, allocationFee: XTZAmount) {
		guard let result = result else {
			return (consumedGas: 0, storageBytesUsed: 0, allocationFee: XTZAmount.zero())
		}
		
		let consumedGas = Int(result.consumedGas ?? "0") ?? 0
		let paidStorageSizeDiff = Int(result.paidStorageSizeDiff ?? "0") ?? 0
		var allocationFee = XTZAmount.zero()
		
		if let allocated = result.allocatedDestinationContract, allocated {
			allocationFee = constants.xtzForReveal()
		}
		
		return (consumedGas: consumedGas, storageBytesUsed: paidStorageSizeDiff, allocationFee: allocationFee)
	}
	
	/// Calculate the fee to add for the given amount of gas
	private func feeForGas(_ gas: Int) -> XTZAmount {
		let nanoTez = gas * FeeConstants.feePerGasUnit
		return nanoTeztoXTZ(nanoTez)
	}
	
	/// Calculate the fee to add based on the size of the forged string
	private func feeForStorage(_ forgedHexString: String, numberOfOperations: Int) -> XTZAmount {
		let forgedHexWithSignature = (forgedHexString + FeeEstimatorService.defaultSignatureHex)
		let nanoTez = ((forgedHexWithSignature.count/2) + (10 * numberOfOperations)) * FeeConstants.feePerStorageByte // Multiply bytes (2 characters per byte) by the fee perSotrageByteConstant. Add 10 bytes per op to account for any variations
		return nanoTeztoXTZ(nanoTez)
	}
	
	/// Calculate the fee to add based on how many bytes of storage where needed
	private func feeForBurn(_ burn: Int, withConstants contants: NetworkConstants) -> XTZAmount {
		return contants.xtzPerByte() * burn
	}
	
	/// Most calcualtions are documented in NanoTez, which is not accpeted by the network RPC calls. Needs to be converted to Mutez / XTZ
	private func nanoTeztoXTZ(_ nanoTez: NanoTez) -> XTZAmount {
		let mutez = nanoTez % FeeConstants.nanoTezPerMutez == 0 ?
			nanoTez / FeeConstants.nanoTezPerMutez :
			(nanoTez / FeeConstants.nanoTezPerMutez) + 1
		
		return XTZAmount(fromRpcAmount: Decimal(mutez)) ?? XTZAmount.zero()
	}
}
