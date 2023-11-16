//
//  FeeEstimatorService.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 18/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import KukaiCryptoSwift
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
		public static let nanoTezPerMutez: Int = 1000
		public static let minimalFee: NanoTez = 100_000
		public static let feePerGasUnit: NanoTez = 100
		public static let feePerStorageByte: NanoTez = 1000
		public static let baseFee = XTZAmount(fromNormalisedAmount: 0.0001)
	}
	
	/// Various possible errors that can occur during an Estimation
	public enum FeeEstimatorServiceError: Error {
		case tezosNodeClientNotPresent
		case unableToSetupRunOperation
		case invalidNumberOfFeesReturned
		case failedToCopyOperations
		case estimationRemoteError(errors: [OperationResponseInternalResultError]?)
		case unsupportedWalletAddressPrefix
	}
	
	public struct EstimationResult: Codable {
		public let operations: [Operation]
		public let forgedString: String
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
	public func estimate(operations: [Operation], operationMetadata: OperationMetadata, constants: NetworkConstants, walletAddress: String, base58EncodedPublicKey: String, completion: @escaping ((Result<EstimationResult, KukaiError>) -> Void)) {
		let operationPayload = OperationFactory.operationPayload(fromMetadata: operationMetadata, andOperations: operations, walletAddress: walletAddress, base58EncodedPublicKey: base58EncodedPublicKey)
		let originalRemoteOps = operations.copyOperations()
		let preparedOperationsCopy = operationPayload.contents.copyOperations()
		
		// Before estimating, set the maximum gas and storage to ensure the operation suceeds (excluding any errors such as invalid address, insufficnet funds etc)
		let simulationGas = min(constants.maxGasPerOperation(), Int(constants.maxGasPerBlock() / (operations.count + 1)) )
		let maxGasAndStorage = OperationFees(transactionFee: XTZAmount.zero(), gasLimit: simulationGas, storageLimit: constants.maxStoragePerOperation())
		operationPayload.contents.forEach {
			$0.operationFees = maxGasAndStorage
			
			// To handle issues with sending max Tez, and simulation API not ignoring burn fees etc
			// modify the operationPayload contents to send 1 mutez instead of real amount
			// This won't effect the returned operations later, as we've made a deep copy first and will use that afte rthe estimation
			if $0.operationKind == .transaction, let transOp = $0 as? OperationTransaction, (transOp.destination.prefix(3) != "KT1" && ($0 as? OperationTransaction)?.parameters == nil) {
				transOp.amount = "1" // rpc representation of 1 mutez
			}
		}
		
		guard let ellipticalCurve = EllipticalCurve.fromAddress(walletAddress) else {
			completion(Result.failure(KukaiError.internalApplicationError(error: FeeEstimatorServiceError.unsupportedWalletAddressPrefix)))
			return
		}
		
		switch self.config.forgingType {
			case .local:
				TaquitoService.shared.forge(operationPayload: operationPayload) { [weak self] forgedResult in
					self?.handleForge(forgeResult: forgedResult,
									  operationPayload: operationPayload,
									  operationMetadata: operationMetadata,
									  preparedOperationsCopy: preparedOperationsCopy,
									  constants: constants,
									  signingCurve: ellipticalCurve,
									  originalRemoteOps: originalRemoteOps,
									  completion: completion)
				}
				
			case .remote:
				operationService.remoteForge(operationPayload: operationPayload) { [weak self] forgedResult in
					self?.handleForge(forgeResult: forgedResult,
									  operationPayload: operationPayload,
									  operationMetadata: operationMetadata,
									  preparedOperationsCopy: preparedOperationsCopy,
									  constants: constants,
									  signingCurve: ellipticalCurve,
									  originalRemoteOps: originalRemoteOps,
									  completion: completion)
				}
		}
	}
	
	/// Shared function to run whether forged locally or remote
	private func handleForge(forgeResult: Result<String, KukaiError>,
							 operationPayload: OperationPayload,
							 operationMetadata: OperationMetadata,
							 preparedOperationsCopy: [Operation],
							 constants: NetworkConstants,
							 signingCurve: EllipticalCurve,
							 originalRemoteOps: [Operation],
							 completion: @escaping ((Result<EstimationResult, KukaiError>) -> Void))
	{
		switch forgeResult {
			case .success(let hexString):
				var mutablePayload = operationPayload
				mutablePayload.addSignature(FeeEstimatorService.defaultSignature, signingCurve: signingCurve)
				let runOperationPayload = RunOperationPayload(chainID: operationMetadata.chainID, operation: mutablePayload)
				
				self.estimate(runOperationPayload: runOperationPayload, preparedOperationsCopy: preparedOperationsCopy, constants: constants, forgedHex: hexString, originalRemoteOps: originalRemoteOps, completion: completion)
			
			case .failure(let error):
				completion(Result.failure(error))
				return
		}
	}

	/// Breaking out part of the estimation process to keep code cleaner
	private func estimate(runOperationPayload: RunOperationPayload, preparedOperationsCopy: [Operation], constants: NetworkConstants, forgedHex: String, originalRemoteOps: [Operation], completion: @escaping ((Result<EstimationResult, KukaiError>) -> Void)) {
		guard let rpc = RPC.runOperation(runOperationPayload: runOperationPayload) else {
			Logger.kukaiCoreSwift.error("Unable to create runOperation RPC, cancelling event")
			completion(Result.failure(KukaiError.internalApplicationError(error: FeeEstimatorServiceError.unableToSetupRunOperation)))
			return
		}
		
		self.networkService.send(rpc: rpc, withBaseURL: config.primaryNodeURL) { [weak self] (result) in
			guard let opToProcess = try? result.get(), let fees = self?.extractFees(fromOperationResponse: opToProcess, forgedHash: forgedHex, withConstants: constants) else {
				completion(Result.failure( result.getFailure()))
				return
			}
			
			// Make sure we have created a `OperationFees` for each operation
			if fees.count != preparedOperationsCopy.count {
				completion(Result.failure(KukaiError.internalApplicationError(error: FeeEstimatorServiceError.invalidNumberOfFeesReturned)))
				return
			}
			
			
			// Operations can come in with suggested fees (e.g. when using a dApp through something like Beacon).
			// We always do an estimation and pick which ever is higher, the supplied suggested fees (which should always be worst case, but can be flawed), or the result of the estimation
			var lastOpFee: OperationFees = OperationFees(transactionFee: .zero(), gasLimit: 0, storageLimit: 0)
			var operationFeesToUse: [OperationFees] = []
			var original = originalRemoteOps
			
			
			// originalOps may not contain a reveal operation, if the first request a user does is wallet connect / beacon.
			// Check and add a dummy reveal operation to the "originalOps", so that fees are calcualted correctly
			if (preparedOperationsCopy.first is OperationReveal && original.count < preparedOperationsCopy.count) {
				let reveal = OperationReveal(base58EncodedPublicKey: "", walletAddress: "") // dummy only used as an OperationsFee placeholder
				reveal.operationFees = OperationFees(transactionFee: .zero(), networkFees: fees.first?.networkFees ?? [:], gasLimit: fees.first?.gasLimit ?? 0, storageLimit: fees.first?.storageLimit ?? 0)
				original.insert(reveal, at: 0)
			}
			
			
			// Check whether to use suggested fees, or estiamted fees
			if original.map({ $0.operationFees.gasLimit }).reduce(0, +) > fees.map({ $0.gasLimit }).reduce(0, +) {
				lastOpFee = self?.calcFeeFromSuggestedOperations(operations: original, constants: constants, forgedHex: forgedHex) ?? OperationFees.zero()
				operationFeesToUse = original.map({ $0.operationFees })
				
			} else {
				lastOpFee = fees.last ?? OperationFees.zero()
				operationFeesToUse = fees
			}
			
			
			// Set gas, storage and network fees on each operation, but only add transaction fee to last operation.
			// The entire chain of operations can fail due to one in the middle failing. If that happens, only fees attached to operations that were processed, gets debited
			for (index, op) in preparedOperationsCopy.enumerated() {
				op.operationFees = operationFeesToUse[index]
				
				if index == preparedOperationsCopy.count-1 {
					op.operationFees.transactionFee = lastOpFee.transactionFee
					op.operationFees.networkFees = lastOpFee.networkFees
					
				} else {
					op.operationFees.transactionFee = .zero()
				}
			}
			
			completion(Result.success(EstimationResult(operations: preparedOperationsCopy, forgedString: forgedHex)))
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
			opGas = FeeEstimatorService.addGasSafetyMarginTo(gasUsed: results.consumedGas)
			opStorage = results.storageBytesUsed
			opAllocationFee = results.allocationFee
			
			totalGas += FeeEstimatorService.addGasSafetyMarginTo(gasUsed: results.consumedGas)
			totalStorage += results.storageBytesUsed
			totalAllocationFee += results.allocationFee
			
			// If we are allocating an address, we need to include it as storage on our operation
			if results.allocationFee > XTZAmount.zero() {
				opAllocationStorage = constants.bytesForReveal()
			}
			
			if let innerOperationResults = content.metadata.internalOperationResults {
				for innerResult in innerOperationResults {
					let results = extractAndParseAttributes(fromResult: innerResult.result, withConstants: constants)
					opGas += FeeEstimatorService.addGasSafetyMarginTo(gasUsed: results.consumedGas)
					opStorage += results.storageBytesUsed
					opAllocationFee += results.allocationFee
					
					totalGas += FeeEstimatorService.addGasSafetyMarginTo(gasUsed: results.consumedGas)
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
		let fee = FeeEstimatorService.fee(forGasLimit: totalGas, forgedHexString: forgedHash, numberOfOperations: opCount)
		let burnFee = FeeEstimatorService.feeForBurn(totalStorage, withConstants: constants)
		let networkFees = [OperationFees.NetworkFeeType.burnFee: burnFee, OperationFees.NetworkFeeType.allocationFee: .zero()]
		
		return OperationFees(transactionFee: fee, networkFees: networkFees, gasLimit: 0, storageLimit: 0)
	}
	
	/// Create an instance of `OperationFees` for a last operation, with its corresponding gas + storage, but fees for the entire list of operations
	private func createLimitsAndTotalFeeObj(totalGas: Int, opGas: Int, opCount: Int, totalStorage: Int, opStorage: Int, forgedHash: String, constants: NetworkConstants, allocationStorage: Int, totalAllocationFee: XTZAmount) -> OperationFees {
		let fee = FeeEstimatorService.fee(forGasLimit: totalGas, forgedHexString: forgedHash, numberOfOperations: opCount)
		let burnFee = FeeEstimatorService.feeForBurn(totalStorage, withConstants: constants)
		let networkFees = [OperationFees.NetworkFeeType.burnFee: burnFee, OperationFees.NetworkFeeType.allocationFee: totalAllocationFee]
		
		return OperationFees(transactionFee: fee, networkFees: networkFees, gasLimit: opGas, storageLimit: opStorage + allocationStorage)
	}
	
	/// Private helper to process `OperationResponseResult` block. Complicated operations will contain many of these.
	private func extractAndParseAttributes(fromResult result: OperationResponseResult?, withConstants constants: NetworkConstants) -> (consumedGas: Int, storageBytesUsed: Int, allocationFee: XTZAmount) {
		guard let result = result else {
			return (consumedGas: 0, storageBytesUsed: 0, allocationFee: XTZAmount.zero())
		}
		
		var consumedGas = Decimal(string: result.consumedMilligas ?? "0") ?? 0
		consumedGas = (consumedGas / 1000).rounded(scale: 0, roundingMode: .bankers)
		let paidStorageSizeDiff = Int(result.paidStorageSizeDiff ?? "0") ?? 0
		var allocationFee = XTZAmount.zero()
		
		if let allocated = result.allocatedDestinationContract, allocated {
			allocationFee = constants.xtzForReveal()
		}
		
		return (consumedGas: consumedGas.intValue(), storageBytesUsed: paidStorageSizeDiff, allocationFee: allocationFee)
	}
	
	/// Calculate the fee to add for the given amount of gas
	public static func feeForGas(_ gas: Int) -> XTZAmount {
		let nanoTez = gas * FeeConstants.feePerGasUnit
		return nanoTeztoXTZ(nanoTez)
	}
	
	/// Calculate the fee to add based on the size of the forged string
	public static func feeForStorage(_ forgedHexString: String, numberOfOperations: Int) -> XTZAmount {
		let forgedHexWithSignature = (forgedHexString + FeeEstimatorService.defaultSignatureHex)
		let nanoTez = ((forgedHexWithSignature.count/2) + (10 * numberOfOperations)) * FeeConstants.feePerStorageByte // Multiply bytes (2 characters per byte) by the fee perSotrageByteConstant. Add 10 bytes per op to account for any variations
		return nanoTeztoXTZ(nanoTez)
	}
	
	/// Calculate the fee to add based on how many bytes of storage where needed
	public static func feeForBurn(_ burn: Int, withConstants contants: NetworkConstants) -> XTZAmount {
		return contants.xtzPerByte() * burn
	}
	
	/// Most calcualtions are documented in NanoTez, which is not accpeted by the network RPC calls. Needs to be converted to Mutez / XTZ
	public static func nanoTeztoXTZ(_ nanoTez: NanoTez) -> XTZAmount {
		let mutez = nanoTez % FeeConstants.nanoTezPerMutez == 0 ?
			nanoTez / FeeConstants.nanoTezPerMutez :
			(nanoTez / FeeConstants.nanoTezPerMutez) + 1
		
		return XTZAmount(fromRpcAmount: Decimal(mutez)) ?? XTZAmount.zero()
	}
	
	public static func fee(forGasLimit gasLimit: Int, forgedHexString: String, numberOfOperations: Int) -> XTZAmount {
		let gasFee = feeForGas(gasLimit)
		let costToStoreOp = feeForStorage(forgedHexString, numberOfOperations: numberOfOperations)
		
		return FeeConstants.baseFee + gasFee + costToStoreOp
	}
	
	public static func addGasSafetyMarginTo(gasUsed: Int) -> Int {
		return max( Int(ceil(Double(gasUsed) * 1.02)), gasUsed + 25)
	}
}
