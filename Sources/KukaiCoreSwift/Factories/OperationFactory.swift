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
			Logger.kukaiCoreSwift.error("Negative value passed to OperationFactory.sendOperation")
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
				Logger.kukaiCoreSwift.error("Can't send an entire NFT group. Must send individual NFT's from token.nfts array, via the other sendOperation")
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
			Logger.kukaiCoreSwift.error("Negative value passed to OperationFactory.sendOperation")
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
	Create the operations necessary to stake an amount of XTZ
	- parameter from: The address that wishes to stake.
	- parameter amount: The XTZ amount to stake.
	- returns: An array of `Operation` subclasses.
	*/
	public static func stakeOperation(from: String, amount: TokenAmount) -> [Operation] {
		return [OperationTransaction(amount: amount, source: from, destination: from, parameters: ["entrypoint": "stake", "value": ["prim": "Unit"]])]
	}
	
	/**
	Create the operations necessary to unstake an amount of XTZ
	- parameter from: The address that wishes to unstake.
	- parameter amount: The XTZ amount to unstake.
	- returns: An array of `Operation` subclasses.
	*/
	public static func unstakeOperation(from: String, amount: TokenAmount) -> [Operation] {
		return [OperationTransaction(amount: amount, source: from, destination: from, parameters: ["entrypoint": "unstake", "value": ["prim": "Unit"]])]
	}
	
	/**
	Create the operations necessary to finalise and unstake operation
	- parameter from: The address that wishes to stake.
	- returns: An array of `Operation` subclasses.
	*/
	public static func finaliseUnstakeOperation(from: String) -> [Operation] {
		return [OperationTransaction(amount: .zero(), source: from, destination: from, parameters: ["entrypoint": "finalize_unstake", "value": ["prim": "Unit"]])]
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
	
	/*
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
	*/
	
	
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
			"value": ["prim":"Pair", "args":[["string":spenderAddress], ["int":allowance.rpcRepresentation]]] as [String : Any]
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
	public static func updateOperatorsOperation(tokenAddress: String, tokenId: String, spenderAddress: String, walletAddress: String) -> Operation {
		let params: [String: Any] = [
			"entrypoint": OperationTransaction.StandardEntrypoint.updateOperators.rawValue,
			"value": [["prim": "Left","args": [["prim": "Pair","args": [["string": walletAddress] as [String: Any], ["prim": "Pair","args": [["string": spenderAddress], ["int": tokenId]]]]] as [String : Any]]]] as [[String: Any]]
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
	public static func allowanceOperation(standard: DipDupTokenStandard, tokenAddress: String, tokenId: String?, spenderAddress: String, allowance: TokenAmount, walletAddress: String) -> Operation {
		
		switch standard {
			case .fa12:
				return approveOperation(tokenAddress: tokenAddress, spenderAddress: spenderAddress, allowance: allowance, walletAddress: walletAddress)
				
			case .fa2:
				return updateOperatorsOperation(tokenAddress: tokenAddress, tokenId: tokenId ?? "0", spenderAddress: spenderAddress, walletAddress: walletAddress)
				
			case .unknown:
				return approveOperation(tokenAddress: tokenAddress, spenderAddress: spenderAddress, allowance: allowance, walletAddress: walletAddress)
		}
	}
	
	
	
	// MARK: - Dex functions
	
	/*
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
	*/
	
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
					"value": ["prim":"Pair","args":[["string":from] as [String : Any], ["prim":"Pair","args":[["string":to], ["int":tokenAmount.rpcRepresentation]]]]] as [String : Any]
				]
				
			case .fa2:
				return [
					"entrypoint": OperationTransaction.StandardEntrypoint.transfer.rawValue,
					"value": [["prim":"Pair","args":[["string":from], [["prim":"Pair","args":[["string":to] as [String : Any], ["prim":"Pair","args":[["int":"\(tokenId)"], ["int":tokenAmount.rpcRepresentation]]]]] as [String : Any]]] as [Any]] as [String : Any]]
				]
		}
	}
	
	
	
	// MARK: - Extractors
	
	/// Internal Struct to encapsulate helpers methods needed to extract critical information from an array of operations, needed for processing decisions like "do i display a send token screen, or a send NFt screen", fetching total XTZ sent in 1 action etc
	public struct Extractor {
		
		/**
		 Filter reveal operation (if present), and check if what remains is a single OperationTransaction
		 Useful for other functions, such as checking if the list of operations is a single XTZ or token transfer
		 */
		public static func isSingleTransaction(operations: [Operation]) -> OperationTransaction? {
			let filteredOperations = filterReveal(operations: operations)
			if filteredOperations.count == 1, let op = filteredOperations.first as? OperationTransaction {
				return op
			}
			
			return nil
		}
		
		/**
		 Filter and verify only 1 transaction exists thats sending XTZ. If so return this operation, otherwise return false
		 */
		public static func isTezTransfer(operations: [Operation]) -> OperationTransaction? {
			if let op = isSingleTransaction(operations: operations), op.amount != "0", op.parameters == nil {
				return op
			}
			
			return nil
		}
		
		/**
		 Filter and verify only 1 transaction exists thats setting a baker. If so return this operation, otherwise return false
		 */
		public static func isDelegate(operations: [Operation]) -> OperationDelegation? {
			let filteredOperations = filterReveal(operations: operations)
			if filteredOperations.count == 1, let op = filteredOperations.first as? OperationDelegation {
				return op
			}
			
			return nil
		}
		
		/**
		 Filter and verify only 1 transaction exists thats sending a token. If so return this operation, otherwise return false
		 */
		public static func isFaTokenTransfer(operations: [Operation]) -> (operation: OperationTransaction, tokenContract: String, rpcAmount: String, tokenId: Decimal?, destination: String)? {
			if let op = isSingleTransaction(operations: operations), let details = faTokenDetailsFromTransfer(transaction: op) {
				return (operation: op, tokenContract: details.tokenContract, rpcAmount: details.rpcAmount, tokenId: details.tokenId, destination: details.destination)
			}
			
			return nil
		}
		
		/**
		 Filter and verify only 1 transaction exists its not a transfer operation. If so return this operation, otherwise return false
		 */
		public static func isSingleContractCall(operations: [Operation]) -> (operation: OperationTransaction, entrypoint: String, address: String)? {
			if let op = isSingleTransaction(operations: operations), let details = isNonTransferContractCall(operation: op) {
				return details
			}
			
			return nil
		}
		
		/**
		 Extract details from a transfer payload in order to present to the user what it is they are trying to send
		 */
		public static func faTokenDetailsFromTransfer(transaction: OperationTransaction) -> (tokenContract: String, rpcAmount: String, tokenId: Decimal?, destination: String)? {
			if let params = transaction.parameters, let amountAndId = OperationFactory.Extractor.tokenIdAndAmountFromTransferMichelson(michelson: params["value"] ?? [Any]()) {
				let tokenContractAddress = transaction.destination
				return (tokenContract: tokenContractAddress, rpcAmount: amountAndId.rpcAmount, tokenId: amountAndId.tokenId, destination: amountAndId.destination)
			}
			
			return nil
		}
		
		/**
		 Extract rpc amount (without decimal info) a tokenId, and the destination from a michelson `approve` value
		 */
		public static func tokenIdAndAmountFromApproveMichelson(michelson: Any) -> (rpcAmount: String, tokenId: Decimal?, destination: String)? {
			if let michelsonDict = michelson as? [String: Any] {
				let rpcAmountString = michelsonDict.michelsonArgsArray()?.michelsonInt(atIndex: 1)
				let rpcDestinationString = michelsonDict.michelsonArgsArray()?.michelsonString(atIndex: 0) ?? ""
				
				if let str = rpcAmountString {
					return (rpcAmount: str, tokenId: nil, destination: rpcDestinationString)
				} else {
					return nil
				}
			} else {
				return nil
			}
		}
		
		/**
		 Extract  a tokenId, and the destination from a michelson `update_operators` value
		 */
		public static func tokenIdFromUpdateOperatorsMichelson(michelson: Any) -> (tokenId: Decimal?, destination: String)? {
			if let michelsonArray = michelson as? [Any] {
				let argsArray1 = michelsonArray.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()
				let rpcDestination = argsArray1?.michelsonString(atIndex: 0)
				let rpcTokenIdString = argsArray1?.michelsonInt(atIndex: 1)
				
				if let str = rpcTokenIdString, let dest = rpcDestination {
					return (tokenId: Decimal(string: str), destination: dest)
				} else {
					return nil
				}
			} else {
				return nil
			}
		}
		
		/**
		 Extract rpc amount (without decimal info) michelson `execute` value for a 3route call
		 */
		public static func tokenAmountFromExecuteMichelson(michelson: Any, contract: String) -> Decimal? {
			
			if contract == "KT1R7WEtNNim3YgkxPt8wPMczjH3eyhbJMtz", let michelsonDict = michelson as? [String: Any] {
				// v3
				
				let routeArray = (michelsonDict.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsUnknownArray()?.first as? [[String: Any]])
				
				var total: Decimal = 0
				for michelsonDictRoute in routeArray ?? [] {
					let value = michelsonDictRoute.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
					total += Decimal(string: value ?? "0") ?? 0
				}
				
				return total
				
			} else if contract == "KT1V5XKmeypanMS9pR65REpqmVejWBZURuuT", let michelsonDict = michelson as? [String: Any] {
				// v4
				
				let routeArray = (michelsonDict.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsUnknownArray()?.first as? [[String: Any]])
				
				var total: Decimal = 0
				for michelsonDictRoute in routeArray ?? [] {
					let value = michelsonDictRoute.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
					total += Decimal(string: value ?? "0") ?? 0
				}
				
				return total
				
			} else {
				return nil
			}
		}
		
		/**
		 Extract rpc amount (without decimal info) michelson `deposit` value for a crunchy stake call
		 */
		public static func tokenAmountFromDepositMichelson(michelson: Any) -> Decimal? {
			if let michelsonDict = michelson as? [String: Any] {
				let tokenAmount = michelsonDict.michelsonArgsArray()?.michelsonInt(atIndex: 1)
				
				return Decimal(string: tokenAmount ?? "0") ?? 0
				
			} else {
				return nil
			}
		}
		
		/**
		 Extract rpc amount (without decimal info) michelson `offer` value for a OBJKT offer call
		 */
		public static func tokenAmountFromOfferMichelson(michelson: Any) -> Decimal? {
			if let michelsonDict = michelson as? [String: Any] {
				let tokenAmount = michelsonDict.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
				
				return Decimal(string: tokenAmount ?? "0") ?? 0
				
			} else {
				return nil
			}
		}
		
		/**
		 Extract rpc amount (without decimal info) michelson `offer` value for a OBJKT offer call
		 */
		public static func tokenAmountFromBidMichelson(michelson: Any) -> Decimal? {
			if let michelsonDict = michelson as? [String: Any] {
				let tokenAmount = michelsonDict.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
				
				return Decimal(string: tokenAmount ?? "0") ?? 0
				
			} else {
				return nil
			}
		}
		
		/**
		 Extract rpc amount (without decimal info) a tokenId, and the destination from a michelson FA1.2 / FA2 transfer payload
		 */
		public static func tokenIdAndAmountFromTransferMichelson(michelson: Any) -> (rpcAmount: String, tokenId: Decimal?, destination: String)? {
			if let michelsonDict = michelson as? [String: Any] {
				
				// FA1.2
				let rpcAmountString = michelsonDict.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
				let rpcDestinationString = michelsonDict.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonString(atIndex: 0) ?? ""
				
				if let str = rpcAmountString {
					return (rpcAmount: str, tokenId: nil, destination: rpcDestinationString)
				} else {
					return nil
				}
				
			} else if let michelsonArray = michelson as? [[String: Any]] {
				
				// FA2
				let outerContainerArray = michelsonArray[0].michelsonArgsUnknownArray()?.michelsonArray(atIndex: 1)
				
				// For now, we only support sending 1 item per transaction. The FA2 standard allows for multiple items to be passed in via an array
				// If thats the case we simply return nil, to mark it as an unknwon type until we can get a better handle on extractions
				guard outerContainerArray?.count == 1 else {
					return nil
				}
				
				let argsArray1 = outerContainerArray?.michelsonPair(atIndex: 0)?.michelsonArgsArray()
				
				let rpcDestination = argsArray1?.michelsonString(atIndex: 0)
				
				let argsArray2 = argsArray1?.michelsonPair(atIndex: 1)?.michelsonArgsArray()
				let rpcAmountString = argsArray2?.michelsonInt(atIndex: 1)
				let tokenId = argsArray2?.michelsonInt(atIndex: 0)
				
				if let str = rpcAmountString, let tId = tokenId, let dest = rpcDestination {
					return (rpcAmount: str, tokenId: Decimal(string: tId), destination: dest)
				} else {
					return nil
				}
				
			} else {
				return nil
			}
		}
		
		/**
		 Extract rpc amount (without decimal info) a tokenId, and the destination from a michelson
		 Supports:
		 - FA1.2 transfer
		 - FA2 transfer
		 - 3Route
		 - Approve operation
		 - update_operator operation
		 */
		public static func tokenIdAndAmountFromMichelson(michelson: Any, contract: String) -> (rpcAmount: String, tokenId: Decimal?, destination: String?)? {
			if let michelsonDict = michelson as? [String: Any], let entrypoint = michelsonDict["entrypoint"] as? String {
				switch entrypoint {
					case OperationTransaction.StandardEntrypoint.approve.rawValue:
						if let approveResponse = tokenIdAndAmountFromApproveMichelson(michelson: michelsonDict["value"] ?? [:]) {
							return (rpcAmount: approveResponse.rpcAmount, tokenId: approveResponse.tokenId, destination: approveResponse.destination)
						} else {
							return nil
						}
						
					case OperationTransaction.StandardEntrypoint.updateOperators.rawValue:
						if let updateResponse = tokenIdFromUpdateOperatorsMichelson(michelson: michelsonDict["value"] ?? [:]) {
							return (rpcAmount: "0", tokenId: updateResponse.tokenId, destination: updateResponse.destination)
						} else {
							return nil
						}
						
					case OperationTransaction.StandardEntrypoint.transfer.rawValue:
						return tokenIdAndAmountFromTransferMichelson(michelson: michelsonDict["value"] ?? [:])
						
					case OperationTransaction.StandardEntrypoint.execute.rawValue: // 3route
						if let response = tokenAmountFromExecuteMichelson(michelson: michelsonDict["value"] ?? [:], contract: contract) {
							return (rpcAmount: response.description, tokenId: nil, destination: nil) // Can extract amount, but nothing else
							
						} else {
							return nil
						}
						
					case OperationTransaction.StandardEntrypoint.deposit.rawValue: // crunchy - stake
						if let response = tokenAmountFromDepositMichelson(michelson: michelsonDict["value"] ?? [:]) {
							return (rpcAmount: response.description, tokenId: nil, destination: nil) // Can extract amount, but nothing else
							
						} else {
							return nil
						}
					
					case OperationTransaction.StandardEntrypoint.offer.rawValue: // OBJKT - make offer
						if let response = tokenAmountFromOfferMichelson(michelson: michelsonDict["value"] ?? [:]) {
							return (rpcAmount: response.description, tokenId: nil, destination: nil) // Can extract amount, but nothing else
							
						} else {
							return nil
						}
						
					case OperationTransaction.StandardEntrypoint.bid.rawValue: // OBJKT - bid on auction
						if let response = tokenAmountFromBidMichelson(michelson: michelsonDict["value"] ?? [:]) {
							return (rpcAmount: response.description, tokenId: nil, destination: nil) // Can extract amount, but nothing else
							
						} else {
							return nil
						}
						
					default:
						return nil
				}
			}
			
			return nil
		}
		
		/**
		 Run through list of operations and extract the first valid `faTokenDetailsFrom(transaction: ...)`
		 In the case of hitting an `update_operators`, will check for the next transaction to see if it contains the amount
		 Useful for displaying the main token being swapped in a dex aggregator call
		 */
		public static func firstNonZeroTokenTransferAmount(operations: [Operation]) -> (tokenContract: String, rpcAmount: String, tokenId: Decimal?, destination: String)? {
			
			var lastTokenIdAndAmountResults: (rpcAmount: String, tokenId: Decimal?, destination: String?)? = nil
			var lastTokenAddress: String? = nil
			
			for op in operations {
				if let opTrans = op as? OperationTransaction, let details = tokenIdAndAmountFromMichelson(michelson: opTrans.parameters ?? [:], contract: opTrans.destination), let entrypoint = (opTrans.parameters?["entrypoint"] as? String) {
					
					if entrypoint == OperationTransaction.StandardEntrypoint.approve.rawValue || entrypoint == OperationTransaction.StandardEntrypoint.updateOperators.rawValue {
						
						// If its an `approve` oepration or an `update_operators` hold onto the details for the next run
						lastTokenIdAndAmountResults = details
						lastTokenAddress = opTrans.destination
						
					} else if let lastDetails = lastTokenIdAndAmountResults,
							  let lastTokenAddress = lastTokenAddress,
							  (entrypoint != OperationTransaction.StandardEntrypoint.approve.rawValue && entrypoint != OperationTransaction.StandardEntrypoint.updateOperators.rawValue),
							  let knownOpDetails = tokenIdAndAmountFromMichelson(michelson: opTrans.parameters ?? [:], contract: opTrans.destination) {
						
						// If we have a previous set of details from an approve or update, check if we can extract something useful from this one to complete the info
						return (tokenContract: lastTokenAddress, rpcAmount: knownOpDetails.rpcAmount, tokenId: lastDetails.tokenId, destination: lastDetails.destination ?? "")
						
					} else {
						
						// Return the non zero value we have
						return (tokenContract: opTrans.destination, rpcAmount: details.rpcAmount, tokenId: details.tokenId, destination: details.destination ?? "")
					}
				}
			}
			
			
			if let lastDetails = lastTokenIdAndAmountResults, let lastTokenAddress = lastTokenAddress {
				// If we have anything at all, return it, so that we can display something in the event of a single approve or whatever
				return (tokenContract: lastTokenAddress, rpcAmount: lastDetails.rpcAmount, tokenId: lastDetails.tokenId, destination: lastDetails.destination ?? "")
			}
			
			return nil
		}
		
		/**
		 Reveal operation is often visually hidden from user, as its a mandatory step thats handled automatically
		 */
		public static func filterReveal(operations: [Operation]) -> [Operation] {
			let ops = operations.filter { opToCheck in
				if opToCheck.operationKind == .reveal {
					return false
				}
				
				return true
			}
			
			return ops
		}
		
		/**
		 Reveal, Approve and UpdateOperator operations can be appended to operation lists. When determining what the intent of the operation array is, it can be important to ignore these
		 */
		public static func filterRevealApporveUpdate(operations: [Operation]) -> [Operation] {
			let ops = operations.filter { opToCheck in
				let castAsTransaction = opToCheck as? OperationTransaction
				let entrypointAsString = castAsTransaction?.parameters?["entrypoint"] as? String
				
				if opToCheck.operationKind == .reveal ||
					castAsTransaction == nil ||
					entrypointAsString == OperationTransaction.StandardEntrypoint.approve.rawValue ||
					entrypointAsString == OperationTransaction.StandardEntrypoint.updateOperators.rawValue {
					return false
				}
				
				return true
			}
			
			return ops
		}
		
		/**
		 Check if the array is only of type OperationTransaction, optionally ignore reveal as its usually supressed from user
		 Useful in situations where you are displaying batch information but can only handle certain opertion types
		 */
		public static func containsAllOperationTransactions(operations: [Operation], ignoreReveal: Bool = true) -> Bool {
			var result = false
			
			for op in operations {
				if let _ = op as? OperationTransaction {
					result = true
					
				} else if let _ = op as? OperationReveal {
					result = ignoreReveal ?  true : false
					
				} else {
					result = false
				}
				
				if !result {
					return result
				}
			}
			
			return result
		}
		
		/**
		 Check if the array is contains at least 1 OperationUnknown
		 Useful in situations to display fallback UI for unknown cases
		 */
		public static func containsAnUnknownOperation(operations: [Operation]) -> Bool {
			for op in operations {
				if let _ = op as? OperationUnknown {
					return true
				}
			}
			
			return false
		}
		
		/**
		 Run through list of operations and extract .amount from any OperationTransaction + balance from any OperationOrigination
		 */
		public static func totalTezAmountSent(operations: [Operation]) -> XTZAmount {
			var amount = XTZAmount.zero()
			
			for op in operations {
				if let opTrans = op as? OperationTransaction {
					amount += (XTZAmount(fromRpcAmount: opTrans.amount) ?? .zero())
					
				} else if let opOrig = op as? OperationOrigination {
					amount += (XTZAmount(fromRpcAmount: opOrig.balance) ?? .zero())
				}
			}
			
			return amount
		}
		
		/**
		 Check if the operation is a contract call, but ignore entrypoint trasnfer
		 Useful for situations where you want to display different info about contract calls such as claim or mint, compared to transferring a token
		 Return the entrypoint and contract address if so
		 */
		public static func isNonTransferContractCall(operation: Operation) -> (operation: OperationTransaction, entrypoint: String, address: String)? {
			if let details = isContractCall(operation: operation), details.entrypoint != OperationTransaction.StandardEntrypoint.transfer.rawValue {
				return details
			}
			
			return nil
		}
		
		/**
		 Check if the operation is a contract call, return the entrypoint and address if so, nil if not
		 */
		public static func isContractCall(operation: Operation) -> (operation: OperationTransaction, entrypoint: String, address: String)? {
			if let opT = operation as? OperationTransaction, let entrypoint = opT.parameters?["entrypoint"] as? String {
				return (operation: opT, entrypoint: entrypoint, address: opT.destination)
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
			"value": ["prim":"Pair", "args":[["string":walletAddress] as [String : Any], ["prim":"Pair", "args":[["int":minTokenAmount.rpcRepresentation], ["string":dateString]]]]] as [String : Any]
		]
	}
	
	private static func xtzToToken_quipu_michelsonEntrypoint(minTokenAmount: TokenAmount, walletAddress: String) -> [String: Any] {
		
		return [
			"entrypoint": OperationTransaction.StandardEntrypoint.tezToTokenPayment.rawValue,
			"value": ["prim": "Pair", "args": [["int": minTokenAmount.rpcRepresentation], ["string": walletAddress]]] as [String : Any]
		]
	}
	
	
	
	// MARK: - tokenToXtz
	
	private static func tokenToXtz_lb_michelsonEntrypoint(tokenAmount: TokenAmount, minXTZAmount: XTZAmount, walletAddress: String, timeout: TimeInterval) -> [String: Any] {
		let dateString = createDexterTimestampString(nowPlusTimeInterval: timeout)
		return [
			"entrypoint": OperationTransaction.StandardEntrypoint.tokenToXtz.rawValue,
			"value": ["prim":"Pair", "args": [["string": walletAddress] as [String : Any], ["prim": "Pair", "args": [["int": tokenAmount.rpcRepresentation] as [String : Any], ["prim": "Pair", "args":[["int":minXTZAmount.rpcRepresentation], ["string": dateString]]]]]]] as [String : Any]
		]
	}
	
	private static func tokenToXtz_quipu_michelsonEntrypoint(tokenAmount: TokenAmount, minXTZAmount: XTZAmount, walletAddress: String) -> [String: Any] {
		return [
			"entrypoint": OperationTransaction.StandardEntrypoint.tokenToTezPayment.rawValue,
			"value": ["prim": "Pair", "args": [["prim": "Pair", "args": [["int": tokenAmount.rpcRepresentation], ["int": minXTZAmount.rpcRepresentation]]] as [String : Any], ["string": walletAddress]]] as [String : Any]
		]
	}
	
	
	
	// MARK: - Add liquidity
	
	private static func addLiquidity_lb_michelsonEntrypoint(xtzToDeposit: XTZAmount, tokensToDeposit: TokenAmount, minLiquidtyMinted: TokenAmount, walletAddress: String, timeout: TimeInterval) -> [String: Any] {
		let dateString = createDexterTimestampString(nowPlusTimeInterval: timeout)
		
		return [
			"entrypoint": OperationTransaction.StandardEntrypoint.addLiquidity.rawValue,
			"value": ["prim": "Pair", "args": [["string":walletAddress] as [String : Any], ["prim":"Pair", "args":[["int":minLiquidtyMinted.rpcRepresentation] as [String : Any] as [String : Any], ["prim":"Pair", "args":[["int":tokensToDeposit.rpcRepresentation], ["string":dateString]]]]]]] as [String : Any]
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
			"value": ["prim":"Pair","args":[["string":walletAddress] as [String : Any], ["prim":"Pair","args":[["int":liq] as [String : Any], ["prim":"Pair","args":[["int":xtz] as [String : Any], ["prim":"Pair","args":[["int":token], ["string":dateString]]]]]]]]] as [String : Any]
		]
	}
	
	private static func removeLiquidity_quipu_michelsonEntrypoint(minXTZ: XTZAmount, minToken: TokenAmount, liquidityToBurn: TokenAmount) -> [String: Any] {
		return [
			"entrypoint": OperationTransaction.StandardEntrypoint.divestLiquidity.rawValue,
			"value": ["prim": "Pair", "args": [["prim": "Pair", "args": [["int": minXTZ.rpcRepresentation], ["int": minToken.rpcRepresentation]]] as [String : Any], ["int": liquidityToBurn.rpcRepresentation]]] as [String : Any]
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
