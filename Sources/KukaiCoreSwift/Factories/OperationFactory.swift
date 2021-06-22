//
//  OperationFactory.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 18/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import os.log

/// Class responsible for creating operations necessary to perform a given action, and converting those operations into the single payload expected by the RPC.
/// Although not every action requires more than one operation, all functions will return an array, for consistency.
public class OperationFactory {
	
	
	// MARK: - Operation Builders
	
	/**
	Create the operations necessary to send an amount of a token to a destination address.
	- parameter _: The amount of the given token to send.
	- parameter of: The `Token` type that will be sent.
	- parameter from: The address to deduct the funds from.
	- parameter to: The destination address that will recieve the funds.
	- returns: An array of `Operation` subclasses.
	*/
	public static func sendOperation(_ tokenAmount: TokenAmount, of token: Token, from: String, to: String) -> [Operation] {
		
		// Return empty array if `TokenAmount` is a negaitve value
		if tokenAmount < TokenAmount.zeroBalance(decimalPlaces: tokenAmount.decimalPlaces) {
			os_log(.error, log: .kukaiCoreSwift, "Negative value passed to OperationFactory.sendOperation")
			return []
		}
		
		// Process different token types
		switch token.tokenType {
			case .xtz:
				return [OperationTransaction(amount: tokenAmount, source: from, destination: to)]
			
			case .fungible:
				let entrypoint = OperationSmartContractInvocation.StandardEntrypoint.transfer.rawValue
				
				let tokenAmountMichelson = MichelsonFactory.createInt(tokenAmount)
				let destinationMicheslon = MichelsonFactory.createString(to)
				let innerPair = MichelsonPair(args: [destinationMicheslon, tokenAmountMichelson])
				let sourceMichelson = MichelsonFactory.createString(from)
				let michelson = MichelsonPair(args: [sourceMichelson, innerPair])
				
				return [OperationSmartContractInvocation(source: from, destinationContract: token.tokenContractAddress ?? "", entrypoint: entrypoint, value: michelson)]
			
			case .nonfungible:
				// TODO: implement
				return []
		}
	}
	
	/**
	Create the operations necessary to delegate funds to a baker.
	- parameter to: The address of the baker to delegate to.
	- parameter from: The address that wishes to delegate its funds.
	- returns: An array of `Operation` subclasses.
	*/
	public static func delegateOperation(to: String, from: String) -> [Operation] {
		return [OperationDelegation(source: from, delegate: to)]
	}
	
	/**
	Create the operations necessary to remove the current delegate from an address.
	- parameter address: The address that wishes to remove its delegate.
	- returns: An array of `Operation` subclasses.
	*/
	public static func undelegateOperation(address: String) -> [Operation] {
		return [OperationDelegation(source: address, delegate: nil)]
	}
	
	/*
	/**
	Create the operations necessary to perform an exchange of XTZ for a given FA token, using Dexter
	- parameter xxxxx: yyyyy
	- returns: An array of `Operation` subclasses.
	*/
	public static func dexterXtzToToken(xtzAmount: XTZAmount, minTokenAmount: TokenAmount, token: Token, wallet: Wallet, timeout: TimeInterval) -> [Operation] {
		
		let entrypoint = OperationSmartContractInvocation.StandardEntrypoint.xtzToToken.rawValue
		let dateString = createDexterTimestampString(nowPlusTimeInterval: timeout)
		
		let timestampMichelson = MichelsonFactory.createString(dateString)
		let minTokensToBuyMichelson = MichelsonFactory.createInt(minTokenAmount)
		let innerPair = MichelsonPair(args: [minTokensToBuyMichelson, timestampMichelson])
		let destinationMichelson = MichelsonFactory.createString(wallet.address)
		let michelson = MichelsonPair (args: [destinationMichelson, innerPair])
		
		return [OperationSmartContractInvocation(source: wallet.address, amount: xtzAmount, destinationContract: token.dexterExchangeAddress ?? "", entrypoint: entrypoint, value: michelson)]
	}
	
