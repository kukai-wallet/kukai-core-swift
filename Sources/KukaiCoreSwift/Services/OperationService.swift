//
//  OperationService.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 02/12/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import KukaiCryptoSwift
import Sodium
import os.log

/// Several classes need to use pieces of the   forge-sign-parse-preapply-inject   flow. This class abstracts those functions away so that it can be shared throughout the library.
public class OperationService {
	
	/// Errors that the OperationService is capable of returning
	public enum OperationServiceError: Error {
		case unableToSetupForge
		case unableToSetupParse
		case parseFailed
		case signingFailure
		case unableToSetupPreapply
		case preapplyContainedError(errors: [OperationResponseInternalResultError]?)
		case unableToSetupInject
		case noRemoteParseURLFound
	}
	
	/// Used to return a bunch of formatted data, to make interacting with ledger sign operation easier
	public struct LedgerPayloadPrepResponse {
		public let payload: OperationPayload
		public let forgedOp: String
		public let watermarkedOp: String
		public let blake2bHash: String
		public let metadata: OperationMetadata
		public let canLedgerParse: Bool
	}
	
	
	
	// MARK: - Public Properties
	
	/// The configuration object containing all the necessary settings to connect and communicate with the Tezos node
	public let config: TezosNodeClientConfig
	
	/// The `NetworkService` object that will perform all the networking calls
	public let networkService: NetworkService
	
	
	
	// MARK: - Init
	
	/**
	Init a `TezosNodeClient` with a `TezosNodeClientConfig`.
	- parameter config: A configuration object containing all the necessary settings to connect and communicate with the Tezos node.
	*/
	public init(config: TezosNodeClientConfig = TezosNodeClientConfig(withDefaultsForNetworkType: .mainnet), networkService: NetworkService) {
		self.config = config
		self.networkService = networkService
	}
	
	
	
	
	
	// MARK: - Top level functions
	
	/**
	When using remote forging, every `Operation` needs to be Forged, Parsed, Signed, Preapply'd and Injected to make its way into the blockchain.
	This function will complete all of those steps and return an OperationID or an Error.
	- parameter operationMetadata: The latest `OperationMetadata` from the TezosNodeClient
	- parameter operationPayload: The `OperationPayload` generated by the `OperationFactory`
	- parameter wallet: The `Wallet` that will sign the operation
	- parameter completion: Completion block either returning a String containing an OperationHash of the injected Operation, or an Error
	*/
	public func remoteForgeParseSignPreapplyInject(operationMetadata: OperationMetadata, operationPayload: OperationPayload, wallet: Wallet, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		
		// Perform a remote forge of the oepration with the metadata
		remoteForge(operationMetadata: operationMetadata, operationPayload: operationPayload, wallet: wallet, completion: { [weak self] (result) in
			
			// Parse remotely against a different server to verify hash is correct before continuing
			self?.remoteParse(forgeResult: result, operationMetadata: operationMetadata, operationPayload: operationPayload) { (innerResult) in
				switch innerResult {
					case .success(let hash):
						
						// With a successful Parse, we can continue on to Sign, Preapply (to check for errors) and if no errors, inject the operation
						os_log(.debug, log: .kukaiCoreSwift, "Remote parse successful")
						self?.signPreapplyAndInject(wallet: wallet, forgedHash: hash, operationPayload: operationPayload, operationMetadata: operationMetadata, completion: completion)
						
					case .failure(let parseError):
						completion(Result.failure(parseError))
						return
				}
			}
		})
	}
	
	/**
	When using local forging, every `Operation` needs to be Forged, Signed, Preapply'd and Injected to make its way into the blockchain.
	This function will complete all of those steps and return an OperationID or an Error.
	- parameter operationMetadata: The latest `OperationMetadata` from the TezosNodeClient
	- parameter operationPayload: The `OperationPayload` generated by the `OperationFactory`
	- parameter wallet: The `Wallet` that will sign the operation
	- parameter completion: Completion block either returning a String containing an OperationHash of the injected Operation, or an Error
	*/
	public func localForgeSignPreapplyInject(operationMetadata: OperationMetadata, operationPayload: OperationPayload, wallet: Wallet, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		var operationPayloadMinus3 = operationPayload
		operationPayloadMinus3.branch = operationMetadata.branchMinus3
		
		TaquitoService.shared.forge(operationPayload: operationPayloadMinus3) { [weak self] forgeResult in
			switch forgeResult {
				case .success(let forgedString):
					self?.signPreapplyAndInject(wallet: wallet, forgedHash: forgedString, operationPayload: operationPayload, operationMetadata: operationMetadata, completion: completion)
					
				case .failure(let forgeError):
					completion(Result.failure(KukaiError.internalApplicationError(error: forgeError)))
			}
		}
	}
	
	
	
	
	
