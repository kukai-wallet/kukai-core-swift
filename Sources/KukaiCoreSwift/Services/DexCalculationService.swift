//
//  DexCalculationService.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 26/11/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import JavaScriptCore
import os.log

/// A struct to hold all the necessary calculations for a dex trade
public struct DexSwapCalculationResult {
	public let expected: TokenAmount
	public let minimum: TokenAmount
	public let displayExchangeRate: Decimal
	public let displayPriceImpact: Double
	
	public init(expected: TokenAmount, minimum: TokenAmount, displayExchangeRate: Decimal, displayPriceImpact: Double) {
		self.expected = expected
		self.minimum = minimum
		self.displayExchangeRate = displayExchangeRate
		self.displayPriceImpact = displayPriceImpact
	}
}

/// A struct to hold all the necessary calculations for adding liquidity to a dex contract
public struct DexAddCalculationResult {
	public let expectedLiquidity: TokenAmount
	public let minimumLiquidity: TokenAmount
	public let tokenRequired: TokenAmount
	public let exchangeRate: Decimal
	
	public init(expectedLiquidity: TokenAmount, minimumLiquidity: TokenAmount, tokenRequired: TokenAmount, exchangeRate: Decimal) {
		self.expectedLiquidity = expectedLiquidity
		self.minimumLiquidity = minimumLiquidity
		self.tokenRequired = tokenRequired
		self.exchangeRate = exchangeRate
	}
}

/// A struct to hold all the necessary calculations for removing liquidity from a dex contract
public struct DexRemoveCalculationResult {
	public let expectedXTZ: XTZAmount
	public let minimumXTZ: XTZAmount
	public let expectedToken: TokenAmount
	public let minimumToken: TokenAmount
	public let exchangeRate: Decimal
	
	public init(expectedXTZ: XTZAmount, minimumXTZ: XTZAmount, expectedToken: TokenAmount, minimumToken: TokenAmount, exchangeRate: Decimal) {
		self.expectedXTZ = expectedXTZ
		self.minimumXTZ = minimumXTZ
		self.expectedToken = expectedToken
		self.minimumToken = minimumToken
		self.exchangeRate = exchangeRate
	}
}



/// Wrapper around the kukai-dex-calculations JS library for performing calculations: https://github.com/kukai-wallet/kukai-dex-calculations
public class DexCalculationService {
	
	private let jsContext: JSContext
	
	/// Public shared instace to avoid having multiple copies of the underlying `JSContext` created
	public static let shared = DexCalculationService()
	
	
	private init() {
		jsContext = JSContext()
		jsContext.exceptionHandler = { context, exception in
			os_log("Dex calculation JSContext exception: %@", log: .kukaiCoreSwift, type: .error, exception?.toString() ?? "")
		}
		
		if let jsSourcePath = Bundle.module.url(forResource: "kukai-dex-calculations", withExtension: "js", subdirectory: "External") {
			do {
				let jsSourceContents = try String(contentsOf: jsSourcePath)
				self.jsContext.evaluateScript(jsSourceContents)
				
			} catch (let error) {
				os_log("Error parsing Dex calculation javascript file: %@", log: .kukaiCoreSwift, type: .error, "\(error)")
			}
		}
	}
	
	
	
	// MARK: - User flow functions
	
	/**
	A helper function to create all the necessary calculations for a xtzToToken exchange, to perform the operation and display the info to the user in a confirmation screen.
	- parameter xtzToSell: The `XTZAmount` to sell.
	- parameter xtzPool: The `XTZAmount` representing the current pool of XTZ that the dex contract holds. Can be fetched with xxxxx.
	- parameter tokenPool: The `TokenAmount` representing the current pool of the given `Token` that the dex contract holds. Must have the same number of decimalPlaces as the token it represents. Can be fetched with xxxxx.
	- parameter maxSlippage: Percentage (must be between 0 and 1) of maximum amount of slippage the user is willing to accept
	- returns: `DexSwapCalculationResult` containing the results of all the necessary calculations.
	*/
	public func calculateXtzToToken(xtzToSell: XTZAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, maxSlippage: Double, dex: TezToolDex) -> DexSwapCalculationResult? {
		guard let expected = xtzToTokenExpectedReturn(xtzToSell: xtzToSell, xtzPool: xtzPool, tokenPool: tokenPool, dex: dex),
			  let minimum = xtzToTokenMinimumReturn(tokenAmount: expected, slippage: maxSlippage),
			  let rate = xtzToTokenExchangeRateDisplay(xtzToSell: xtzToSell, xtzPool: xtzPool, tokenPool: tokenPool, dex: dex),
			  let priceImpact = xtzToTokenPriceImpact(xtzToSell: xtzToSell, xtzPool: xtzPool, tokenPool: tokenPool, dex: dex) else {
			return nil
		}
		
		let impactDouble = Double(priceImpact.description) ?? 0
		
		return DexSwapCalculationResult(expected: expected, minimum: minimum, displayExchangeRate: rate, displayPriceImpact: impactDouble)
	}
	
