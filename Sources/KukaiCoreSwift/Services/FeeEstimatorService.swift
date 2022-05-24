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
	- parameter operations: An array of `Operation` subclasses to be estimated.
	- parameter operationMetadata: An `OperationMetadata` object containing necessary info about the current blockchain state.
	- parameter networkConstants: A `NetworkConstants` used to provide information about the current network requirements.
	- parameter withWallet: The `Wallet` object used for signing the transaction.
	- parameter completion: A callback containing the same operations passed in, modified to include fees.
	*/
	public func estimate(operations: [Operation], operationMetadata: OperationMetadata, constants: NetworkConstants, withWallet wallet: Wallet, receivedSuggestedGas: Bool, completion: @escaping ((Result<[Operation], ErrorResponse>) -> Void)) {
		
		if !receivedSuggestedGas {
			// Before estimating, set the maximum gas and storage to ensure the operation suceeds (excluding any errors such as invalid address, insufficnet funds etc)
			let maxGasAndStorage = OperationFees(transactionFee: XTZAmount.zero(), gasLimit: constants.maxGasPerOperation(), storageLimit: constants.maxStoragePerOperation())
			operations.forEach { $0.operationFees = maxGasAndStorage }
		}
		
		let operationPayload = OperationFactory.operationPayload(fromMetadata: operationMetadata, andOperations: operations, withWallet: wallet)
		
		switch self.config.forgingType {
			case .local:
				TaquitoService.shared.forge(operationPayload: operationPayload) { [weak self] forgedResult in
					self?.handleForge(forgeResult: forgedResult, operationPayload: operationPayload, operationMetadata: operationMetadata, constants: constants, wallet: wallet, receivedSuggestedGas: receivedSuggestedGas, completion: completion)
				}
				
			case .remote:
				operationService.remoteForge(operationMetadata: operationMetadata, operationPayload: operationPayload, wallet: wallet) { [weak self] forgedResult in
					self?.handleForge(forgeResult: forgedResult, operationPayload: operationPayload, operationMetadata: operationMetadata, constants: constants, wallet: wallet, receivedSuggestedGas: receivedSuggestedGas, completion: completion)
				}
		}
	}
	
	/// Shared function to run whether forged locally or remote
	private func handleForge(forgeResult: Result<String, ErrorResponse>,
							 operationPayload: OperationPayload,
							 operationMetadata: OperationMetadata,
							 constants: NetworkConstants,
							 wallet: Wallet,
							 receivedSuggestedGas: Bool,
							 completion: @escaping ((Result<[Operation], ErrorResponse>) -> Void))
	{
		switch forgeResult {
			case .success(let hexString):
				
				if receivedSuggestedGas {
					self.estimateFeesOnly(operations: operationPayload.contents, constants: constants, forgedHex: hexString, completion: completion)
					
				} else {
					// Add signature to operation payload and perform the /run_operation request
					var mutablePayload = operationPayload
					mutablePayload.addSignature(FeeEstimatorService.defaultSignature, signingCurve: wallet.privateKeyCurve())
					let runOperationPayload = RunOperationPayload(chainID: operationMetadata.chainID, operation: mutablePayload)
					
					self.estimate(runOperationPayload: runOperationPayload, operations: mutablePayload.contents, constants: constants, forgedHex: hexString, completion: completion)
				}
			
			case .failure(let error):
				completion(Result.failure(error))
				return
		}
	}

	/// Breaking out part of the estimation process to keep code cleaner
	private func estimate(runOperationPayload: RunOperationPayload, operations: [Operation], constants: NetworkConstants, forgedHex: String, completion: @escaping ((Result<[Operation], ErrorResponse>) -> Void)) {
		guard let rpc = RPC.runOperation(runOperationPayload: runOperationPayload) else {
			os_log(.error, log: .kukaiCoreSwift, "Unable to create runOperation RPC, cancelling event")
			completion(Result.failure(ErrorResponse.internalApplicationError(error: FeeEstimatorServiceError.unableToSetupRunOperation)))
			return
		}
		
		self.networkService.send(rpc: rpc, withBaseURL: config.primaryNodeURL) { [weak self] (result) in
			var operationResponseToProcess: OperationResponse? = nil
			var errorToProcess: ErrorResponse? = nil
			
			switch result {
				case .success(let operationResponse):
					operationResponseToProcess = operationResponse
					
				case .failure(let error):
					
					// There are some cases where estimation ignores the wallets balance and allows you to estimate the cost of sending funds, where it would be impossible to pay the fee
					// There are other situations, such as sending to an unrevealed destination account, that estimation won't ignore the lack of balance to pay an allocation fee
					// For this reason, we check all errors to see if it is an insufficient funds error. If so we check if its an XTZ send (and doesn't include a reveal operation).
					// If these cases match, we try to parse the JSON anyway, as it will still contain the estimated fees. We continue processing, and return the fees.
					// We do this because the caller of this code must always be prepared for (sendingAmount + fees) is greater than the avialble wallet balance, and deduct the difference
					if error.errorType == .insufficientFunds,
					   !(operations.first is OperationReveal),
					   operations.last is OperationTransaction,
					   let jsonObjectWithError = try? JSONDecoder().decode(OperationResponse.self, from: error.responseJSON?.data(using: .utf8) ?? Data()) {
						operationResponseToProcess = jsonObjectWithError
					} else {
						errorToProcess = error
					}
			}
			
			
			guard let opToProcess = operationResponseToProcess else {
				os_log(.error, log: .kukaiCoreSwift, "Unable to estimate: %@", "\(errorToProcess?.description ?? "-")")
				completion(Result.failure(errorToProcess ?? ErrorResponse.unknownError()))
				return
			}
			
			
			// Extract gas, storage, burn, allocation etc, fees from the response body
			guard let fees = self?.extractFees(fromOperationResponse: opToProcess, forgedHash: forgedHex, withConstants: constants) else {
				completion(Result.failure(ErrorResponse.internalApplicationError(error: FeeEstimatorServiceError.invalidNumberOfFeesReturned)))
				return
			}
			
			
			// Apply the full fee to the last operation so its only charged if the whole thing is successful
			for (index, op) in operations.enumerated() {
				if index == operations.count-1 {
					op.operationFees = fees
				} else {
					op.operationFees = OperationFees(transactionFee: .zero(), gasLimit: 0, storageLimit: 0)
				}
			}
			
			completion(Result.success(operations))
		}
	}
	
	/// When we recieve a suggestion from Beacon, we don't need to perform a runOperation, instead just grab the suggestions and work out the fee
	private func estimateFeesOnly(operations: [Operation], constants: NetworkConstants, forgedHex: String, completion: @escaping ((Result<[Operation], ErrorResponse>) -> Void)) {
		let totalGas = operations.map({ $0.operationFees?.gasLimit ?? 0 }).reduce(0, +)
		let totalStorage = operations.map({ $0.operationFees?.storageLimit ?? 0 }).reduce(0, +)
		
		
		// Apply the full fee to the last operation so its only charged if the whole thing is successful
		for (index, op) in operations.enumerated() {
			if index == operations.count-1 {
				op.operationFees = operationFee(forGas: totalGas, forgedHash: forgedHex, storage: totalStorage, constants: constants, allocationStorage: 0, allocationFee: .zero())
			} else {
				op.operationFees = OperationFees(transactionFee: .zero(), gasLimit: 0, storageLimit: 0)
			}
		}
		
		completion(Result.success(operations))
	}
	
	/**
	Create an array of `OperationFees` from an `OperationResponse`.
	- parameter fromOperationResponse: The `OperationResponse` resulting from an RPC call to `.../run_operation`.
	- parameter forgedHash: The forged hash string resulting from a call to `TezosNodeClient.forge(...)`
	- returns: An array of `OperationFees`
	*/
	public func extractFees(fromOperationResponse operationResponse: OperationResponse, forgedHash: String, withConstants constants: NetworkConstants) -> OperationFees {
		var totalGas = 0
		var totalStorage = 0
		var totalAllocationStorage = 0 // Needs to be included in `storage_limit`, but ignored as a burn fee because it is an "allocation fee"
		var totalAllocationFee = XTZAmount.zero()
		
		for content in operationResponse.contents {
			let results = extractAndParseAttributes(fromResult: content.metadata.operationResult, withConstants: constants)
			totalGas += results.consumedGas
			totalStorage += results.storageBytesUsed
			totalAllocationFee += results.allocationFee
			
			// If we are allocating an address, we need to include it as storage on our operation
			if results.allocationFee > XTZAmount.zero() {
				totalAllocationStorage += constants.bytesForReveal()
			}
			
			
			if let innerOperationResults = content.metadata.internalOperationResults {
				for innerResult in innerOperationResults {
					let results = extractAndParseAttributes(fromResult: innerResult.result, withConstants: constants)
					totalGas += results.consumedGas
					totalStorage += results.storageBytesUsed
					totalAllocationFee += results.allocationFee
					
					// If we are allocating an address, we need to include it as storage on our operation
					if results.allocationFee > XTZAmount.zero() {
						totalAllocationStorage += constants.bytesForReveal()
					}
				}
			}
		}
		
		return operationFee(forGas: totalGas, forgedHash: forgedHash, storage: totalStorage, constants: constants, allocationStorage: totalAllocationStorage, allocationFee: totalAllocationFee)
	}
	
	/// Private helper to extract fee calcualtion logic, as its needed in multiple places
	private func operationFee(forGas: Int, forgedHash: String, storage: Int, constants: NetworkConstants, allocationStorage: Int, allocationFee: XTZAmount) -> OperationFees {
		let totalGas = forGas + gasSafetyMargin
		
		let gasFee = feeForGas(totalGas)
		let storageFee = feeForStorage(forgedHash)
		let burnFee = feeForBurn(storage, withConstants: constants)
		let networkFees = [[OperationFees.NetworkFeeType.burnFee: burnFee, OperationFees.NetworkFeeType.allocationFee: allocationFee]]
		
		return OperationFees(transactionFee: FeeConstants.baseFee + gasFee + storageFee, networkFees: networkFees, gasLimit: totalGas, storageLimit: storage + allocationStorage)
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
	private func feeForStorage(_ forgedHexString: String) -> XTZAmount {
		let forgedHexWithSignature = (forgedHexString + FeeEstimatorService.defaultSignatureHex)
		let nanoTez = ((forgedHexWithSignature.count/2) + 10) * FeeConstants.feePerStorageByte // Multiply bytes (2 characters per byte) by the fee perSotrageByteConstant. Add 10 bytes to account for any variations
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