	/**
	Create the operations necessary to perform an exchange of a given FA token for XTZ, using Dexter
	- parameter xxxxx: yyyyy
	- returns: An array of `Operation` subclasses.
	*/
	public static func dexterTokenToXTZ(tokenAmount: TokenAmount, minXTZAmount: XTZAmount, token: Token, currentAllowance: TokenAmount, wallet: Wallet, timeout: TimeInterval) -> [Operation] {
		guard let tokenAddress = token.tokenContractAddress, let dexterAddress = token.dexterExchangeAddress else {
			os_log(.error, log: .kukaiCoreSwift, "Token `%@` doesn't have a `tokenContractAddress` and/or `dexterExchangeAddress`", token.symbol)
			return []
		}
		
		let entrypoint = OperationSmartContractInvocation.StandardEntrypoint.tokenToXtz.rawValue
		let dateString = createDexterTimestampString(nowPlusTimeInterval: timeout)
		
		
		// If the current allowance is zero, set the allowance tot he amount we are trying to send.
		// Else, for secuirty, we must set the allowance to zero, then set the allwaonce to what we need.
		var operations: [Operation] = []
		if currentAllowance.toRpcDecimal() ?? 0 > 0 {
			operations = [
				dexterAllowanceOperation(tokenAddress: tokenAddress, spenderAddress: dexterAddress, allowance: TokenAmount.zeroBalance(decimalPlaces: 0), wallet: wallet),
				dexterAllowanceOperation(tokenAddress: tokenAddress, spenderAddress: dexterAddress, allowance: tokenAmount, wallet: wallet)
			]
			
		} else {
			operations = [ dexterAllowanceOperation(tokenAddress: tokenAddress, spenderAddress: dexterAddress, allowance: tokenAmount, wallet: wallet) ]
		}
		
		// Create the michelson
		let timestampMichelson = MichelsonFactory.createString(dateString)
		let minMutezToBuyMichelson = MichelsonFactory.createInt(minXTZAmount)
		let tokensToSellMichelson = MichelsonFactory.createInt(tokenAmount)
		let amountInnerPair = MichelsonPair(args: [minMutezToBuyMichelson, timestampMichelson])
		let amountPair = MichelsonPair(args: [tokensToSellMichelson, amountInnerPair])
		
		let destinationMichelson = MichelsonFactory.createString(wallet.address)
		let ownerMichelson = MichelsonFactory.createString(wallet.address)
		let addressPair = MichelsonPair(args: [ownerMichelson, destinationMichelson])
		
		let michelson = MichelsonPair(args: [addressPair, amountPair])
		
		
		// Add the last operation to perform the swap
		operations.append(OperationSmartContractInvocation(source: wallet.address, destinationContract: token.dexterExchangeAddress ?? "", entrypoint: entrypoint, value: michelson))
		
		return operations
	}
	
	/// Not implmented yet
	public static func dexterTokenToToken() -> [Operation] {
		return []
	}
	*/

	/**
	Create the operations necessary to register an allowance, allowing another address to send FA tokens on your behalf.
	Used when interacting with smart contract applications like Dexter or QuipuSwap
	- parameter xxxxx: yyyyy
	- returns: An array of `Operation` subclasses.
	*/
	public static func allowanceOperation(tokenAddress: String, spenderAddress: String, allowance: TokenAmount, wallet: Wallet) -> Operation {
		let entrypoint = OperationSmartContractInvocation.StandardEntrypoint.approve.rawValue
		
		let spenderMichelson = MichelsonFactory.createString(spenderAddress)
		let allowanceMichelson = MichelsonFactory.createInt(allowance)
		let michelson = MichelsonPair(args: [spenderMichelson, allowanceMichelson])
		
		return OperationSmartContractInvocation(source: wallet.address, destinationContract: tokenAddress, entrypoint: entrypoint, value: michelson)
	}
	
	
	
	// MARK: - Utilities
	
	/**
	Convert an array of operations into the format expected by the RPC. Will also inject a `OperationReveal` if the sender has not yet revealed their public key.
	- parameter fromMetadata: `OperationMeatdata` containing necessary data to form the object.
	- parameter andOperations: An array of `Operation` subclasses to send.
	- parameter withWallet: The `Wallet` instance that will be responsible for these operations.
	- returns: An instance of `OperationPayload` that can be sent to the RPC
	*/
	public static func operationPayload(fromMetadata metadata: OperationMetadata, andOperations operations: [Operation], withWallet wallet: Wallet) -> OperationPayload {
		var ops = operations
		
		// If theres no manager key, we need to add a reveal operation first (unless one has been added already, such as from an estimation)
		// Also ignore the need for a reveal if we are activating an account
		if metadata.managerKey == nil && operations.first?.operationKind != .reveal && operations.first?.operationKind != .activate_account {
			ops.insert(OperationReveal(wallet: wallet), at: 0)
		}
		
		// Add the counters to the operations
		if operations.first?.operationKind != .activate_account {
			var opCounter = metadata.counter
			for op in ops {
				opCounter += 1
				op.counter = "\(opCounter)"
			}
		}
		
		// return the structure the RPC is expecting to see
		return OperationPayload(branch: metadata.branch, contents: ops)
	}
	
	/**
	Dexter requires date strings to act as deadline dates for exchanges.
	This function takes a `TimeInterval` and uses it to createa date in the future, and returns that as a formatted string.
	- parameter nowPlusTimeInterval: The amount of time in the future the date string should represent.
	- returns: A formatted date `String`
	*/
	public static func createDexterTimestampString(nowPlusTimeInterval: TimeInterval) -> String {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
		dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
		dateFormatter.locale = Locale(identifier: "en_US_POSIX")
		
		return dateFormatter.string(from: Date().addingTimeInterval(nowPlusTimeInterval))
	}
}