	/**
	A helper function to create all the necessary calculations for a tokenToXtz exchange, to perform the operation and display the info to the user in a confirmation screen.
	- parameter tokenToSell: The `TokenAmount` to sell.
	- parameter xtzPool: The `XTZAmount` representing the current pool of XTZ that the dex contract holds. Can be fetched with xxxxx.
	- parameter tokenPool: The `TokenAmount` representing the current pool of the given `Token` that the dex contract holds. Must have the same number of decimalPlaces as the token it represents. Can be fetched with xxxxx.
	- parameter maxSlippage: Percentage (must be between 0 and 1) of maximum amount of slippage the user is willing to accept
	- returns: `DexSwapCalculationResult` containing the results of all the necessary calculations.
	*/
	public func calculateTokenToXTZ(tokenToSell: TokenAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, maxSlippage: Double, dex: TezToolDex) -> DexSwapCalculationResult? {
		guard let expected = tokenToXtzExpectedReturn(tokenToSell: tokenToSell, xtzPool: xtzPool, tokenPool: tokenPool, dex: dex),
			  let minimum = tokenToXtzMinimumReturn(xtzAmount: expected, slippage: maxSlippage),
			  let rate = tokenToXtzExchangeRateDisplay(tokenToSell: tokenToSell, xtzPool: xtzPool, tokenPool: tokenPool, dex: dex),
			  let priceImpact = tokenToXtzPriceImpact(tokenToSell: tokenToSell, xtzPool: xtzPool, tokenPool: tokenPool, dex: dex) else {
			return nil
		}
		
		let impactDouble = Double(priceImpact.description) ?? 0
		
		return DexSwapCalculationResult(expected: expected, minimum: minimum, displayExchangeRate: rate, displayPriceImpact: impactDouble)
	}
	
	/**
	A helper function to create all the necessary calculations for adding liquidity, with an XTZ input
	- parameter xtz: The amount of XTZ to deposit
	- parameter xtzPool: The total XTZ held in the dex contract
	- parameter tokenPool: The total token held in the dex contract
	- parameter totalLiquidity: The ttotal liquidity held in the liquidity contract
	- parameter maxSlippage: Percentage (must be between 0 and 1) of maximum amount of slippage the user is willing to accept
	- returns: `(tokenRequired: TokenAmount, liquidity: TokenAmount)` containing the results of all the necessary calculations.
	*/
	public func calculateAddLiquidity(xtz: XTZAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, totalLiquidity: TokenAmount, maxSlippage: Double, dex: TezToolDex) -> DexAddCalculationResult? {
		guard let tokenRequired = addLiquidityTokenRequired(xtzToDeposit: xtz, xtzPool: xtzPool, tokenPool: tokenPool, dex: dex),
			  let liquidityReturned = addLiquidityReturn(xtzToDeposit: xtz, xtzPool: xtzPool, totalLiquidity: totalLiquidity, slippage: maxSlippage, dex: dex),
			  let exchangeRate = xtzToTokenExchangeRateDisplay(xtzToSell: xtz, xtzPool: xtzPool, tokenPool: tokenPool, dex: dex) else {
			return nil
		}
		
		return DexAddCalculationResult(expectedLiquidity: liquidityReturned.expected, minimumLiquidity: liquidityReturned.minimum, tokenRequired: tokenRequired, exchangeRate: exchangeRate)
	}
	
	/**
	A helper function to create all the necessary calculations for adding liquidity, with an Token input
	- parameter token: The amount of Token to deposit
	- parameter xtzPool: The total XTZ held in the dex contract
	- parameter tokenPool: The total token held in the dex contract
	- parameter totalLiquidity: The ttotal liquidity held in the liquidity contract
	- parameter maxSlippage: Percentage (must be between 0 and 1) of maximum amount of slippage the user is willing to accept
	- returns: `(xtzRequired: XTZAmount, liquidity: TokenAmount)` containing the results of all the necessary calculations.
	*/
	public func calculateAddLiquidity(token: TokenAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, totalLiquidity: TokenAmount, maxSlippage: Double, dex: TezToolDex) -> DexAddCalculationResult? {
		guard let xtzRequired = addLiquidityXtzRequired(tokenToDeposit: token, xtzPool: xtzPool, tokenPool: tokenPool, dex: dex),
			  let liquidityReturned = addLiquidityReturn(xtzToDeposit: xtzRequired, xtzPool: xtzPool, totalLiquidity: totalLiquidity, slippage: maxSlippage, dex: dex),
			  let exchangeRate = xtzToTokenExchangeRateDisplay(xtzToSell: xtzRequired, xtzPool: xtzPool, tokenPool: tokenPool, dex: dex) else {
			return nil
		}
		
		return DexAddCalculationResult(expectedLiquidity: liquidityReturned.expected, minimumLiquidity: liquidityReturned.minimum, tokenRequired: xtzRequired, exchangeRate: exchangeRate)
	}
	