	// MARK: - Helpers / wrappers
	
	/// Internal function to group together operations for readability sake
	private func signPreapplyAndInject(wallet: Wallet, forgedHash: String, operationPayload: OperationPayload, operationMetadata: OperationMetadata, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		var stringToSign = forgedHash
		
		if wallet.type == .ledger {
			stringToSign = ledgerStringToSign(forgedHash: forgedHash, operationPayload: operationPayload)
		}
		
		
		// Sign whatever string is required, and move on to preapply / inject
		wallet.sign(stringToSign) { [weak self] result in
			guard let signature = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			self?.preapplyAndInject(forgedOperation: forgedHash, signature: signature, signatureCurve: wallet.privateKeyCurve(), operationPayload: operationPayload, operationMetadata: operationMetadata, completion: completion)
		}
	}
	
	/**
	 Ledger can only parse operations under certain conditions. These conditions are not documented well. This function will attempt to determine whether the payload can be parsed or not, and returnt he appropriate string for the LedgerWallet sign function
	 It seems to be able to parse the payload if it contains 1 operation, of the below types. Combining types (like Reveal + Transation) causes a parse error
	 If the payload structure passes the conditions we are aware of, allow parsing to take place. If not, sign blake2b hash instead
	 */
	public func ledgerStringToSign(forgedHash: String, operationPayload: OperationPayload) -> String {
		let watermarkedOp = "03" + forgedHash
		let watermarkedBytes = Sodium.shared.utils.hex2bin(watermarkedOp) ?? []
		let blakeHash = Sodium.shared.genericHash.hash(message: watermarkedBytes, outputLength: 32)
		let blakeHashString = blakeHash?.toHexString() ?? ""
		
		// Ledger can only parse operations under certain conditions. These conditions are not documented well.
		// It seems to be able to parse the payload if it contains 1 operation, of the below types. Combining types (like Reveal + Transation) causes a parse error
		// If the payload structure passes the conditions we are aware of, allow parsing to take place. If not, sign blake2b hash instead
		var ledgerCanParse = false
		if operationPayload.contents.count == 1, let first = operationPayload.contents.first, (first is OperationReveal || first is OperationDelegation || first is OperationTransaction) {
			ledgerCanParse = true
		}
		
		return (ledgerCanParse ? watermarkedOp : blakeHashString)
	}
	
	/**
	Preapply and Inject wrapped up as one function, for situations like Ledger Wallets, where signing is a complately different process, and must be done elsewhere
	- parameter forgedOperation: The forged operation hex without a watermark.
	- parameter signature: Binary representation of the signed operation forge.
	- parameter signatureCurve: The curve used to sign the forge.
	- parameter operationPayload: The payload to be sent.
	- parameter operationMetadata: The metadata required to send the payload.
	- parameter completion: callback with a forged hash or an error.
	*/
	public func preapplyAndInject(forgedOperation: String, signature: [UInt8], signatureCurve: EllipticalCurve, operationPayload: OperationPayload, operationMetadata: OperationMetadata, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		
		// Add the signature and protocol to the payload
		var signedPayload = operationPayload
		signedPayload.addSignature(signature, signingCurve: signatureCurve)
		signedPayload.addProtcol(fromMetadata: operationMetadata)
		
		
		// Perform the preapply to check for errors, otherwise attempt to inject the operation onto the blockchain
		self.preapply(operationMetadata: operationMetadata, operationPayload: signedPayload) { [weak self] (preapplyResult) in
			self?.inject(signedBytes: forgedOperation+signature.toHexString(), handlePreapplyResult: preapplyResult) { (injectResult) in
				completion(injectResult)
			}
		}
	}
	
	/**
	Forge an `OperationPayload` remotely, so it can be sent to the RPC.
	- parameter operationMetadata: fetched from `getOperationMetadata(...)`.
	- parameter operationPayload: created from `OperationFactory.operationPayload()`.
	- parameter wallet: The `Wallet` object that will sign the operations.
	- parameter completion: callback with a forged hash or an error.
	*/
	public func remoteForge(operationMetadata: OperationMetadata, operationPayload: OperationPayload, wallet: Wallet, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		
		guard let rpc = RPC.forge(operationPayload: operationPayload, withMetadata: operationMetadata) else {
			os_log(.error, log: .kukaiCoreSwift, "Unable to create forge RPC, cancelling event")
			completion(Result.failure(KukaiError.internalApplicationError(error: OperationServiceError.unableToSetupForge)))
			return
		}
		
		self.networkService.send(rpc: rpc, withBaseURL: config.primaryNodeURL) { (result) in
			switch result {
				case .success(let string):
					completion(Result.success(string))
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Unable to remote forge: %@", "\(error)")
					completion(Result.failure(error))
			}
		}
	}
	
