//
//  DexterCalculationServiceTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class DexterCalculationServiceTests: XCTestCase {
	
	let dexterCalcualtionService = DexterCalculationService.shared
	let USDtzDecimalPlaces = 6
	
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }
	
	
	
	// MARK: - XTZ To Token
	
	func testXtzToTokenExpectedReturn() {
		var xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		var xtzPool = XTZAmount(fromRpcAmount: 1000000000) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 250000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var result = dexterCalcualtionService.xtzToTokenExpectedReturn(xtzToSell: xtzIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "249", result?.rpcRepresentation ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 5) ?? XTZAmount.zero()
		xtzPool = XTZAmount(fromRpcAmount: 100000) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 10, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = dexterCalcualtionService.xtzToTokenExpectedReturn(xtzToSell: xtzIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "0", result?.rpcRepresentation ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 20000) ?? XTZAmount.zero()
		xtzPool =  XTZAmount(fromRpcAmount: 100000) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 10, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = dexterCalcualtionService.xtzToTokenExpectedReturn(xtzToSell: xtzIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "1", result?.rpcRepresentation ?? "-")
	}
	
	func testXtzToTokenRequiredXTZ() {
		var tokenIn = TokenAmount(fromRpcAmount: 2000000, decimalPlaces: 8) ?? TokenAmount.zeroBalance(decimalPlaces: 8)
		var xtzPool = XTZAmount(fromRpcAmount: 38490742927) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 44366268, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var result = dexterCalcualtionService.xtzToTokenRequiredXtzFor(tokenAmount: tokenIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "1822514204", result?.rpcRepresentation ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 23500000, decimalPlaces: 8) ?? TokenAmount.zeroBalance(decimalPlaces: 8)
		xtzPool =  XTZAmount(fromRpcAmount: 3003926688) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 667902216, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = dexterCalcualtionService.xtzToTokenRequiredXtzFor(tokenAmount: tokenIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "109876548", result?.rpcRepresentation ?? "-")
	}
	
	func testXtzToTokenExchangeRate() {
		var xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		var xtzPool = XTZAmount(fromRpcAmount: 34204881343) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 39306268, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var result = dexterCalcualtionService.xtzToTokenExchangeRate(xtzToSell: xtzIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "0.001145", result?.description ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		xtzPool = XTZAmount(fromRpcAmount: 3003226688) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 668057425, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = dexterCalcualtionService.xtzToTokenExchangeRate(xtzToSell: xtzIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "0.221705", result?.description ?? "-")
	}
	
	func testXtzToTokenExchangeRateDisplay() {
		var xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		var xtzPool = XTZAmount(fromRpcAmount: 34204881343) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 39306268, decimalPlaces: 8) ?? XTZAmount.zero()
		var result = dexterCalcualtionService.xtzToTokenExchangeRateDisplay(xtzToSell: xtzIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "0.00001145", result?.description ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		xtzPool = XTZAmount(fromRpcAmount: 3003226688) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 668057425, decimalPlaces: 6) ?? XTZAmount.zero()
		result = dexterCalcualtionService.xtzToTokenExchangeRateDisplay(xtzToSell: xtzIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "0.221705", result?.description ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 100000) ?? XTZAmount.zero()
		xtzPool = XTZAmount(fromRpcAmount: 2000000) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 100000, decimalPlaces: 0) ?? XTZAmount.zero()
		result = dexterCalcualtionService.xtzToTokenExchangeRateDisplay(xtzToSell: xtzIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "47480", result?.description ?? "-")
	}
	
	func testXtzToTokenMarketRate() {
		var xtzPool =  XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: "500000000000000000000", decimalPlaces: 18) ?? XTZAmount.zero()
		var result = dexterCalcualtionService.xtzToTokenMarketRate(dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "500.00000000000006", result?.description ?? "-")
		
		xtzPool = XTZAmount(fromRpcAmount: 144621788919) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 961208019, decimalPlaces: 8) ?? XTZAmount.zero()
		result = dexterCalcualtionService.xtzToTokenMarketRate(dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "0.00006646", result?.description ?? "-")
		
		xtzPool = XTZAmount(fromRpcAmount: 20167031717) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: "41063990114535450000", decimalPlaces: 18) ?? XTZAmount.zero()
		result = dexterCalcualtionService.xtzToTokenMarketRate(dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "0.002036194056258669", result?.description ?? "-")
	}
	
	func testXtzToTokenPriceImpact() {
		var xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		var xtzPool = XTZAmount(fromRpcAmount: 29757960047) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 351953939, decimalPlaces: 8) ?? XTZAmount.zero()
		var result = dexterCalcualtionService.xtzToTokenPriceImpact(xtzToSell: xtzIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "0.01", result?.description ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 20000) ?? XTZAmount.zero()
		xtzPool = XTZAmount(fromRpcAmount: 100000) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 10, decimalPlaces: 8) ?? XTZAmount.zero()
		result = dexterCalcualtionService.xtzToTokenPriceImpact(xtzToSell: xtzIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "50", result?.description ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 10000000) ?? XTZAmount.zero()
		xtzPool =  XTZAmount(fromRpcAmount: 3003226688) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 668057425, decimalPlaces: 6) ?? XTZAmount.zero()
		result = dexterCalcualtionService.xtzToTokenPriceImpact(xtzToSell: xtzIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "0.33", result?.description ?? "-")
	}
	
	func testXtzToTokenMinimumReturn() {
		var tokenIn = TokenAmount(fromRpcAmount: 10000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		var result = dexterCalcualtionService.xtzToTokenMinimumReturn(tokenAmount: tokenIn, slippage: 0.05)
		XCTAssert(result?.description == "9500", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 10000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		result = dexterCalcualtionService.xtzToTokenMinimumReturn(tokenAmount: tokenIn, slippage: 0.01)
		XCTAssert(result?.description == "9900", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 330000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		result = dexterCalcualtionService.xtzToTokenMinimumReturn(tokenAmount: tokenIn, slippage: 0.005)
		XCTAssert(result?.description == "328350", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 1000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		result = dexterCalcualtionService.xtzToTokenMinimumReturn(tokenAmount: tokenIn, slippage: 0.01)
		XCTAssert(result?.description == "990", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 5000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		result = dexterCalcualtionService.xtzToTokenMinimumReturn(tokenAmount: tokenIn, slippage: 0.2)
		XCTAssert(result?.description == "4000", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 100, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		result = dexterCalcualtionService.xtzToTokenMinimumReturn(tokenAmount: tokenIn, slippage: 0.055)
		XCTAssert(result?.description == "94", result?.description ?? "-")
	}
	
	func testXtzToTokenAllInOne() {
		var xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		var xtzPool = XTZAmount(fromRpcAmount: 1000000000) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 250000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var result = dexterCalcualtionService.calculateXtzToToken(xtzToSell: xtzIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool, maxSlippage: 0.05)
		
		XCTAssert(result?.expected.rpcRepresentation == "249", result?.expected.rpcRepresentation ?? "-")
		XCTAssert(result?.minimum.rpcRepresentation == "236", result?.minimum.rpcRepresentation ?? "-")
		XCTAssert(result?.displayExchangeRate.description == "0.000249", result?.displayExchangeRate.description ?? "-")
		XCTAssert(result?.displayPriceImpact.description == "0.4", result?.displayPriceImpact.description ?? "-")
		
		
		xtzIn = XTZAmount(fromRpcAmount: 1754311) ?? XTZAmount.zero()
		xtzPool = XTZAmount(fromRpcAmount: 1000000000) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 250000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = dexterCalcualtionService.calculateXtzToToken(xtzToSell: xtzIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool, maxSlippage: 0.05)
		
		XCTAssert(result?.expected.rpcRepresentation == "436", result?.expected.rpcRepresentation ?? "-")
		XCTAssert(result?.minimum.rpcRepresentation == "414", result?.minimum.rpcRepresentation ?? "-")
		XCTAssert(result?.displayExchangeRate.description == "0.000249", result?.displayExchangeRate.description ?? "-")
		XCTAssert(result?.displayPriceImpact.description == "0.36", result?.displayPriceImpact.description ?? "-")
	}
	
	
	
	// MARK: - Token To XTZ
	
	func testTokenToXtzExpectedReturn() {
		var tokenIn = TokenAmount(fromRpcAmount: 1000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		var xtzPool =  XTZAmount(fromRpcAmount: 20000000) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 1000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var result = dexterCalcualtionService.tokenToXtzExpectedReturn(tokenToSell: tokenIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "9984977", result?.rpcRepresentation ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 1000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		xtzPool =  XTZAmount(fromRpcAmount: 37412394) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 42000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = dexterCalcualtionService.tokenToXtzExpectedReturn(tokenToSell: tokenIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "867506", result?.rpcRepresentation ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 1000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		xtzPool =  XTZAmount(fromRpcAmount: 94441241342423) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 97000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = dexterCalcualtionService.tokenToXtzExpectedReturn(tokenToSell: tokenIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "960824490733", result?.rpcRepresentation ?? "-")
	}
	
	func testTokenToXtzRequiredXTZ() {
		var xtzIn = XTZAmount(fromRpcAmount: 12000000) ?? XTZAmount.zero()
		var xtzPool =  XTZAmount(fromRpcAmount: 38490742927) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 44366268, decimalPlaces: 8) ?? XTZAmount.zero()
		var result = dexterCalcualtionService.tokenToXtzRequiredTokenFor(xtzAmount: xtzIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "13877", result?.rpcRepresentation ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		xtzPool =  XTZAmount(fromRpcAmount: 3003926688) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 667902216, decimalPlaces: 6) ?? XTZAmount.zero()
		result = dexterCalcualtionService.tokenToXtzRequiredTokenFor(xtzAmount: xtzIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.rpcRepresentation == "223086", result?.rpcRepresentation ?? "-")
	}
	
	func testTokenToXtzExchangeRate() {
		var tokenIn = TokenAmount(fromRpcAmount: 100000000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		var xtzPool = XTZAmount(fromRpcAmount: 38490742927) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 44366268, decimalPlaces: 8) ?? XTZAmount.zero()
		var result = dexterCalcualtionService.tokenToXtzExchangeRate(tokenToSell: tokenIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "266.37235232", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 34000000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		xtzPool = XTZAmount(fromRpcAmount: 3003926688) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 667902216, decimalPlaces: 6) ?? XTZAmount.zero()
		result = dexterCalcualtionService.tokenToXtzExchangeRate(tokenToSell: tokenIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "4.267475029411765", result?.description ?? "-")
	}
	
	func testTokenToXtzExchangeRateDisplay() {
		var tokenIn = TokenAmount(fromRpcAmount: 100000000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		var xtzPool = XTZAmount(fromRpcAmount: 38490742927) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 44366268, decimalPlaces: 8) ?? XTZAmount.zero()
		var result = dexterCalcualtionService.tokenToXtzExchangeRateDisplay(tokenToSell: tokenIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "26637.235232", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 34000000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		xtzPool = XTZAmount(fromRpcAmount: 3003926688) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 667902216, decimalPlaces: 6) ?? XTZAmount.zero()
		result = dexterCalcualtionService.tokenToXtzExchangeRateDisplay(tokenToSell: tokenIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "4.267475", result?.description ?? "-")
	}
	
	func testTokenToXtzMarketRate() {
		var xtzPool = XTZAmount(fromRpcAmount: 1000000) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: "500000000000000000000", decimalPlaces: 18) ?? XTZAmount.zero()
		var result = dexterCalcualtionService.tokenToXtzMarketRate(dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "0.002", result?.description ?? "-")
		
		xtzPool = XTZAmount(fromRpcAmount: 144621788919) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: "961208019", decimalPlaces: 8) ?? XTZAmount.zero()
		result = dexterCalcualtionService.tokenToXtzMarketRate(dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "15045.83670343", result?.description ?? "-")
		
		xtzPool = XTZAmount(fromRpcAmount: 46296642164) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: "110543540642", decimalPlaces: 6) ?? XTZAmount.zero()
		result = dexterCalcualtionService.tokenToXtzMarketRate(dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "0.418809", result?.description ?? "-")
	}
	
	func testTokenToXtzPriceImpact() {
		var tokenIn = TokenAmount(fromRpcAmount: 100000000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		var xtzPool = XTZAmount(fromRpcAmount: 3849181242) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 44365061, decimalPlaces: 8) ?? XTZAmount.zero()
		var result = dexterCalcualtionService.tokenToXtzPriceImpact(tokenToSell: tokenIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "69.27", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 40000000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		xtzPool = XTZAmount(fromRpcAmount: 3849181242) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 44365061, decimalPlaces: 8) ?? XTZAmount.zero()
		result = dexterCalcualtionService.tokenToXtzPriceImpact(tokenToSell: tokenIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "47.41", result?.description ?? "-")
		
		tokenIn = TokenAmount(fromRpcAmount: 1000000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		xtzPool = XTZAmount(fromRpcAmount: 2869840667) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 699209512, decimalPlaces: 6) ?? XTZAmount.zero()
		result = dexterCalcualtionService.tokenToXtzPriceImpact(tokenToSell: tokenIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool)
		XCTAssert(result?.description == "0.14", result?.description ?? "-")
	}
	
	func testTokenToXtzMinimumReturn() {
		var xtzIn = XTZAmount(fromRpcAmount: 10000) ?? XTZAmount.zero()
		var result = dexterCalcualtionService.tokenToXtzMinimumReturn(xtzAmount: xtzIn, slippage: 0.05)
		XCTAssert(result?.rpcRepresentation == "9500", result?.rpcRepresentation ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 10000) ?? XTZAmount.zero()
		result = dexterCalcualtionService.tokenToXtzMinimumReturn(xtzAmount: xtzIn, slippage: 0.01)
		XCTAssert(result?.rpcRepresentation == "9900", result?.rpcRepresentation ?? "-")
		
		xtzIn = XTZAmount(fromRpcAmount: 330000) ?? XTZAmount.zero()
		result = dexterCalcualtionService.tokenToXtzMinimumReturn(xtzAmount: xtzIn, slippage: 0.005)
		XCTAssert(result?.rpcRepresentation == "328350", result?.rpcRepresentation ?? "-")
	}
	
	func testTokenToXtzAllInOne() {
		var tokenIn = TokenAmount(fromRpcAmount: 1000, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		var xtzPool =  XTZAmount(fromRpcAmount: 20000000) ?? XTZAmount.zero()
		var tokenPool = TokenAmount(fromRpcAmount: 1000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		var result = dexterCalcualtionService.calcualteTokenToXTZ(tokenToSell: tokenIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool, maxSlippage: 0.05)
		
		XCTAssert(result?.expected.rpcRepresentation == "9984977", result?.expected.rpcRepresentation ?? "-")
		XCTAssert(result?.minimum.rpcRepresentation == "9485728", result?.minimum.rpcRepresentation ?? "-")
		XCTAssert(result?.displayExchangeRate.description == "9984.977", result?.displayExchangeRate.description ?? "-")
		XCTAssert(result?.displayPriceImpact.description == "50.0", result?.displayPriceImpact.description ?? "-")
		
		
		tokenIn = TokenAmount(fromRpcAmount: 1754311, decimalPlaces: 0) ?? TokenAmount.zeroBalance(decimalPlaces: 0)
		xtzPool = XTZAmount(fromRpcAmount: 1000000000) ?? XTZAmount.zero()
		tokenPool = TokenAmount(fromRpcAmount: 250000, decimalPlaces: USDtzDecimalPlaces) ?? XTZAmount.zero()
		result = dexterCalcualtionService.calcualteTokenToXTZ(tokenToSell: tokenIn, dexterXtzPool: xtzPool, dexterTokenPool: tokenPool, maxSlippage: 0.05)
		
		XCTAssert(result?.expected.rpcRepresentation == "874940475", result?.expected.rpcRepresentation ?? "-")
		XCTAssert(result?.minimum.rpcRepresentation == "831193451", result?.minimum.rpcRepresentation ?? "-")
		XCTAssert(result?.displayExchangeRate.description == "498.737382", result?.displayExchangeRate.description ?? "-")
		XCTAssert(result?.displayPriceImpact.description == "87.53", result?.displayPriceImpact.description ?? "-")
	}
}