	/**
	A helper function to create all the necessary calculations for removing liquidity, to return everything the user will get out
	- parameter liquidityBurned: The amount of Liquidity tokens the user wants to burn or sell
	- parameter totalLiquidity: The total volume of liquidity held in the contract
	- parameter xtzPool: The xtz pool held in the dex contract
	- parameter tokenPool: The token pool held in the dex contract
	- parameter maxSlippage: Percentage (must be between 0 and 1) of maximum amount of slippage the user is willing to accept
	- returns: `(xtz: XTZAmount, token: TokenAmount)` containing the results of all the necessary calculations.
	*/
	public func calculateRemoveLiquidity(liquidityBurned: TokenAmount, totalLiquidity: TokenAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, maxSlippage: Double, dex: TezToolDex) -> DexRemoveCalculationResult? {
		guard let xtzOut = removeLiquidityXtzReceived(liquidityBurned: liquidityBurned, totalLiquidity: totalLiquidity, xtzPool: xtzPool, slippage: maxSlippage, dex: dex),
			  let tokenOut = removeLiquidityTokenReceived(liquidityBurned: liquidityBurned, totalLiquidity: totalLiquidity, tokenPool: tokenPool, slippage: maxSlippage),
			  let exchangeRate = xtzToTokenExchangeRateDisplay(xtzToSell: xtzOut.expected, xtzPool: xtzPool, tokenPool: tokenPool, dex: dex) else {
			return nil
		}
		
		return DexRemoveCalculationResult(expectedXTZ: xtzOut.expected, minimumXTZ: xtzOut.minimum, expectedToken: tokenOut.expected, minimumToken: tokenOut.minimum, exchangeRate: exchangeRate)
	}
	
	public static func settings(forDex dex: TezToolDex) -> (fee: Double, burn: Double, includeSubsidy: Bool) {
		switch dex {
			case .liquidityBaking:
				return (fee: 0.1, burn: 0.1, includeSubsidy: true)
				
			case .quipuswap:
				return (fee: 0.3, burn: 0, includeSubsidy: false)
				
			case .unknown:
				return (fee: 0.3, burn: 0, includeSubsidy: false)
		}
	}
	
	
	
	// MARK: - XTZ To Token
	
