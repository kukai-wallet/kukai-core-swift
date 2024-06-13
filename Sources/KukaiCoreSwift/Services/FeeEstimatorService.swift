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
			if $0.operationKind == .transaction, let transOp = $0 as? OperationTransaction, (transOp.destination.prefix(3) != "KT1" && transOp.parameters == nil && transOp.destination != walletAddress) {
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
									  fromAddress: walletAddress,
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
									  fromAddress: walletAddress,
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
							 fromAddress address: String,
							 completion: @escaping ((Result<EstimationResult, KukaiError>) -> Void))
	{
		switch forgeResult {
			case .success(let hexString):
				var mutablePayload = operationPayload
				mutablePayload.addSignature(FeeEstimatorService.defaultSignature, signingCurve: signingCurve)
				let runOperationPayload = RunOperationPayload(chainID: operationMetadata.chainID, operation: mutablePayload)
				
				self.estimate(runOperationPayload: runOperationPayload, preparedOperationsCopy: preparedOperationsCopy, constants: constants, forgedHex: hexString, originalRemoteOps: originalRemoteOps, fromAddress: address, completion: completion)
			
			case .failure(let error):
				completion(Result.failure(error))
				return
		}
	}

	/// Breaking out part of the estimation process to keep code cleaner
	private func estimate(runOperationPayload: RunOperationPayload,
						  preparedOperationsCopy: [Operation],
						  constants: NetworkConstants,
						  forgedHex: String,
						  originalRemoteOps: [Operation],
						  fromAddress address: String,
						  completion: @escaping ((Result<EstimationResult, KukaiError>) -> Void)) {
		
		guard let rpc = RPC.simulateOperation(runOperationPayload: runOperationPayload) else {
			Logger.kukaiCoreSwift.error("Unable to create runOperation RPC, cancelling event")
			completion(Result.failure(KukaiError.internalApplicationError(error: FeeEstimatorServiceError.unableToSetupRunOperation)))
			return
		}
		
		self.networkService.send(rpc: rpc, withNodeURLs: config.nodeURLs) { [weak self] (result) in
			guard let opToProcess = try? result.get(), let fees = self?.extractFees(fromOperationResponse: opToProcess, originalRemoteOps: originalRemoteOps, forgedHash: forgedHex, withConstants: constants, fromAddress: address) else {
				completion(Result.failure( result.getFailure()))
				return
			}
			
			// Make sure we have created a `OperationFees` for each operation
			if fees.count != preparedOperationsCopy.count {
				completion(Result.failure(KukaiError.internalApplicationError(error: FeeEstimatorServiceError.invalidNumberOfFeesReturned)))
				return
			}
			
			// Set gas, storage and network fees on each operation, but only add transaction fee to last operation.
			// The entire chain of operations can fail due to one in the middle failing. If that happens, only fees attached to operations that were processed, gets debited
			for (index, op) in preparedOperationsCopy.enumerated() {
				op.operationFees = fees[index]
				
				if index == preparedOperationsCopy.count-1 {
					let lastOpFee = fees.last ?? OperationFees.zero()
					op.operationFees.transactionFee = lastOpFee.transactionFee
					op.operationFees.networkFees = lastOpFee.networkFees
					
				} else {
					op.operationFees.transactionFee = .zero()
				}
			}
			
			completion(Result.success(EstimationResult(operations: preparedOperationsCopy, forgedString: forgedHex)))
		}
	}
	
	/**
	Create an array of `OperationFees` from an `OperationResponse`.
	- parameter fromOperationResponse: The `OperationResponse` resulting from an RPC call to `.../run_operation`.
	- parameter forgedHash: The forged hash string resulting from a call to `TezosNodeClient.forge(...)`
	- returns: An array of `OperationFees`
	*/
	public func extractFees(fromOperationResponse operationResponse: OperationResponse, originalRemoteOps: [Operation], forgedHash: String, withConstants constants: NetworkConstants, fromAddress address: String) -> [OperationFees] {
		var opFees: [OperationFees] = []
		var totalGas: Decimal = 0
		var totalStorage: Decimal = 0
		
		
		// preparedOperationsCopy may contain an extra reveal operation at the start
		for (index, content) in operationResponse.contents.enumerated() {
			var opGas: Decimal = 0
			var opStorage: Decimal = 0
			let suggestedCompareIndex = (operationResponse.contents.first?.kind == "reveal" && operationResponse.contents.count != originalRemoteOps.count) ? -1 : 0
			
			
			// Storage
			if content.source == address {
				opStorage -= Decimal(string: content.amount ?? "0") ?? 0
				opStorage -= Decimal(string: content.fee ?? "0") ?? 0
				opStorage -= Decimal(string: content.balance ?? "0") ?? 0
			}
			
			if content.destination == address {
				opStorage += Decimal(string: content.amount ?? "0") ?? 0
			}
			
			for balanceUpdate in content.metadata.operationResult?.balanceUpdates ?? [] {
				if balanceUpdate.contract == address || balanceUpdate.staker?.contract == address {
					opStorage -= Decimal(string: balanceUpdate.change) ?? 0
				}
			}
			
			for balanceUpdate in content.metadata.balanceUpdates ?? [] {
				if balanceUpdate.contract == address {
					opStorage -= Decimal(string: balanceUpdate.change) ?? 0
				}
			}
			
			// Gas
			opGas += ((Decimal(string: content.metadata.operationResult?.consumedMilligas ?? "0") ?? 0) / 1000).rounded(scale: 0, roundingMode: .up)
			for internalResult in content.metadata.internalOperationResults ?? [] {
				opGas += ((Decimal(string: internalResult.result.consumedMilligas ?? "0") ?? 0) / 1000).rounded(scale: 0, roundingMode: .up)
				
				for balanceUpdate in internalResult.result.balanceUpdates ?? [] {
					if balanceUpdate.contract == address && balanceUpdate.change.prefix(1) == "-" {
						opStorage -= Decimal(string: balanceUpdate.change) ?? 0
					}
				}
			}
			opGas = Decimal(FeeEstimatorService.addGasSafetyMarginTo(gasUsed: opGas.intValue()))
			
			
			
			// Convert storage to bytes
			opStorage = opStorage / (constants.xtzPerByte().toRpcDecimal() ?? 250)
			
			// Check for reveal
			if content.metadata.operationResult?.allocatedDestinationContract == true {
				opStorage += Decimal(constants.bytesForReveal())
			}
			
			for internalResult in content.metadata.internalOperationResults ?? [] {
				if internalResult.result.allocatedDestinationContract == true {
					opStorage += Decimal(constants.bytesForReveal())
				}
			}
			
			
			
			// Check whether suggested or estimated gas / storage is higher and pick that
			let indexToCheck = index + suggestedCompareIndex
			if indexToCheck > -1 {
				let op = originalRemoteOps[indexToCheck]
				
				if op.operationFees.gasLimit > opGas.intValue() {
					opGas = Decimal(op.operationFees.gasLimit)
				}
				
				if op.operationFees.storageLimit > opStorage.intValue() {
					opStorage = Decimal(op.operationFees.storageLimit)
				}
			}
			
			
			
			
			// Sum totals for later
			totalGas += opGas
			totalStorage += opStorage
			
			
			// If last
			if index == operationResponse.contents.count-1 {
				opFees.append( createLimitsAndTotalFeeObj(totalGas: totalGas.intValue(),
														  opGas: opGas.intValue(),
														  opCount: operationResponse.contents.count,
														  totalStorage: totalStorage.intValue(),
														  opStorage: opStorage.intValue(),
														  forgedHash: forgedHash,
														  constants: constants) )
				
			} else {
				opFees.append( OperationFees(transactionFee: .zero(), gasLimit: opGas.intValue(), storageLimit: opStorage.intValue()) )
			}
		}
		
		return opFees
	}
	
	/// Create an instance of `OperationFees` in order to calculate a transaction fee. Used to calculate the overall transaction fee
	private func calcTransactionFee(totalGas: Int, opCount: Int, totalStorage: Int, forgedHash: String, constants: NetworkConstants) -> OperationFees {
		let fee = FeeEstimatorService.fee(forGasLimit: totalGas, forgedHexString: forgedHash, numberOfOperations: opCount)
		let burnFee = FeeEstimatorService.feeForBurn(totalStorage, withConstants: constants)
		let networkFees = [OperationFees.NetworkFeeType.burnFee: burnFee]
		
		return OperationFees(transactionFee: fee, networkFees: networkFees, gasLimit: 0, storageLimit: 0)
	}
	
	/// Create an instance of `OperationFees` for a last operation, with its corresponding gas + storage, but fees for the entire list of operations
	private func createLimitsAndTotalFeeObj(totalGas: Int, opGas: Int, opCount: Int, totalStorage: Int, opStorage: Int, forgedHash: String, constants: NetworkConstants) -> OperationFees {
		let fee = FeeEstimatorService.fee(forGasLimit: totalGas, forgedHexString: forgedHash, numberOfOperations: opCount)
		let burnFee = FeeEstimatorService.feeForBurn(totalStorage, withConstants: constants)
		let networkFees = [OperationFees.NetworkFeeType.burnFee: burnFee]
		
		return OperationFees(transactionFee: fee, networkFees: networkFees, gasLimit: opGas, storageLimit: opStorage)
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
