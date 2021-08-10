//
//  LiquidityBakingCalculationServiceTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class LiquidityBakingCalculationServiceTests: XCTestCase {
	
	let liquidityBakingCalcualtionService = LiquidityBakingCalculationService.shared
	let USDtzDecimalPlaces = 6
	
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }
	
	
	// MARK: - Supplied mock data tests
	
	func testXtzToToken() {
		guard let mockPath = Bundle.module.url(forResource: "xtz_to_token", withExtension: "json", subdirectory: "MockData"),
			  let mockData = try? Data(contentsOf: mockPath),
			  let jsonObj = try? JSONSerialization.jsonObject(with: mockData, options: .allowFragments) as? [[String: String]] else {
			XCTFail("Can't parse Mock json ")
			return
		}
		
		for dataSet in jsonObj {
			guard let xPool = dataSet["xtz_pool"],
				  let tPool = dataSet["token_pool"],
				  let xtzIn = dataSet["xtz_in"],
				  let tokenOut = dataSet["token_out"],
				  let priceImpact = dataSet["price_impact"] else {
				XCTFail("Can't get data")
				return
			}
			
			let result = liquidityBakingCalcualtionService.calculateXtzToToken(xtzToSell: XTZAmount(fromRpcAmount: xtzIn) ?? XTZAmount.zero(), xtzPool: XTZAmount(fromRpcAmount: xPool) ?? XTZAmount.zero(), tokenPool: TokenAmount(fromRpcAmount: tPool, decimalPlaces: 0) ?? TokenAmount.zero(), maxSlippage: 0)
			let impactAsPercentage = (Decimal(string: priceImpact)?.rounded(scale: 4, roundingMode: .bankers) ?? 0) * 100
			
			XCTAssert(result?.expected.rpcRepresentation == tokenOut, "\(result?.expected.rpcRepresentation ?? "") != \(tokenOut)")
			XCTAssert(result?.displayPriceImpact == Double(impactAsPercentage.description), "\(result?.displayPriceImpact ?? -1) != \(Double(impactAsPercentage.description) ?? -1)")
		}
	}
	
	func testTokenToXtz() {
		guard let mockPath = Bundle.module.url(forResource: "token_to_xtz", withExtension: "json", subdirectory: "MockData"),
			  let mockData = try? Data(contentsOf: mockPath),
			  let jsonObj = try? JSONSerialization.jsonObject(with: mockData, options: .allowFragments) as? [[String: String]] else {
			XCTFail("Can't parse Mock json ")
			return
		}
		
		for dataSet in jsonObj {
			guard let xPool = dataSet["xtz_pool"],
				  let tPool = dataSet["token_pool"],
				  let tokenIn = dataSet["token_in"],
				  let xtzOut = dataSet["xtz_out"],
				  let priceImpact = dataSet["price_impact"] else {
				XCTFail("Can't get data")
				return
			}
			
			let result = liquidityBakingCalcualtionService.calculateTokenToXTZ(tokenToSell: TokenAmount(fromRpcAmount: tokenIn, decimalPlaces: 0) ?? TokenAmount.zero(), xtzPool: XTZAmount(fromRpcAmount: xPool) ?? XTZAmount.zero(), tokenPool: TokenAmount(fromRpcAmount: tPool, decimalPlaces: 0) ?? TokenAmount.zero(), maxSlippage: 0)
			let impactAsPercentage = (Decimal(string: priceImpact)?.rounded(scale: 4, roundingMode: .bankers) ?? 0) * 100
			
			XCTAssert(result?.expected.rpcRepresentation == xtzOut, "\(result?.expected.rpcRepresentation ?? "") != \(xtzOut)")
			XCTAssert(result?.displayPriceImpact == Double(impactAsPercentage.description), "\(result?.displayPriceImpact ?? -1) != \(Double(impactAsPercentage.description) ?? -1)")
		}
	}
	
	
	
	// MARK: - XTZ To Token
	
	func testXtzToTokenExpectedReturn() {
		var xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		var xtzPool = XTZAmount(fromRpcAmount: 1000000000) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 250000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.xtzToTokenExpectedReturn(xtzToSell: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "248", result?.rpcRepresentation ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 5) ?? XTZAmount.zero()
		xtzPool = XTZAmount(fromRpcAmount: 100000) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 10, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.xtzToTokenExpectedReturn(xtzToSell: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "0", result?.rpcRepresentation ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 20000) ?? XTZAmount.zero()
		xtzPool =  XTZAmount(fromRpcAmount: 100000) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 10, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.xtzToTokenExpectedReturn(xtzToSell: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "0", result?.rpcRepresentation ?? "-")
	}
	
	func testXtzToTokenRequiredXTZ() {
		var tokenIn = TokenAmount(fromRpcAmount: 2000000, decimalPlaces: 8) ?? TokenAmount.zeroBalance(decimalPlaces: 8)
		var xtzPool = XTZAmount(fromRpcAmount: 38490742927) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 44366268, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.xtzToTokenRequiredXtzFor(tokenAmount: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "1820804468", result?.rpcRepresentation ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 23500000, decimalPlaces: 8) ?? TokenAmount.zeroBalance(decimalPlaces: 8)
		xtzPool =  XTZAmount(fromRpcAmount: 3003926688) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 667902216, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.xtzToTokenRequiredXtzFor(tokenAmount: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "109857694", result?.rpcRepresentation ?? "-")
	}
	
	func testXtzToTokenExchangeRate() {
		var xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		var xtzPool = XTZAmount(fromRpcAmount: 34204881343) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 39306268, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.xtzToTokenExchangeRate(xtzToSell: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "0.001146", result?.description ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		xtzPool = XTZAmount(fromRpcAmount: 3003226688) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 668057425, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.xtzToTokenExchangeRate(xtzToSell: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "0.221743", result?.description ?? "-")
	}
	
	func testXtzToTokenExchangeRateDisplay() {
		var xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		var xtzPool = XTZAmount(fromRpcAmount: 34204881343) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 39306268, decimalPlaces: 8) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.xtzToTokenExchangeRateDisplay(xtzToSell: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "0.00001146", result?.description ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		xtzPool = XTZAmount(fromRpcAmount: 3003226688) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 668057425, decimalPlaces: 6) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.xtzToTokenExchangeRateDisplay(xtzToSell: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "0.002217", result?.description ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 100000) ?? XTZAmount.zero()
		xtzPool = XTZAmount(fromRpcAmount: 2000000) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 100000, decimalPlaces: 0) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.xtzToTokenExchangeRateDisplay(xtzToSell: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "0", result?.description ?? "-")
	}
	
	func testXtzToTokenMarketRate() {
		var xtzPool =  XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: "500000000000000000000", decimalPlaces: 18) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.xtzToTokenMarketRate(xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "500.00000000000006", result?.description ?? "-")
		
		xtzPool = XTZAmount(fromRpcAmount: 144621788919) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 961208019, decimalPlaces: 8) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.xtzToTokenMarketRate(xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "0.00006646", result?.description ?? "-")
		
		xtzPool = XTZAmount(fromRpcAmount: 20167031717) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: "41063990114535450000", decimalPlaces: 18) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.xtzToTokenMarketRate(xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "0.002036194056258669", result?.description ?? "-")
	}
	
	func testXtzToTokenPriceImpact() {
		var xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		var xtzPool = XTZAmount(fromRpcAmount: 29757960047) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 351953939, decimalPlaces: 8) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.xtzToTokenPriceImpact(xtzToSell: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "0.1", result?.description ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 20000) ?? XTZAmount.zero()
		xtzPool = XTZAmount(fromRpcAmount: 100000) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 10, decimalPlaces: 8) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.xtzToTokenPriceImpact(xtzToSell: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "0", result?.description ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 10000000) ?? XTZAmount.zero()
		xtzPool =  XTZAmount(fromRpcAmount: 3003226688) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 668057425, decimalPlaces: 6) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.xtzToTokenPriceImpact(xtzToSell: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "0.43", result?.description ?? "-")
	}
	
	func testXtzToTokenMinimumReturn() {
		var tokenIn = TokenAmount(fromRpcAmount: 10000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		var result = liquidityBakingCalcualtionService.xtzToTokenMinimumReturn(tokenAmount: tokenIn, slippage: 0.05)
		XCTAssert(result?.description == "9500", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 10000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		result = liquidityBakingCalcualtionService.xtzToTokenMinimumReturn(tokenAmount: tokenIn, slippage: 0.01)
		XCTAssert(result?.description == "9900", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 330000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		result = liquidityBakingCalcualtionService.xtzToTokenMinimumReturn(tokenAmount: tokenIn, slippage: 0.005)
		XCTAssert(result?.description == "328350", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 1000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		result = liquidityBakingCalcualtionService.xtzToTokenMinimumReturn(tokenAmount: tokenIn, slippage: 0.01)
		XCTAssert(result?.description == "990", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 5000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		result = liquidityBakingCalcualtionService.xtzToTokenMinimumReturn(tokenAmount: tokenIn, slippage: 0.2)
		XCTAssert(result?.description == "4000", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 100, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		result = liquidityBakingCalcualtionService.xtzToTokenMinimumReturn(tokenAmount: tokenIn, slippage: 0.055)
		XCTAssert(result?.description == "94", result?.description ?? "-")
	}
	
	func testXtzToTokenAllInOne() {
		var xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		var xtzPool = XTZAmount(fromRpcAmount: 1000000000) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 250000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.calculateXtzToToken(xtzToSell: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool, maxSlippage: 0.05)
		
		XCTAssert(result?.expected.rpcRepresentation == "248", result?.expected.rpcRepresentation ?? "-")
		XCTAssert(result?.minimum.rpcRepresentation == "235", result?.minimum.rpcRepresentation ?? "-")
		XCTAssert(result?.displayExchangeRate.description == "0.000002", result?.displayExchangeRate.description ?? "-")
		XCTAssert(result?.displayPriceImpact.description == "0.55", result?.displayPriceImpact.description ?? "-")
		
		
		xtzIn = XTZAmount(fromRpcAmount: 1754311) ?? XTZAmount.zero()
		xtzPool = XTZAmount(fromRpcAmount: 1000000000) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 250000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.calculateXtzToToken(xtzToSell: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool, maxSlippage: 0.05)
		
		XCTAssert(result?.expected.rpcRepresentation == "435", result?.expected.rpcRepresentation ?? "-")
		XCTAssert(result?.minimum.rpcRepresentation == "413", result?.minimum.rpcRepresentation ?? "-")
		XCTAssert(result?.displayExchangeRate.description == "0.000002", result?.displayExchangeRate.description ?? "-")
		XCTAssert(result?.displayPriceImpact.description == "0.34", result?.displayPriceImpact.description ?? "-")
	}
	
	
	
	// MARK: - Token To XTZ
	
	func testTokenToXtzExpectedReturn() {
		var tokenIn = TokenAmount(fromRpcAmount: 1000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		var xtzPool =  XTZAmount(fromRpcAmount: 20000000) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 1000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.tokenToXtzExpectedReturn(tokenToSell: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "11233127", result?.rpcRepresentation ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 1000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		xtzPool =  XTZAmount(fromRpcAmount: 37412394) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 42000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.tokenToXtzExpectedReturn(tokenToSell: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "926361", result?.rpcRepresentation ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 1000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		xtzPool =  XTZAmount(fromRpcAmount: 94441241342423) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 97000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.tokenToXtzExpectedReturn(tokenToSell: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "961769566995", result?.rpcRepresentation ?? "-")
	}
	
	func testTokenToXtzRequiredXTZ() {
		var xtzIn = XTZAmount(fromRpcAmount: 12000000) ?? XTZAmount.zero()
		var xtzPool =  XTZAmount(fromRpcAmount: 38490742927) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 44366268, decimalPlaces: 8) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.tokenToXtzRequiredTokenFor(xtzAmount: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "13849", result?.rpcRepresentation ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		xtzPool =  XTZAmount(fromRpcAmount: 3003926688) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 667902216, decimalPlaces: 6) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.tokenToXtzRequiredTokenFor(xtzAmount: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "222454", result?.rpcRepresentation ?? "-")
	}
	
	func testTokenToXtzExchangeRate() {
		var tokenIn = TokenAmount(fromRpcAmount: 100000000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		var xtzPool = XTZAmount(fromRpcAmount: 38490742927) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 44366268, decimalPlaces: 8) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.tokenToXtzExchangeRate(tokenToSell: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "266.28743826", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 34000000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		xtzPool = XTZAmount(fromRpcAmount: 3003926688) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 667902216, decimalPlaces: 6) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.tokenToXtzExchangeRate(tokenToSell: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "4.274900558823529", result?.description ?? "-")
	}
	
	func testTokenToXtzExchangeRateDisplay() {
		var tokenIn = TokenAmount(fromRpcAmount: 100000000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		var xtzPool = XTZAmount(fromRpcAmount: 38490742927) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 44366268, decimalPlaces: 8) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.tokenToXtzExchangeRateDisplay(tokenToSell: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "26628.743826", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 34000000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		xtzPool = XTZAmount(fromRpcAmount: 3003926688) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 667902216, decimalPlaces: 6) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.tokenToXtzExchangeRateDisplay(tokenToSell: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "427.490056", result?.description ?? "-")
	}
	
	func testTokenToXtzMarketRate() {
		var xtzPool = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: "500000000000000000000", decimalPlaces: 18) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.tokenToXtzMarketRate(xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "0.0000000000002", result?.description ?? "-")
		
		xtzPool = XTZAmount(fromRpcAmount: 144621788919) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: "961208019", decimalPlaces: 8) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.tokenToXtzMarketRate(xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "15045.83670343", result?.description ?? "-")
		
		xtzPool = XTZAmount(fromRpcAmount: 46296642164) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: "110543540642", decimalPlaces: 6) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.tokenToXtzMarketRate(xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "41.880911", result?.description ?? "-")
	}
	
	func testTokenToXtzPriceImpact() {
		var tokenIn = TokenAmount(fromRpcAmount: 100000000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		var xtzPool = XTZAmount(fromRpcAmount: 3849181242) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 44365061, decimalPlaces: 8) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.tokenToXtzPriceImpact(tokenToSell: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "69.3", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 40000000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		xtzPool = XTZAmount(fromRpcAmount: 3849181242) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 44365061, decimalPlaces: 8) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.tokenToXtzPriceImpact(tokenToSell: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "47.47", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 1000000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		xtzPool = XTZAmount(fromRpcAmount: 2869840667) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 699209512, decimalPlaces: 6) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.tokenToXtzPriceImpact(tokenToSell: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool)
		XCTAssert(result?.description == "0.24", result?.description ?? "-")
	}
	
	func testTokenToXtzMinimumReturn() {
		var xtzIn = XTZAmount(fromRpcAmount: 10000) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.tokenToXtzMinimumReturn(xtzAmount: xtzIn, slippage: 0.05)
		XCTAssert(result?.rpcRepresentation == "9500", result?.rpcRepresentation ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 10000) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.tokenToXtzMinimumReturn(xtzAmount: xtzIn, slippage: 0.01)
		XCTAssert(result?.rpcRepresentation == "9900", result?.rpcRepresentation ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 330000) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.tokenToXtzMinimumReturn(xtzAmount: xtzIn, slippage: 0.005)
		XCTAssert(result?.rpcRepresentation == "328350", result?.rpcRepresentation ?? "-")
	}
	
	func testTokenToXtzAllInOne() {
		var tokenIn = TokenAmount(fromRpcAmount: 1000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		var xtzPool =  XTZAmount(fromRpcAmount: 20000000) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 1000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.calculateTokenToXTZ(tokenToSell: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool, maxSlippage: 0.05)
		
		XCTAssert(result?.expected.rpcRepresentation == "11233127", result?.expected.rpcRepresentation ?? "-")
		XCTAssert(result?.minimum.rpcRepresentation == "10671470", result?.minimum.rpcRepresentation ?? "-")
		XCTAssert(result?.displayExchangeRate.description == "1123312.7", result?.displayExchangeRate.description ?? "-")
		XCTAssert(result?.displayPriceImpact.description == "50.05", result?.displayPriceImpact.description ?? "-")
		
		
		tokenIn = TokenAmount(fromRpcAmount: 1754311, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		xtzPool = XTZAmount(fromRpcAmount: 1000000000) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 250000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.calculateTokenToXTZ(tokenToSell: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool, maxSlippage: 0.05)
		
		XCTAssert(result?.expected.rpcRepresentation == "876470140", result?.expected.rpcRepresentation ?? "-")
		XCTAssert(result?.minimum.rpcRepresentation == "832646633", result?.minimum.rpcRepresentation ?? "-")
		XCTAssert(result?.displayExchangeRate.description == "49960.932811", result?.displayExchangeRate.description ?? "-")
		XCTAssert(result?.displayPriceImpact.description == "87.54", result?.displayPriceImpact.description ?? "-")
	}
	
	
	
	// MARK: - Liquidity
	
	func testAddLiquidityXTZ() {
		var xtzIn = XTZAmount(fromRpcAmount: 27000) ?? XTZAmount.zero()
		var xtzPool =  XTZAmount(fromRpcAmount: 20000000) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 1000000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var totalLqt = TokenAmount(fromRpcAmount: 1000000000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.calculateAddLiquidity(xtz: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool, totalLiquidity: totalLqt, maxSlippage: 0.5)
		
		XCTAssert(result?.tokenRequired.normalisedRepresentation == "0.0012", result?.tokenRequired.normalisedRepresentation ?? "-")
		XCTAssert(result?.expectedLiquidity.normalisedRepresentation == "1.2", result?.expectedLiquidity.normalisedRepresentation ?? "-")
		XCTAssert(result?.minimumLiquidity.normalisedRepresentation == "0.6", result?.minimumLiquidity.normalisedRepresentation ?? "-")
		XCTAssert(result?.exchangeRate.description == "0.000443", result?.exchangeRate.description ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 2103460) ?? XTZAmount.zero()
		xtzPool =  XTZAmount(fromRpcAmount: 20000000) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 1000000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		totalLqt = TokenAmount(fromRpcAmount: 1000000000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.calculateAddLiquidity(xtz: xtzIn, xtzPool: xtzPool, tokenPool: tokenPool, totalLiquidity: totalLqt, maxSlippage: 0.5)
		
		XCTAssert(result?.tokenRequired.normalisedRepresentation == "0.093488", result?.tokenRequired.normalisedRepresentation ?? "-")
		XCTAssert(result?.expectedLiquidity.normalisedRepresentation == "93.487111", result?.expectedLiquidity.normalisedRepresentation ?? "-")
		XCTAssert(result?.minimumLiquidity.normalisedRepresentation == "46.743555", result?.minimumLiquidity.normalisedRepresentation ?? "-")
		XCTAssert(result?.exchangeRate.description == "0.000406", result?.exchangeRate.description ?? "-")
	}
	
	func testAddLiquidityToken() {
		var tokenIn = TokenAmount(fromRpcAmount: 10000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var xtzPool =  XTZAmount(fromRpcAmount: 20000000) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 1000000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var totalLqt = TokenAmount(fromRpcAmount: 1000000000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.calculateAddLiquidity(token: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool, totalLiquidity: totalLqt, maxSlippage: 0.5)
		
		XCTAssert(result?.tokenRequired.normalisedRepresentation == "0.225", result?.tokenRequired.normalisedRepresentation ?? "-")
		XCTAssert(result?.expectedLiquidity.normalisedRepresentation == "10", result?.expectedLiquidity.normalisedRepresentation ?? "-")
		XCTAssert(result?.minimumLiquidity.normalisedRepresentation == "5", result?.minimumLiquidity.normalisedRepresentation ?? "-")
		XCTAssert(result?.exchangeRate.description == "0.000439", result?.exchangeRate.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 2103460, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		xtzPool =  XTZAmount(fromRpcAmount: 20000000) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 1000000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		totalLqt = TokenAmount(fromRpcAmount: 1000000000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.calculateAddLiquidity(token: tokenIn, xtzPool: xtzPool, tokenPool: tokenPool, totalLiquidity: totalLqt, maxSlippage: 0.5)
		
		XCTAssert(result?.tokenRequired.normalisedRepresentation == "47.32785", result?.tokenRequired.normalisedRepresentation ?? "-")
		XCTAssert(result?.expectedLiquidity.normalisedRepresentation == "2103.46", result?.expectedLiquidity.normalisedRepresentation ?? "-")
		XCTAssert(result?.minimumLiquidity.normalisedRepresentation == "1051.73", result?.minimumLiquidity.normalisedRepresentation ?? "-")
		XCTAssert(result?.exchangeRate.description == "0.000143", result?.exchangeRate.description ?? "-")
	}
	
	func testRemoveLiquidity() {
		var burnedLqt = TokenAmount(fromRpcAmount: 5000000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var totalLqt = TokenAmount(fromRpcAmount: 1000000000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var xtzPool =  XTZAmount(fromRpcAmount: 20000000) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 100000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var result = liquidityBakingCalcualtionService.calculateRemoveLiquidity(liquidityBurned: burnedLqt, totalLiquidity: totalLqt, xtzPool: xtzPool, tokenPool: tokenPool, maxSlippage: 0.5)
		
		XCTAssert(result?.expectedToken.normalisedRepresentation == "0.0005", result?.expectedToken.normalisedRepresentation ?? "-")
		XCTAssert(result?.minimumToken.normalisedRepresentation == "0.00025", result?.minimumToken.normalisedRepresentation ?? "-")
		XCTAssert(result?.expectedXTZ.normalisedRepresentation == "0.1125", result?.expectedXTZ.normalisedRepresentation ?? "-")
		XCTAssert(result?.minimumXTZ.normalisedRepresentation == "0.05625", result?.minimumXTZ.normalisedRepresentation ?? "-")
		XCTAssert(result?.exchangeRate.description == "0.000044", result?.exchangeRate.description ?? "-")
		
		burnedLqt = TokenAmount(fromRpcAmount: 5000000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		totalLqt = TokenAmount(fromRpcAmount: 1000000000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		xtzPool =  XTZAmount(fromRpcAmount: 2000000) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 35000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = liquidityBakingCalcualtionService.calculateRemoveLiquidity(liquidityBurned: burnedLqt, totalLiquidity: totalLqt, xtzPool: xtzPool, tokenPool: tokenPool, maxSlippage: 0.5)
		
		XCTAssert(result?.expectedToken.normalisedRepresentation == "0.000175", result?.expectedToken.normalisedRepresentation ?? "-")
		XCTAssert(result?.minimumToken.normalisedRepresentation == "0.000087", result?.minimumToken.normalisedRepresentation ?? "-")
		XCTAssert(result?.expectedXTZ.normalisedRepresentation == "0.0225", result?.expectedXTZ.normalisedRepresentation ?? "-")
		XCTAssert(result?.minimumXTZ.normalisedRepresentation == "0.01125", result?.minimumXTZ.normalisedRepresentation ?? "-")
		XCTAssert(result?.exchangeRate.description == "0.000077", result?.exchangeRate.description ?? "-")
	}
}