	/**
	The `TokenAmount` expected to be returned for the supplied `XTZAmount`, given the dex contract xtzPool and tokenPool.
	- parameter xtzToSell: The `XTZAmount` to sell.
	- parameter xtzPool: The `XTZAmount` representing the current pool of XTZ that the dex holds. Can be fetched with xxxxx.
	- parameter tokenPool: The `TokenAmount` representing the current pool of the given `Token` that the dex holds. Must have the same number of decimalPlaces as the token it represents. Can be fetched with xxxxx.
	- returns: `TokenAmount` containing the amount the user can expect in return for their XTZ
	*/
	public func xtzToTokenExpectedReturn(xtzToSell: XTZAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, dex: TezToolDex) -> TokenAmount? {
		let xtz = xtzToSell.rpcRepresentation
		let xPool = xtzPool.rpcRepresentation
		let tPool = tokenPool.rpcRepresentation
		let settings = DexCalculationService.settings(forDex: dex)
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("xtzToTokenTokenOutput"),
			  let result = inner.call(withArguments: [xtz, xPool, tPool, settings.fee, settings.burn, settings.includeSubsidy]) else {
			return nil
		}
		
		return TokenAmount(fromRpcAmount: result.toString(), decimalPlaces: tokenPool.decimalPlaces)
	}
	
	
	/**
	The minimum possible `TokenAmount` returned, taking into account slippage.
	- parameter tokenAmount: The `TokenAmount` returned from `xtzToTokenExpectedReturn()`.
	- parameter slippage: A double value between 0 and 1, indicating the maximum percentage of slippage a user will accept.
	- returns: `TokenAmount` containing the minimum amount the user can expect in return for their XTZ
	*/
	public func xtzToTokenMinimumReturn(tokenAmount: TokenAmount, slippage: Double) -> TokenAmount? {
		let token = tokenAmount.rpcRepresentation
		
		guard slippage >= 0, slippage <= 1 else {
			os_log("slippage value supplied to `xtzToTokenMinimumReturn` was not between 0 and 1: %@", log: .kukaiCoreSwift, type: .error, slippage)
			return nil
		}
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("xtzToTokenMinimumTokenOutput"),
			  let result = inner.call(withArguments: [token, slippage]) else {
			return nil
		}
		
		return TokenAmount(fromRpcAmount: result.toString(), decimalPlaces: tokenAmount.decimalPlaces)
	}
	
	
	/**
	Calculate the `XTZAmount` required in order to receive the supplied `TokenAmount`.
	- parameter tokenAmount: The `TokenAmount` the user wants to receive.
	- parameter xtzPool: The `XTZAmount` representing the current pool of XTZ that the dex holds. Can be fetched with xxxxx.
	- parameter tokenPool: The `TokenAmount` representing the current pool of the given `Token` that the dex holds. Must have the same number of decimalPlaces as the token it represents. Can be fetched with xxxxx.
	- returns: `XTZAmount` containing the amount of XTZ required in order to recieve the amount of token.
	*/
	public func xtzToTokenRequiredXtzFor(tokenAmount: TokenAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, dex: TezToolDex) -> XTZAmount? {
		let tokenRequired = tokenAmount.rpcRepresentation
		let xtzPool = xtzPool.rpcRepresentation
		let tokenPool = tokenPool.rpcRepresentation
		let settings = DexCalculationService.settings(forDex: dex)
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("xtzToTokenXtzInput"),
			  let result = inner.call(withArguments: [tokenRequired, xtzPool, tokenPool, tokenAmount.decimalPlaces, settings.fee, settings.burn, settings.includeSubsidy]) else {
			return nil
		}
		
		return XTZAmount(fromRpcAmount: result.toString())
	}
	
	
	
	// MARK: XTZ To Token Rates
	
	/**
	The exchange rate for a given trade, taking into account slippage and fees
	- parameter xtzToSell: The `XTZAmount` to sell.
	- parameter xtzPool: The `XTZAmount` representing the current pool of XTZ that the dex holds. Can be fetched with xxxxx.
	- parameter tokenPool: The `TokenAmount` representing the current pool of the given `Token` that the dex holds. Must have the same number of decimalPlaces as the token it represents. Can be fetched with xxxxx.
	- returns: `Decimal` containing the exchange rate from 1 XTZ to the requested `Token`
	*/
	public func xtzToTokenExchangeRate(xtzToSell: XTZAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, dex: TezToolDex) -> Decimal? {
		let xtz = xtzToSell.rpcRepresentation
		let xtzPool = xtzPool.rpcRepresentation
		let tokenPool = tokenPool.rpcRepresentation
		let settings = DexCalculationService.settings(forDex: dex)
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("xtzToTokenExchangeRate"),
			  let result = inner.call(withArguments: [xtz, xtzPool, tokenPool, settings.fee, settings.burn, settings.includeSubsidy]) else {
			return nil
		}
		
		return Decimal(string: result.toString())
	}
	
	
	/**
	The exchange rate for a given trade, taking into account slippage and fees, formatted and truncated for easier display in the UI.
	- parameter xtzToSell: The `XTZAmount` to sell.
	- parameter xtzPool: The `XTZAmount` representing the current pool of XTZ that the dex holds. Can be fetched with xxxxx.
	- parameter tokenPool: The `TokenAmount` representing the current pool of the given `Token` that the dex holds. Must have the same number of decimalPlaces as the token it represents. Can be fetched with xxxxx.
	- returns: `Decimal` containing the exchange rate from 1 XTZ to the requested `Token`
	*/
	public func xtzToTokenExchangeRateDisplay(xtzToSell: XTZAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, dex: TezToolDex) -> Decimal? {
		let xtz = xtzToSell.rpcRepresentation
		let xPool = xtzPool.rpcRepresentation
		let tPool = tokenPool.rpcRepresentation
		let settings = DexCalculationService.settings(forDex: dex)
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("xtzToTokenExchangeRateForDisplay"),
			  let result = inner.call(withArguments: [xtz, xPool, tPool, tokenPool.decimalPlaces, settings.fee, settings.burn, settings.includeSubsidy]) else {
			return nil
		}
		
		return Decimal(string: result.toString())?.rounded(scale: tokenPool.decimalPlaces, roundingMode: .bankers)
	}
	
