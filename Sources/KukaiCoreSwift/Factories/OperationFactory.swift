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
	
	/**
	Create the operations necessary to perform an exchange of XTZ for a given FA token, using liquidity baking contracts
	- parameter xtzAmount: The amount of XTZ to be swaped
	- parameter minTokenAmount: The minimum token amount you will accept
	- parameter contract: The address of the swap contract
	- parameter wallet: The wallet signing the operation
	- parameter timeout: Max amount of time to wait before asking the node to cancel the operation
	- returns: An array of `Operation` subclasses.
	*/
	public static func liquidityBakingXtzToToken(xtzAmount: XTZAmount, minTokenAmount: TokenAmount, dexContract: String, wallet: Wallet, timeout: TimeInterval) -> [Operation] {
		
		let entrypoint = OperationSmartContractInvocation.StandardEntrypoint.xtzToToken.rawValue
		let dateString = createDexterTimestampString(nowPlusTimeInterval: timeout)
		
		let timestampMichelson = MichelsonFactory.createString(dateString)
		let minTokensToBuyMichelson = MichelsonFactory.createInt(minTokenAmount)
		let destinationMichelson = MichelsonFactory.createString(wallet.address)
		let michelson = MichelsonPair (args: [destinationMichelson, minTokensToBuyMichelson, timestampMichelson])
		
		return [OperationSmartContractInvocation(source: wallet.address, amount: xtzAmount, destinationContract: dexContract, entrypoint: entrypoint, value: michelson)]
	}
	
	/**
	Create the operations necessary to perform an exchange of a given FA token for XTZ, using liquidity baking contracts
	- parameter tokenAmount: The amount of Token to be swapped
	- parameter minXTZAmount: The minimum xtz amount you will accept
	- parameter contract: The address of the swap contract
	- parameter tokenContract: The address of the returned token
	- parameter currentAllowance: The users current approved allowance to spend
	- parameter wallet: The wallet signing the operation
	- parameter timeout: Max amount of time to wait before asking the node to cancel the operation
	- returns: An array of `Operation` subclasses.
	*/
	public static func liquidityBakingTokenToXTZ(tokenAmount: TokenAmount, minXTZAmount: XTZAmount, dexContract: String, tokenContract: String, currentAllowance: TokenAmount, wallet: Wallet, timeout: TimeInterval) -> [Operation] {
		let entrypoint = OperationSmartContractInvocation.StandardEntrypoint.tokenToXtz.rawValue
		let dateString = createDexterTimestampString(nowPlusTimeInterval: timeout)
		
		
		// If the current allowance is zero, set the allowance tot he amount we are trying to send.
		// Else, for secuirty, we must set the allowance to zero, then set the allwaonce to what we need.
		var operations: [Operation] = []
		if currentAllowance.toRpcDecimal() ?? 0 > 0 {
			operations = [
				allowanceOperation(tokenAddress: tokenContract, spenderAddress: dexContract, allowance: TokenAmount.zeroBalance(decimalPlaces: 0), wallet: wallet),
				allowanceOperation(tokenAddress: tokenContract, spenderAddress: dexContract, allowance: tokenAmount, wallet: wallet)
			]
			
		} else {
			operations = [ allowanceOperation(tokenAddress: tokenContract, spenderAddress: dexContract, allowance: tokenAmount, wallet: wallet) ]
		}
		
		// Create the michelson
		let timestampMichelson = MichelsonFactory.createString(dateString)
		let minMutezToBuyMichelson = MichelsonFactory.createInt(minXTZAmount)
		let tokensToSellMichelson = MichelsonFactory.createInt(tokenAmount)
		let destinationMichelson = MichelsonFactory.createString(wallet.address)
		let michelson = MichelsonPair(args: [destinationMichelson, tokensToSellMichelson, minMutezToBuyMichelson, timestampMichelson])
		
		
		// Add the last operation to perform the swap
		operations.append(OperationSmartContractInvocation(source: wallet.address, destinationContract: dexContract, entrypoint: entrypoint, value: michelson))
		
		return operations
	}
	
	/**
	Create the operations necessary to register an allowance, allowing another address to send FA tokens on your behalf.
	Used when interacting with smart contract applications like Dexter or QuipuSwap
	- parameter tokenAddress: The address of the token contract
	- parameter spenderAddress: The address that is being given permission to spend the users balance
	- parameter allowance: The allowance to set for the given contract
	- parameter wallet: The wallet signing the operation
	- returns: An array of `Operation` subclasses.
	*/
	public static func allowanceOperation(tokenAddress: String, spenderAddress: String, allowance: TokenAmount, wallet: Wallet) -> Operation {
		let entrypoint = OperationSmartContractInvocation.StandardEntrypoint.approve.rawValue
		
		let spenderMichelson = MichelsonFactory.createString(spenderAddress)
		let allowanceMichelson = MichelsonFactory.createInt(allowance)
		let michelson = MichelsonPair(args: [spenderMichelson, allowanceMichelson])
		
		return OperationSmartContractInvocation(source: wallet.address, destinationContract: tokenAddress, entrypoint: entrypoint, value: michelson)
	}
	
	/**
	TODO:
	- parameter _:
	- returns: An array of `Operation` subclasses.
	*/
	public static func liquidityBakingAddLiquidity(xtzToDeposit: XTZAmount, tokensToDeposit: TokenAmount, minLiquidtyMinted: TokenAmount, tokenContract: String, dexContract: String, currentAllowance: TokenAmount, wallet: Wallet, timeout: TimeInterval) -> [Operation] {
		
		let entrypoint = OperationSmartContractInvocation.StandardEntrypoint.addLiquidity.rawValue
		let dateString = createDexterTimestampString(nowPlusTimeInterval: timeout)
		
		
		// If the current allowance is zero, set the allowance tot he amount we are trying to send.
		// Else, for secuirty, we must set the allowance to zero, then set the allwaonce to what we need.
		var operations: [Operation] = []
		if currentAllowance.toRpcDecimal() ?? 0 > 0 {
			operations = [
				allowanceOperation(tokenAddress: tokenContract, spenderAddress: dexContract, allowance: TokenAmount.zeroBalance(decimalPlaces: 0), wallet: wallet),
				allowanceOperation(tokenAddress: tokenContract, spenderAddress: dexContract, allowance: tokensToDeposit, wallet: wallet)
			]
			
		} else {
			operations = [ allowanceOperation(tokenAddress: tokenContract, spenderAddress: dexContract, allowance: tokensToDeposit, wallet: wallet) ]
		}
		
		let timestampMichelson = MichelsonFactory.createString(dateString)
		let token = MichelsonFactory.createInt(tokensToDeposit)
		let lqt = MichelsonFactory.createInt(minLiquidtyMinted)
		let owner = MichelsonFactory.createString(wallet.address)
		let michelson = MichelsonPair (args: [owner, lqt, token, timestampMichelson])
		
		operations.append(OperationSmartContractInvocation(source: wallet.address, amount: xtzToDeposit, destinationContract: dexContract, entrypoint: entrypoint, value: michelson))
		
		return operations
	}
	
	/**
	TODO:
	- parameter _:
	- returns: An array of `Operation` subclasses.
	*/
	public static func liquidityBakingRemoveLiquidity(minXTZ: XTZAmount, minToken: TokenAmount, liquidityToBurn: TokenAmount, dexContract: String, wallet: Wallet, timeout: TimeInterval) -> [Operation] {
		
		let entrypoint = OperationSmartContractInvocation.StandardEntrypoint.removeLiquidity.rawValue
		let dateString = createDexterTimestampString(nowPlusTimeInterval: timeout)
		
		let timestampMichelson = MichelsonFactory.createString(dateString)
		let xtz = MichelsonFactory.createInt(minXTZ)
		let token = MichelsonFactory.createInt(minToken)
		let lqt = MichelsonFactory.createInt(liquidityToBurn)
		let destination = MichelsonFactory.createString(wallet.address)
		let michelson = MichelsonPair (args: [destination, lqt, xtz, token, timestampMichelson])
		
		return [OperationSmartContractInvocation(source: wallet.address, amount: XTZAmount.zero(), destinationContract: dexContract, entrypoint: entrypoint, value: michelson)]
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