	/**
	Parse a forged `OperationPayload` on a different server to ensure nobody maliciously tampared with the request.
	- parameter forgeResult: The `Result` object from the `forge(...)` function.
	- parameter operationMetadata: fetched from `getOperationMetadata(...)`.
	- parameter operationPayload: the `OperationPayload` to compare against to ensure it matches.
	- parameter completion: callback which just returns success or failure with an error.
	*/
	public func remoteParse(forgeResult: Result<String, KukaiError>, operationMetadata: OperationMetadata, operationPayload: OperationPayload, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		guard let parseURL = config.parseNodeURL else {
			completion(Result.failure(KukaiError.internalApplicationError(error: OperationServiceError.noRemoteParseURLFound)))
			return
		}
		
		
		// Handle the forge result first to check there are no errors
		var remoteForgedHash = ""
		
		switch forgeResult {
			case .success(let forgedHash):
				remoteForgedHash = forgedHash
				
			case .failure(_):
				completion(forgeResult) // Pass error upwards and exit early
				return
		}
		
		
		// Continue with parse
		guard let rpc = RPC.parse(hashToParse: remoteForgedHash, metadata: operationMetadata) else {
			os_log(.error, log: .kukaiCoreSwift, "Unable to create parse RPC, cancelling event")
			completion(Result.failure(KukaiError.internalApplicationError(error: OperationServiceError.unableToSetupParse)))
			return
		}
		
		self.networkService.send(rpc: rpc, withBaseURL: parseURL) { (result) in
			switch result {
				case .success(let parsedPayload):
					
					if parsedPayload.count > 0 && parsedPayload[0] == operationPayload {
						completion(Result.success(remoteForgedHash))
					} else {
						completion(Result.failure(KukaiError.internalApplicationError(error: OperationServiceError.parseFailed)))
					}
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Unable to remote forge: %@", "\(error)")
					completion(Result.failure(error))
			}
		}
	}
	
	/**
	Preapply a signed `OperationPayload` to check for any errors.
	- parameter operationMetadata: Fetched from `getOperationMetadata(...)`.
	- parameter operationPayload: An `OperationPayload`that has had a signature and a protcol added to it.
	- parameter completion: Callback which just returns success or failure with an error.
	*/
	public func preapply(operationMetadata: OperationMetadata, operationPayload: OperationPayload, completion: @escaping ((Result<[OperationResponse], KukaiError>) -> Void)) {
		
		guard let rpc = RPC.preapply(operationPayload: operationPayload, withMetadata: operationMetadata) else {
			os_log(.error, log: .kukaiCoreSwift, "Unable to create preapply RPC, cancelling event")
			completion(Result.failure(KukaiError.internalApplicationError(error: OperationServiceError.unableToSetupPreapply)))
			return
		}
		
		self.networkService.send(rpc: rpc, withBaseURL: config.primaryNodeURL) { (result) in
			switch result {
				case .success(let operationResponse):
					completion(Result.success(operationResponse))
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Preapply returned an error: %@", "\(error)")
					completion(Result.failure(error))
			}
		}
	}
	
	
	/**
	Inject a signed bytes to become part of the next block on the blockchain
	- parameter signedBytes: The result of the forge operation (as a string) with the signature (as a hex string) appended on.
	- parameter handlePreapplyResult: Optionally pass in the result of the preapply function to reduce the indentation required to perform the full set of operations. Any error will be returned via the injection Result object.
	*/
	public func inject(signedBytes: String, handlePreapplyResult: Result<[OperationResponse], KukaiError>?, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		
		// Check if we are handling a preapply result to check for errors
		if let preapplyResult = handlePreapplyResult {
			switch preapplyResult {
				case .success(let operationResponse):
					
					// Search for errors inside each `OperationResponse`, if theres an error present return them all
					let errors = operationResponse.compactMap({ $0.errors() }).reduce([], +)
					if errors.count > 0 {
						completion(Result.failure(KukaiError.internalApplicationError(error: OperationServiceError.preapplyContainedError(errors: errors))))
						return
					}
					
				// Else continue on to inject. The purpose of the preapply is to just check for errors. If no errors, we can safely attempt an injection
				
				case .failure(let preapplyError):
					completion(Result.failure(preapplyError))
					return
			}
		}
		
		// Continue on with the injection
		guard let rpc = RPC.inject(signedBytes: signedBytes) else {
			os_log(.error, log: .kukaiCoreSwift, "Unable to create inject RPC, cancelling event")
			completion(Result.failure(KukaiError.internalApplicationError(error: OperationServiceError.unableToSetupInject)))
			return
		}
		
		self.networkService.send(rpc: rpc, withBaseURL: config.primaryNodeURL) { (result) in
			completion(result)
		}
	}
}