	/**
	Before a user has entered in an amount to trade, its useful to show them the base exchange rate, ignoring slippage.
	- parameter xtzPool: The `XTZAmount` representing the current pool of XTZ that the dex holds. Can be fetched with xxxxx.
	- parameter tokenPool: The `TokenAmount` representing the current pool of the given `Token` that the dex holds. Must have the same number of decimalPlaces as the token it represents. Can be fetched with xxxxx.
	- returns: `Decimal` containing the exchange rate from 1 XTZ to the requested `Token`
	*/
	public func xtzToTokenMarketRate(xtzPool: XTZAmount, tokenPool: TokenAmount) -> Decimal? {
		let xPool = xtzPool.rpcRepresentation
		let tPool = tokenPool.rpcRepresentation
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("xtzToTokenMarketRate"),
			  let result = inner.call(withArguments: [xPool, tPool, tokenPool.decimalPlaces]) else {
			return nil
		}
		
		return Decimal(string: result.toString())?.rounded(scale: tokenPool.decimalPlaces, roundingMode: .bankers)
	}
	
	
	
	/**
	Calcualte the percentage the price impact the given trade would incur. Since this is already taken into account for the other functions, this function returns in the scale of 0 - 100, for display purposes.
	- parameter xtzToSell: The `XTZAmount` to sell.
	- parameter xtzPool: The `XTZAmount` representing the current pool of XTZ that the dex holds. Can be fetched with xxxxx.
	- parameter tokenPool: The `TokenAmount` representing the current pool of the given `Token` that the dex holds. Must have the same number of decimalPlaces as the token it represents. Can be fetched with xxxxx.
	- returns: `Decimal` containing the slippage percentage, 0 - 100.
	*/
	public func xtzToTokenPriceImpact(xtzToSell: XTZAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, dex: TezToolDex) -> Decimal? {
		let xtz = xtzToSell.rpcRepresentation
		let xtzPool = xtzPool.rpcRepresentation
		let tokenPool = tokenPool.rpcRepresentation
		let settings = DexCalculationService.settings(forDex: dex)
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("xtzToTokenPriceImpact"),
			  let result = inner.call(withArguments: [xtz, xtzPool, tokenPool, settings.burn, settings.includeSubsidy]) else {
			return nil
		}
		
		return (Decimal(string: result.toString())?.rounded(scale: 4, roundingMode: .bankers) ?? 0) * 100
	}
	
	
	
	// MARK: Token to XTZ
	
	/**
	The `XTZAmount` expected to be returned for the supplied `TokenAmount`, given the dex contracts xtzPool and tokenPool.
	- parameter tokenToSell: The `TokenAmount` to sell.
	- parameter xtzPool: The `XTZAmount` representing the current pool of XTZ that the dex holds. Can be fetched with xxxxx.
	- parameter tokenPool: The `TokenAmount` representing the current pool of the given `Token` that the dex holds. Must have the same number of decimalPlaces as the token it represents. Can be fetched with xxxxx.
	- returns: `XTZAmount` containing the amount the user can expect in return for their `Token`
	*/
	public func tokenToXtzExpectedReturn(tokenToSell: TokenAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, dex: TezToolDex) -> XTZAmount? {
		let token = tokenToSell.rpcRepresentation
		let xtzPool = xtzPool.rpcRepresentation
		let tokenPool = tokenPool.rpcRepresentation
		let settings = DexCalculationService.settings(forDex: dex)
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("tokenToXtzXtzOutput"),
			  let result = inner.call(withArguments: [token, xtzPool, tokenPool, settings.fee, settings.burn, settings.includeSubsidy]) else {
			return nil
		}
		
		return XTZAmount(fromRpcAmount: result.toString())
	}
	
	
	/**
	The minimum possible `XTZAmount` returned, taking into account slippage.
	- parameter xtzAmount: The `XTZAmount` returned from `tokenToXtzExpectedReturn()`.
	- parameter slippage: A double value between 0 and 1, indicating the maximum percentage of slippage a user will accept.
	- returns: `XTZAmount` containing the minimum amount the user can expect in return for their Token
	*/
	public func tokenToXtzMinimumReturn(xtzAmount: XTZAmount, slippage: Double) -> XTZAmount? {
		let xtz = xtzAmount.rpcRepresentation
		
		guard slippage >= 0, slippage <= 1 else {
			os_log("slippage value supplied to `tokenToXtzMinimumReturn` was not between 0 and 1: %@", log: .kukaiCoreSwift, type: .error, slippage)
			return nil
		}
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("tokenToXtzMinimumXtzOutput"),
			  let result = inner.call(withArguments: [xtz, slippage]) else {
			return nil
		}
		
		return XTZAmount(fromRpcAmount: result.toString())
	}
	
	
	/**
	Calculate the `TokenAmount` required in order to receive the supplied `XTZAmount`.
	- parameter xtzAmount: The `XTZAmount` the user wants to receive.
	- parameter xtzPool: The `XTZAmount` representing the current pool of XTZ that the dex holds. Can be fetched with xxxxx.
	- parameter tokenPool: The `TokenAmount` representing the current pool of the given `Token` that the dex holds. Must have the same number of decimalPlaces as the token it represents. Can be fetched with xxxxx.
	- returns: `TokenAmount` containing the amount of `Token` required in order to recieve the amount of XTZ.
	*/
	public func tokenToXtzRequiredTokenFor(xtzAmount: XTZAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, dex: TezToolDex) -> TokenAmount? {
		let xtzRequired = xtzAmount.rpcRepresentation
		let xPool = xtzPool.rpcRepresentation
		let tPool = tokenPool.rpcRepresentation
		let settings = DexCalculationService.settings(forDex: dex)
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("tokenToXtzTokenInput"),
			  let result = inner.call(withArguments: [xtzRequired, xPool, tPool, tokenPool.decimalPlaces, settings.fee, settings.burn, settings.includeSubsidy]) else {
			return nil
		}
		
		return TokenAmount(fromRpcAmount: result.toString(), decimalPlaces: tokenPool.decimalPlaces)
	}
	
	
	
