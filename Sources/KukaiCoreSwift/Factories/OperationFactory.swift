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
				let michelson = sendTokenMichelson(forFaVersion: token.faVersion ?? .fa1_2, tokenAmount: tokenAmount, tokenId: token.tokenId ?? 0, to: to, from: from)
				
				if (token.faVersion ?? .fa1_2) == .fa1_2 {
					return [OperationTransaction(amount: TokenAmount.zero(), source: from, destination: token.tokenContractAddress ?? "", parameters: michelson)]
					
				} else {
					return [OperationTransaction(amount: TokenAmount.zero(), source: from, destination: token.tokenContractAddress ?? "", parameters: michelson)]
				}
			
			case .nonfungible:
				// Can't send an entire NFT group, need to rethink this
				os_log(.error, log: .kukaiCoreSwift, "Can't send an entire NFT group. Must send individual NFT's from token.nfts array, via the other sendOperation")
				return []
		}
	}
	
	/**
	 Create the operations necessary to send aan NFT
	 - parameter : The amount of the given token to send.
	 - parameter ofNft: The `NFT` type that will be sent.
	 - parameter from: The address to deduct the funds from.
	 - parameter to: The destination address that will recieve the funds.
	 - returns: An array of `Operation` subclasses.
	 */
	public static func sendOperation(_ amount: Decimal, ofNft nft: NFT, from: String, to: String) -> [Operation] {
		
		// Return empty array if `amount` is a negaitve value
		if amount < 0 {
			os_log(.error, log: .kukaiCoreSwift, "Negative value passed to OperationFactory.sendOperation")
			return []
		}
		
		let michelson = sendTokenMichelson(forFaVersion: nft.faVersion, tokenAmount: TokenAmount(fromNormalisedAmount: amount, decimalPlaces: nft.decimalPlaces), tokenId: nft.tokenId, to: to, from: from)
		
		return [OperationTransaction(amount: TokenAmount.zero(), source: from, destination: nft.parentContract, parameters: michelson)]
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
	Create the operations necessary to perform an exchange of XTZ for a given FA token, using a given dex
	- parameter withDex: Enum controling which dex to use to perform the swap
	- parameter xtzAmount: The amount of XTZ to be swaped
	- parameter minTokenAmount: The minimum token amount you will accept
	- parameter wallet: The wallet signing the operation
	- parameter timeout: Max amount of time to wait before asking the node to cancel the operation
	- returns: An array of `Operation` subclasses.
	*/
	public static func swapXtzToToken(withDex dex: DipDupExchange, xtzAmount: XTZAmount, minTokenAmount: TokenAmount, walletAddress: String, timeout: TimeInterval) -> [Operation] {
		
		switch dex.name {
			case .quipuswap:
				let swapData = xtzToToken_quipu_michelsonEntrypoint(minTokenAmount: minTokenAmount, walletAddress: walletAddress)
				return [OperationTransaction(amount: xtzAmount, source: walletAddress, destination: dex.address, parameters: swapData)]
				
			case .lb:
				let swapData = xtzToToken_lb_michelsonEntrypoint(minTokenAmount: minTokenAmount, walletAddress: walletAddress, timeout: timeout)
				return [OperationTransaction(amount: xtzAmount, source: walletAddress, destination: dex.address, parameters: swapData)]
				
			case .unknown:
				return []
		}
	}
	
	/**
	Create the operations necessary to perform an exchange of a given FA token for XTZ, using dex contracts
	- parameter withDex: `DipDupExchange` instance providing information about the exchange
	- parameter tokenAmount: The amount of Token to be swapped
	- parameter minXTZAmount: The minimum xtz amount you will accept
	- parameter wallet: The wallet signing the operation
	- parameter timeout: Max amount of time to wait before asking the node to cancel the operation
	- returns: An array of `Operation` subclasses.
	*/
	public static func swapTokenToXTZ(withDex dex: DipDupExchange, tokenAmount: TokenAmount, minXTZAmount: XTZAmount, walletAddress: String, timeout: TimeInterval) -> [Operation] {
		var operations: [Operation] = [
			allowanceOperation(standard: dex.token.standard, tokenAddress: dex.token.address, spenderAddress: dex.address, allowance: TokenAmount.zeroBalance(decimalPlaces: 0), walletAddress: walletAddress),
			allowanceOperation(standard: dex.token.standard, tokenAddress: dex.token.address, spenderAddress: dex.address, allowance: tokenAmount, walletAddress: walletAddress)
		]
		
		// Create entrypoint and michelson data depening on type of dex
		switch dex.name {
			case .quipuswap:
				let swapData = tokenToXtz_quipu_michelsonEntrypoint(tokenAmount: tokenAmount, minXTZAmount: minXTZAmount, walletAddress: walletAddress)
				operations.append(OperationTransaction(amount: TokenAmount.zero(), source: walletAddress, destination: dex.address, parameters: swapData))
				
			case .lb:
				let swapData = tokenToXtz_lb_michelsonEntrypoint(tokenAmount: tokenAmount, minXTZAmount: minXTZAmount, walletAddress: walletAddress, timeout: timeout)
				operations.append(OperationTransaction(amount: TokenAmount.zero(), source: walletAddress, destination: dex.address, parameters: swapData))
				
			case .unknown:
				return []
		}
		
		// Add a trailing approval operation
		operations.append(allowanceOperation(standard: dex.token.standard, tokenAddress: dex.token.address, spenderAddress: dex.address, allowance: TokenAmount.zeroBalance(decimalPlaces: 0), walletAddress: walletAddress))
		
		return operations
	}
	
	
	
	// MARK: - Allowance (approve, update_operators)
	
	/**
	Create an operation to call the entrypoint `approve`, to allow another address to spend some of your token (only FA1.2)
	Used when interacting with smart contract applications like Dexter or QuipuSwap
	- parameter tokenAddress: The address of the token contract
	- parameter spenderAddress: The address that is being given permission to spend the users balance
	- parameter allowance: The allowance to set for the given contract
	- parameter wallet: The wallet signing the operation
	 - returns: An `OperationTransaction` which will invoke a smart contract call
	*/
	public static func approveOperation(tokenAddress: String, spenderAddress: String, allowance: TokenAmount, walletAddress: String) -> Operation {
		let params: [String: Any] = [
			"entrypoint": OperationTransaction.StandardEntrypoint.approve.rawValue,
			"value": ["prim":"Pair", "args":[["string":spenderAddress], ["int":allowance.rpcRepresentation]]]
		]
		
		return OperationTransaction(amount: TokenAmount.zero(), source: walletAddress, destination: tokenAddress, parameters: params)
	}
	
	/**
	 Create an operation to call the entrypoint `update_operators`, to allow another address to spend some of your token (only FA2)
	 Used when interacting with smart contract applications like Dexter or QuipuSwap
	 - parameter tokenAddress: The address of the token contract
	 - parameter spenderAddress: The address that is being given permission to spend the users balance
	 - parameter allowance: The allowance to set for the given contract
	 - parameter wallet: The wallet signing the operation
	 - returns: An `OperationTransaction` which will invoke a smart contract call
	 */
	public static func updateOperatorsOperation(tokenAddress: String, spenderAddress: String, allowance: TokenAmount, walletAddress: String) -> Operation {
		let params: [String: Any] = [
			"entrypoint": OperationTransaction.StandardEntrypoint.updateOperators.rawValue,
			"value": [["prim": "Left","args": [["prim": "Pair","args": [["string": walletAddress], ["prim": "Pair","args": [["string": spenderAddress], ["int": allowance.rpcRepresentation]]]]]]]]
		]
		
		return OperationTransaction(amount: TokenAmount.zero(), source: walletAddress, destination: tokenAddress, parameters: params)
	}
	
	/**
	 Return the operation necessary to register an allowance (either calling `apporve` or `update_operators`) depending on the token standard version. Removing the need to check manually
	 Used when interacting with smart contract applications like Dexter or QuipuSwap
	 - parameter standard: The FA standard that the token conforms too
	 - parameter tokenAddress: The address of the token contract
	 - parameter spenderAddress: The address that is being given permission to spend the users balance
	 - parameter allowance: The allowance to set for the given contract
	 - parameter wallet: The wallet signing the operation
	 - returns: An `OperationTransaction` which will invoke a smart contract call
	 */
	public static func allowanceOperation(standard: DipDupTokenStandard, tokenAddress: String, spenderAddress: String, allowance: TokenAmount, walletAddress: String) -> Operation {
		
		switch standard {
			case .fa12:
				return approveOperation(tokenAddress: tokenAddress, spenderAddress: spenderAddress, allowance: allowance, walletAddress: walletAddress)
				
			case .fa2:
				return updateOperatorsOperation(tokenAddress: tokenAddress, spenderAddress: spenderAddress, allowance: allowance, walletAddress: walletAddress)
				
			case .unknown:
				return approveOperation(tokenAddress: tokenAddress, spenderAddress: spenderAddress, allowance: allowance, walletAddress: walletAddress)
		}
	}
	
	
	
	// MARK: - Dex functions
	
	/**
	Create the operations necessary to add liquidity to a dex contract. Use DexCalculationService to figure out the numbers required
	- parameter withDex: `DipDupExchange` instance providing information about the exchange
	- parameter xtz: The amount of XTZ to deposit
	- parameter token: The amount of Token to deposit
	- parameter minLiquidty: The minimum amount of liquidity tokens you will accept
	- parameter isInitialLiquidity: Is this the xtzPool and tokenPool empty? If so, the operation needs to set the exchange rate for the dex. Some dex's require extra logic here
	- parameter wallet: The wallet that will sign the operation
	- parameter timeout: The timeout in seconds, before the dex contract should cancel the operation
	- returns: An array of `Operation` subclasses.
	*/
	public static func addLiquidity(withDex dex: DipDupExchange, xtz: XTZAmount, token: TokenAmount, minLiquidty: TokenAmount, isInitialLiquidity: Bool, walletAddress: String, timeout: TimeInterval) -> [Operation] {
		var operations: [Operation] = [
			allowanceOperation(standard: dex.token.standard, tokenAddress: dex.token.address, spenderAddress: dex.address, allowance: TokenAmount.zeroBalance(decimalPlaces: 0), walletAddress: walletAddress),
			allowanceOperation(standard: dex.token.standard, tokenAddress: dex.token.address, spenderAddress: dex.address, allowance: token, walletAddress: walletAddress)
		]
		
		// Create entrypoint and michelson data depening on type of dex
		switch dex.name {
			case .quipuswap:
				let swapData = addLiquidity_quipu_michelsonEntrypoint(xtzToDeposit: xtz, tokensToDeposit: token, isInitialLiquidity: isInitialLiquidity)
				operations.append(OperationTransaction(amount: xtz, source: walletAddress, destination: dex.address, parameters: swapData))
				
			case .lb:
				let swapData = addLiquidity_lb_michelsonEntrypoint(xtzToDeposit: xtz, tokensToDeposit: token, minLiquidtyMinted: minLiquidty, walletAddress: walletAddress, timeout: timeout)
				operations.append(OperationTransaction(amount: xtz, source: walletAddress, destination: dex.address, parameters: swapData))
				
			case .unknown:
				return []
		}
		
		// Add a trailing approval operation
		operations.append(allowanceOperation(standard: dex.token.standard, tokenAddress: dex.token.address, spenderAddress: dex.address, allowance: TokenAmount.zeroBalance(decimalPlaces: 0), walletAddress: walletAddress))
		
		return operations
	}
	
	/**
	Create the operations necessary to remove liquidity from a dex contract, also withdraw pending rewards if applicable. Use DexCalculationService to figure out the numbers required
	- parameter withDex: `DipDupExchange` instance providing information about the exchange
	- parameter minXTZ: The minimum XTZ to accept in return for the burned amount of Liquidity
	- parameter minToken: The minimum Token to accept in return for the burned amount of Liquidity
	- parameter liquidityToBurn: The amount of Liqudity to burn
	- parameter wallet: The wallet that will sign the operation
	- parameter timeout: The timeout in seconds, before the dex contract should cancel the operation
	- returns: An array of `Operation` subclasses.
	*/
	public static func removeLiquidity(withDex dex: DipDupExchange, minXTZ: XTZAmount, minToken: TokenAmount, liquidityToBurn: TokenAmount, walletAddress: String, timeout: TimeInterval) -> [Operation] {
		switch dex.name {
			case .quipuswap:
				let swapData = removeLiquidity_quipu_michelsonEntrypoint(minXTZ: minXTZ, minToken: minToken, liquidityToBurn: liquidityToBurn)
				var removeAndWithdrawOperations: [Operation] = [OperationTransaction(amount: XTZAmount.zero(), source: walletAddress, destination: dex.address, parameters: swapData)]
				removeAndWithdrawOperations.append(contentsOf: withdrawRewards(withDex: dex, walletAddress: walletAddress))
				return removeAndWithdrawOperations
				
			case .lb:
				let swapData = removeLiquidity_lb_michelsonEntrypoint(minXTZ: minXTZ, minToken: minToken, liquidityToBurn: liquidityToBurn, walletAddress: walletAddress, timeout: timeout)
				return [OperationTransaction(amount: XTZAmount.zero(), source: walletAddress, destination: dex.address, parameters: swapData)]
				
			case .unknown:
				return []
		}
	}
	
	/**
	 Create the operations necessary to withdraw rewards from a dex contract. For example in quipuswap, XTZ provided as liquidity will earn baking rewards. This can been withdrawn at any time while leaving liquidity in palce
	 - parameter withDex: `DipDupExchange` instance providing information about the exchange
	 - parameter wallet: The wallet that will sign the operation
	 - returns: An array of `Operation` subclasses.
	 */
	public static func withdrawRewards(withDex dex: DipDupExchange, walletAddress: String) -> [Operation] {
		switch dex.name {
			case .quipuswap:
				let swapData = withdrawRewards_quipu_michelsonEntrypoint(walletAddress: walletAddress)
				return [OperationTransaction(amount: XTZAmount.zero(), source: walletAddress, destination: dex.address, parameters: swapData)]
				
			case .lb:
				return []
				
			case .unknown:
				return []
		}
	}
	
	
	
	// MARK: - Utilities
	
	/**
	Convert an array of operations into the format expected by the RPC. Will also inject a `OperationReveal` if the sender has not yet revealed their public key.
	- parameter fromMetadata: `OperationMeatdata` containing necessary data to form the object.
	- parameter andOperations: An array of `Operation` subclasses to send.
	- parameter withWallet: The `Wallet` instance that will be responsible for these operations.
	- returns: An instance of `OperationPayload` that can be sent to the RPC
	*/
	public static func operationPayload(fromMetadata metadata: OperationMetadata, andOperations operations: [Operation], walletAddress: String, base58EncodedPublicKey: String) -> OperationPayload {
		var ops = operations
		
		// If theres no manager key, we need to add a reveal operation first (unless one has been added already, such as from an estimation)
		// Also ignore the need for a reveal if we are activating an account
		if metadata.managerKey == nil && operations.first?.operationKind != .reveal && operations.first?.operationKind != .activate_account {
			ops.insert(OperationReveal(base58EncodedPublicKey: base58EncodedPublicKey, walletAddress: walletAddress), at: 0)
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
	
	public static func sendTokenMichelson(forFaVersion faVersion: FaVersion, tokenAmount: TokenAmount, tokenId: Decimal, to: String, from: String) -> [String: Any] {
		switch faVersion {
			case .fa1_2, .unknown:
				return [
					"entrypoint": OperationTransaction.StandardEntrypoint.transfer.rawValue,
					"value": ["prim":"Pair","args":[["string":from], ["prim":"Pair","args":[["string":to], ["int":tokenAmount.rpcRepresentation]]]]]
				]
				
			case .fa2:
				return [
					"entrypoint": OperationTransaction.StandardEntrypoint.transfer.rawValue,
					"value": [["prim":"Pair","args":[["string":from], [["prim":"Pair","args":[["string":to], ["prim":"Pair","args":[["int":"\(tokenId)"], ["int":tokenAmount.rpcRepresentation]]]]]]]]]
				]
		}
	}
	
	
	
	// MARK: - Extractors
	
	public struct Extractor {
		
		/**
		 Extract rpc amount (without decimal info)  and a tokenId from a michelson FA1.2 / FA2 trasfer payload
		 */
		public static func tokenIdAndAmountFromSendMichelson(michelson: Any) -> (rpcAmount: String, tokenId: Decimal?)? {
			if let michelsonDict = michelson as? [String: Any] {
				// FA1.2
				let rpcAmountString = michelsonDict.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
				
				if let str = rpcAmountString {
					return (rpcAmount: str, tokenId: nil)
				} else {
					return nil
				}
				
			} else if let michelsonArray = michelson as? [[String: Any]] {
				// FA2
				
				let argsArray = michelsonArray[0].michelsonArgsUnknownArray()?.michelsonArray(atIndex: 1)?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()
				let rpcAmountString = argsArray?.michelsonInt(atIndex: 1)
				let tokenId = argsArray?.michelsonInt(atIndex: 0)
				
				if let str = rpcAmountString, let tId = tokenId {
					return (rpcAmount: str, tokenId: Decimal(string: tId))
				} else {
					return nil
				}
				
			} else {
				return nil
			}
		}
		
		/**
		 Extract details form a payload in order to present to the user what it is they are trying to send
		 */
		public static func faTokenDetailsFrom(transaction: OperationTransaction) -> (tokenContract: String, rpcAmount: String, tokenId: Decimal?)? {
			if let params = transaction.parameters, let amountAndId = OperationFactory.Extractor.tokenIdAndAmountFromSendMichelson(michelson: params["value"] ?? []) {
				let tokenContractAddress = transaction.destination
				return (tokenContract: tokenContractAddress, rpcAmount: amountAndId.rpcAmount, tokenId: amountAndId.tokenId)
			}
			
			return nil
		}
		
		/**
		 Helper to  call `faTokenDetailsFrom(transaction: OperationTransaction)` on the first `OperationTransaction` in an array of operations. Allows to more easily parse an array of operations that may include `approval`'s or `update_operator` calls
		 */
		public static func faTokenDetailsFrom(operations: [Operation]) -> (tokenContract: String, rpcAmount: String, tokenId: Decimal?)? {
			if let op = operations.first(where: { $0 is OperationTransaction }) as? OperationTransaction {
				return OperationFactory.Extractor.faTokenDetailsFrom(transaction: op)
			}
			
			return nil
		}
	}
	
	
	
	// MARK: - Private helpers
	
	
	
	// MARK: - xtzToToken
	
	private static func xtzToToken_lb_michelsonEntrypoint(minTokenAmount: TokenAmount, walletAddress: String, timeout: TimeInterval) -> [String: Any] {
		let dateString = createDexterTimestampString(nowPlusTimeInterval: timeout)
		
		return [
			"entrypoint": OperationTransaction.StandardEntrypoint.xtzToToken.rawValue,
			"value": ["prim":"Pair", "args":[["string":walletAddress], ["prim":"Pair", "args":[["int":minTokenAmount.rpcRepresentation], ["string":dateString]]]]]
		]
	}
	
	private static func xtzToToken_quipu_michelsonEntrypoint(minTokenAmount: TokenAmount, walletAddress: String) -> [String: Any] {
		
		return [
			"entrypoint": OperationTransaction.StandardEntrypoint.tezToTokenPayment.rawValue,
			"value": ["prim": "Pair", "args": [["int": minTokenAmount.rpcRepresentation], ["string": walletAddress]]]
		]
	}
	
	
	
	// MARK: - tokenToXtz
	
	private static func tokenToXtz_lb_michelsonEntrypoint(tokenAmount: TokenAmount, minXTZAmount: XTZAmount, walletAddress: String, timeout: TimeInterval) -> [String: Any] {
		let dateString = createDexterTimestampString(nowPlusTimeInterval: timeout)
		return [
			"entrypoint": OperationTransaction.StandardEntrypoint.tokenToXtz.rawValue,
			"value": ["prim":"Pair", "args": [["string": walletAddress], ["prim": "Pair", "args": [["int": tokenAmount.rpcRepresentation], ["prim": "Pair", "args":[["int":minXTZAmount.rpcRepresentation], ["string": dateString]]]]]]]
		]
	}
	
	private static func tokenToXtz_quipu_michelsonEntrypoint(tokenAmount: TokenAmount, minXTZAmount: XTZAmount, walletAddress: String) -> [String: Any] {
		return [
			"entrypoint": OperationTransaction.StandardEntrypoint.tokenToTezPayment.rawValue,
			"value": ["prim": "Pair", "args": [["prim": "Pair", "args": [["int": tokenAmount.rpcRepresentation], ["int": minXTZAmount.rpcRepresentation]]], ["string": walletAddress]]]
		]
	}
	
	
	
	// MARK: - Add liquidity
	
	private static func addLiquidity_lb_michelsonEntrypoint(xtzToDeposit: XTZAmount, tokensToDeposit: TokenAmount, minLiquidtyMinted: TokenAmount, walletAddress: String, timeout: TimeInterval) -> [String: Any] {
		let dateString = createDexterTimestampString(nowPlusTimeInterval: timeout)
		
		return [
			"entrypoint": OperationTransaction.StandardEntrypoint.addLiquidity.rawValue,
			"value": ["prim": "Pair", "args": [["string":walletAddress], ["prim":"Pair", "args":[["int":minLiquidtyMinted.rpcRepresentation], ["prim":"Pair", "args":[["int":tokensToDeposit.rpcRepresentation], ["string":dateString]]]]]]]
		]
	}
	
	private static func addLiquidity_quipu_michelsonEntrypoint(xtzToDeposit: XTZAmount, tokensToDeposit: TokenAmount, isInitialLiquidity: Bool) -> [String: Any] {
		return [
			"entrypoint": OperationTransaction.StandardEntrypoint.investLiquidity.rawValue,
			"value": ["int": tokensToDeposit.rpcRepresentation]
		]
	}
	
	
	
	// MARK: - Remove liquidity
	
	private static func removeLiquidity_lb_michelsonEntrypoint(minXTZ: XTZAmount, minToken: TokenAmount, liquidityToBurn: TokenAmount, walletAddress: String, timeout: TimeInterval) -> [String: Any] {
		let liq = liquidityToBurn.rpcRepresentation
		let xtz = minXTZ.rpcRepresentation
		let token = minToken.rpcRepresentation
		let dateString = createDexterTimestampString(nowPlusTimeInterval: timeout)
		
		return [
			"entrypoint": OperationTransaction.StandardEntrypoint.removeLiquidity.rawValue,
			"value": ["prim":"Pair","args":[["string":walletAddress], ["prim":"Pair","args":[["int":liq], ["prim":"Pair","args":[["int":xtz], ["prim":"Pair","args":[["int":token], ["string":dateString]]]]]]]]]
		]
	}
	
	private static func removeLiquidity_quipu_michelsonEntrypoint(minXTZ: XTZAmount, minToken: TokenAmount, liquidityToBurn: TokenAmount) -> [String: Any] {
		return [
			"entrypoint": OperationTransaction.StandardEntrypoint.divestLiquidity.rawValue,
			"value": ["prim": "Pair", "args": [["prim": "Pair", "args": [["int": minXTZ.rpcRepresentation], ["int": minToken.rpcRepresentation]]], ["int": liquidityToBurn.rpcRepresentation]]]
		]
	}
	
	
	
	// MARK: - Withdraw
	
	private static func withdrawRewards_quipu_michelsonEntrypoint(walletAddress: String) -> [String: Any]  {
		return [
			"entrypoint": OperationTransaction.StandardEntrypoint.withdrawProfit.rawValue,
			"value": ["string": walletAddress]
		]
	}
}