	// MARK: XTZ To Token Rates
	
	/**
	The exchange rate for a given trade, taking into account slippage and fees
	- parameter tokenToSell: The `TokenAmount` to sell.
	- parameter xtzPool: The `XTZAmount` representing the current pool of XTZ that the dex holds. Can be fetched with xxxxx.
	- parameter tokenPool: The `TokenAmount` representing the current pool of the given `Token` that the dex holds. Must have the same number of decimalPlaces as the token it represents. Can be fetched with xxxxx.
	- returns: `Decimal` containing the exchange rate from 1 of the given `Token` to XTZ
	*/
	public func tokenToXtzExchangeRate(tokenToSell: TokenAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, dex: TezToolDex) -> Decimal? {
		let token = tokenToSell.rpcRepresentation
		let xtzPool = xtzPool.rpcRepresentation
		let tokenPool = tokenPool.rpcRepresentation
		let settings = DexCalculationService.settings(forDex: dex)
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("tokenToXtzExchangeRate"),
			  let result = inner.call(withArguments: [token, xtzPool, tokenPool, settings.fee, settings.burn, settings.includeSubsidy]) else {
			return nil
		}
		
		return Decimal(string: result.toString())
	}
	
	
	/**
	The exchange rate for a given trade, taking into account slippage and fees, formatted and truncated for easier display in the UI.
	- parameter tokenToSell: The `TokenAmount` to sell.
	- parameter xtzPool: The `XTZAmount` representing the current pool of XTZ that the dex holds. Can be fetched with xxxxx.
	- parameter tokenPool: The `TokenAmount` representing the current pool of the given `Token` that the dex holds. Must have the same number of decimalPlaces as the token it represents. Can be fetched with xxxxx.
	- returns: `Decimal` containing the exchange rate from 1 of the given `Token` to XTZ
	*/
	public func tokenToXtzExchangeRateDisplay(tokenToSell: TokenAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, dex: TezToolDex) -> Decimal? {
		let token = tokenToSell.rpcRepresentation
		let xPool = xtzPool.rpcRepresentation
		let tPool = tokenPool.rpcRepresentation
		let settings = DexCalculationService.settings(forDex: dex)
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("tokenToXtzExchangeRateForDisplay"),
			  let result = inner.call(withArguments: [token, xPool, tPool, tokenPool.decimalPlaces, settings.fee, settings.burn, settings.includeSubsidy]) else {
			return nil
		}
		
		return Decimal(string: result.toString())?.rounded(scale: tokenPool.decimalPlaces, roundingMode: .bankers)
	}
	
	
	/**
	Before a user has entered in an amount to trade, its useful to show them the base exchange rate, ignoring slippage.
	- parameter xtzPool: The `XTZAmount` representing the current pool of XTZ that the dex holds. Can be fetched with xxxxx.
	- parameter tokenPool: The `TokenAmount` representing the current pool of the given `Token` that the dex holds. Must have the same number of decimalPlaces as the token it represents. Can be fetched with xxxxx.
	- returns: `Decimal` containing the exchange rate from 1 of the given `Token` to XTZ
	*/
	public func tokenToXtzMarketRate(xtzPool: XTZAmount, tokenPool: TokenAmount) -> Decimal? {
		let xPool = xtzPool.rpcRepresentation
		let tPool = tokenPool.rpcRepresentation
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("tokenToXtzMarketRate"),
			  let result = inner.call(withArguments: [xPool, tPool, tokenPool.decimalPlaces]) else {
			return nil
		}
		
		return Decimal(string: result.toString())?.rounded(scale: tokenPool.decimalPlaces, roundingMode: .bankers)
	}
	
	
	/**
	Calcualte the percentage slippage the given trade would incur. Since this is already taken into account for the other functions, this function returns in the scale of 0 - 100, for display purposes.
	- parameter tokenToSell: The `TokenAmount` to sell.
	- parameter xtzPool: The `XTZAmount` representing the current pool of XTZ that the dex holds. Can be fetched with xxxxx.
	- parameter tokenPool: The `TokenAmount` representing the current pool of the given `Token` that the dex holds. Must have the same number of decimalPlaces as the token it represents. Can be fetched with xxxxx.
	- returns: `Decimal` containing the slippage percentage, 0 - 100.
	*/
	public func tokenToXtzPriceImpact(tokenToSell: TokenAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, dex: TezToolDex) -> Decimal? {
		let token = tokenToSell.rpcRepresentation
		let xtzPool = xtzPool.rpcRepresentation
		let tokenPool = tokenPool.rpcRepresentation
		let settings = DexCalculationService.settings(forDex: dex)
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("tokenToXtzPriceImpact"),
			  let result = inner.call(withArguments: [token, xtzPool, tokenPool, settings.burn, settings.includeSubsidy]) else {
			return nil
		}
		
		return (Decimal(string: result.toString())?.rounded(scale: 4, roundingMode: .bankers) ?? 0) * 100
	}
	
	
	
	// MARK: Add Liquidity
	
	/**
	Calculate the amount of liquidity tokens a user can expect back for an amount of XTZ and Token
	- parameter xtzToDeposit: The XTZ to send to the dex contract
	- parameter tokenToDeposit: The Token to send to the dex contract
	- parameter totalLiquidity: The total liquidity already in the contract
	- parameter slippage: Percentage (must be between 0 and 1) of maximum amount of slippage the user is willing to accept
	- returns: `TokenAmount` an amount of Liquidity token you will receive
	*/
	public func addLiquidityReturn(xtzToDeposit: XTZAmount, xtzPool: XTZAmount, totalLiquidity: TokenAmount, slippage: Double, dex: TezToolDex) -> (expected: TokenAmount, minimum: TokenAmount)? {
		guard slippage >= 0, slippage <= 1 else {
			os_log("slippage value supplied to `addLiquidityReturn` was not between 0 and 1: %@", log: .kukaiCoreSwift, type: .error, slippage)
			return nil
		}
		
		let xtzIn = xtzToDeposit.rpcRepresentation
		let xPool = xtzPool.rpcRepresentation
		let totalLqt = totalLiquidity.rpcRepresentation
		let settings = DexCalculationService.settings(forDex: dex)
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("addLiquidityLiquidityCreated"),
			  let result = inner.call(withArguments: [xtzIn, xPool, totalLqt, settings.includeSubsidy]) else {
			return nil
		}
		
		if let expectedAmount = TokenAmount(fromRpcAmount: result.toString(), decimalPlaces: totalLiquidity.decimalPlaces) {
			let minimum = expectedAmount * Decimal(slippage)
			let minAmount = TokenAmount(fromNormalisedAmount: minimum, decimalPlaces: expectedAmount.decimalPlaces)
			
			return (expected: expectedAmount, minimum: minAmount)
			
		} else {
			return nil
		}
	}
	
	/**
	Calculate the amount of Token that is required to send along side your XTZ
	- parameter xtzToDeposit: The amount of XTZ to send
	- parameter xtzPool: The XTZ currently held in the dex contract
	- parameter tokenPool: The Token currently held in the dex contract
	- returns: `TokenAmount` The amount of token required to send with the given amount of XTZ
	*/
	public func addLiquidityTokenRequired(xtzToDeposit: XTZAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, dex: TezToolDex) -> TokenAmount? {
		let xtzIn = xtzToDeposit.rpcRepresentation
		let xPool = xtzPool.rpcRepresentation
		let tPool = tokenPool.rpcRepresentation
		let settings = DexCalculationService.settings(forDex: dex)
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("addLiquidityTokenIn"),
			  let result = inner.call(withArguments: [xtzIn, xPool, tPool, settings.includeSubsidy]) else {
			return nil
		}
		
		return TokenAmount(fromRpcAmount: result.toString(), decimalPlaces: tokenPool.decimalPlaces)
	}
	
	/**
	Calculate the amount of XTZ that is required to send along side your Token
	- parameter tokenToDeposit: The amount of Token to send
	- parameter xtzPool: The XTZ currently held in the dex contract
	- parameter tokenPool: The Token currently held in the dex contract
	- returns: `XTZAmount` The amount of XTZ required to send with the given amount of Token
	*/
	public func addLiquidityXtzRequired(tokenToDeposit: TokenAmount, xtzPool: XTZAmount, tokenPool: TokenAmount, dex: TezToolDex) -> XTZAmount? {
		let tokenIn = tokenToDeposit.rpcRepresentation
		let xPool = xtzPool.rpcRepresentation
		let tPool = tokenPool.rpcRepresentation
		let settings = DexCalculationService.settings(forDex: dex)
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("addLiquidityXtzIn"),
			  let result = inner.call(withArguments: [tokenIn, xPool, tPool, settings.includeSubsidy]) else {
			return nil
		}
		
		return XTZAmount(fromRpcAmount: result.toString())
	}
	
	
	
	// MARK: Remove Liquidity
	
	/**
	Calculate the amount of token a user would revice back if they burned X liquidity
	- parameter liquidityBurned: The amount of liquidity to burn
	- parameter totalLiquidity: The totla liquidity held in the dex contract
	- parameter tokenPool: The total token held in the dex contract
	- parameter slippage: Percentage (must be between 0 and 1) of maximum amount of slippage the user is willing to accept
	- returns: `TokenAmount` The amount of Token that would be returned
	*/
	public func removeLiquidityTokenReceived(liquidityBurned: TokenAmount, totalLiquidity: TokenAmount, tokenPool: TokenAmount, slippage: Double) -> (expected: TokenAmount, minimum: TokenAmount)? {
		guard slippage >= 0, slippage <= 1 else {
			os_log("slippage value supplied to `removeLiquidityTokenReceived` was not between 0 and 1: %@", log: .kukaiCoreSwift, type: .error, slippage)
			return nil
		}
		
		let lqtBurned = liquidityBurned.rpcRepresentation
		let tLqt = totalLiquidity.rpcRepresentation
		let tPool = tokenPool.rpcRepresentation
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("removeLiquidityTokenOut"),
			  let result = inner.call(withArguments: [lqtBurned, tLqt, tPool]) else {
			return nil
		}
		
		if let expectedAmount = TokenAmount(fromRpcAmount: result.toString(), decimalPlaces: tokenPool.decimalPlaces) {
			let minimum = expectedAmount * Decimal(slippage)
			let minAmount = TokenAmount(fromNormalisedAmount: minimum, decimalPlaces: expectedAmount.decimalPlaces)
			
			return (expected: expectedAmount, minimum: minAmount)
			
		} else {
			return nil
		}
	}
	
	/**
	Calculate the amount of XTZ a user would revice back if they burned X liquidity
	- parameter liquidityBurned: The amount of liquidity to burn
	- parameter totalLiquidity: The totla liquidity held in the dex contract
	- parameter xtzPool: The total XTZ held in the dex contract
	- parameter slippage: Percentage (must be between 0 and 1) of maximum amount of slippage the user is willing to accept
	- returns: `XTZAmount` The amount of XTZ that would be returned
	*/
	public func removeLiquidityXtzReceived(liquidityBurned: TokenAmount, totalLiquidity: TokenAmount, xtzPool: XTZAmount, slippage: Double, dex: TezToolDex) -> (expected: XTZAmount, minimum: XTZAmount)? {
		guard slippage >= 0, slippage <= 1 else {
			os_log("slippage value supplied to `removeLiquidityXtzReceived` was not between 0 and 1: %@", log: .kukaiCoreSwift, type: .error, slippage)
			return nil
		}
		
		let lqtBurned = liquidityBurned.rpcRepresentation
		let tLqt = totalLiquidity.rpcRepresentation
		let xPool = xtzPool.rpcRepresentation
		let settings = DexCalculationService.settings(forDex: dex)
		
		guard let outer = jsContext.objectForKeyedSubscript("dexterCalculations"),
			  let inner = outer.objectForKeyedSubscript("removeLiquidityXtzOut"),
			  let result = inner.call(withArguments: [lqtBurned, tLqt, xPool, settings.includeSubsidy]) else {
			return nil
		}
		
		if let expectedAmount = XTZAmount(fromRpcAmount: result.toString()) {
			let minimum = expectedAmount * Decimal(slippage)
			let minAmount = XTZAmount(fromNormalisedAmount: minimum)
			
			return (expected: expectedAmount, minimum: minAmount)
			
		} else {
			return nil
		}
	}
}
