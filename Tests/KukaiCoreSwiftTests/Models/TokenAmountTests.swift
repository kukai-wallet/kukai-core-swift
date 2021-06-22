//
//  TokenAmountTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class TokenAmountTests: XCTestCase {

    override func setUpWithError() throws {
		
    }

    override func tearDownWithError() throws {
		
    }
	
	
	
	func testNormalisedAmounts() {
		let test1 = TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 0)
		let test1_formatUS = test1.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test1_formatSpain = test1.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test1.normalisedRepresentation == "1", test1.normalisedRepresentation)
		XCTAssert(test1.toNormalisedDecimal() == 1, test1.toNormalisedDecimal()?.description ?? "-")
		XCTAssert(test1.rpcRepresentation == "1", test1.rpcRepresentation)
		XCTAssert(test1.toRpcDecimal() == 1, test1.toRpcDecimal()?.description ?? "-")
		XCTAssert(test1_formatUS == "1", test1_formatUS ?? "-")
		XCTAssert(test1_formatSpain == "1", test1_formatSpain ?? "-")
		
		
		let test2 = TokenAmount(fromNormalisedAmount: 17, decimalPlaces: 0)
		let test2_formatUS = test2.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test2_formatSpain = test2.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test2.normalisedRepresentation == "17", test2.normalisedRepresentation)
		XCTAssert(test2.toNormalisedDecimal() == 17, test2.toNormalisedDecimal()?.description ?? "-")
		XCTAssert(test2.rpcRepresentation == "17", test2.rpcRepresentation)
		XCTAssert(test2.toRpcDecimal() == 17, test2.toRpcDecimal()?.description ?? "-")
		XCTAssert(test2_formatUS == "17", test2_formatUS ?? "-")
		XCTAssert(test2_formatSpain == "17", test2_formatSpain ?? "-")
		
		
		let test3 = TokenAmount(fromNormalisedAmount: 29.123456, decimalPlaces: 6)
		let test3_formatUS = test3.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test3_formatSpain = test3.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test3.normalisedRepresentation == "29.123456", test3.normalisedRepresentation)
		XCTAssert(test3.toNormalisedDecimal() == 29.123456, test3.toNormalisedDecimal()?.description ?? "-")
		XCTAssert(test3.rpcRepresentation == "29123456", test3.rpcRepresentation)
		XCTAssert(test3.toRpcDecimal() == 29123456, test3.toRpcDecimal()?.description ?? "-")
		XCTAssert(test3_formatUS == "29.123456", test3_formatUS ?? "-")
		XCTAssert(test3_formatSpain == "29,123456", test3_formatSpain ?? "-")
		

		let test4 = TokenAmount(fromNormalisedAmount: 137615.12345678901234, decimalPlaces: 8)
		let test4_formatUS = test4.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test4_formatSpain = test4.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test4.normalisedRepresentation == "137615.12345678", test4.normalisedRepresentation)
		XCTAssert(test4.toNormalisedDecimal() == Decimal(137615.12345678).rounded(scale: 8, roundingMode: .down), test4.toNormalisedDecimal()?.description ?? "-")
		XCTAssert(test4.rpcRepresentation == "13761512345678", test4.rpcRepresentation)
		XCTAssert(test4.toRpcDecimal() == Decimal(13761512345678), test4.toRpcDecimal()?.description ?? "-")
		XCTAssert(test4_formatUS == "137,615.12345678", test4_formatUS ?? "-")
		XCTAssert(test4_formatSpain == "137.615,12345678", test4_formatSpain ?? "-")
	}
	
	func testRpcAmounts() {
		let test1 = TokenAmount(fromRpcAmount: 1, decimalPlaces: 0)
		let test1_formatUS = test1?.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test1_formatSpain = test1?.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test1?.normalisedRepresentation == "1", test1?.normalisedRepresentation ?? "-")
		XCTAssert(test1?.toNormalisedDecimal() == 1, test1?.toNormalisedDecimal()?.description ?? "-")
		XCTAssert(test1?.rpcRepresentation == "1", test1?.rpcRepresentation ?? "-")
		XCTAssert(test1?.toRpcDecimal() == 1, test1?.toRpcDecimal()?.description ?? "-")
		XCTAssert(test1_formatUS == "1", test1_formatUS ?? "-")
		XCTAssert(test1_formatSpain == "1", test1_formatSpain ?? "-")
		
		
		let test2 = TokenAmount(fromRpcAmount: 17, decimalPlaces: 0)
		let test2_formatUS = test2?.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test2_formatSpain = test2?.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test2?.normalisedRepresentation == "17", test2?.normalisedRepresentation ?? "-")
		XCTAssert(test2?.toNormalisedDecimal() == 17, test2?.toNormalisedDecimal()?.description ?? "-")
		XCTAssert(test2?.rpcRepresentation == "17", test2?.rpcRepresentation ?? "-")
		XCTAssert(test2?.toRpcDecimal() == 17, test2?.toRpcDecimal()?.description ?? "-")
		XCTAssert(test2_formatUS == "17", test2_formatUS ?? "-")
		XCTAssert(test2_formatSpain == "17", test2_formatSpain ?? "-")
		
		
		let test3 = TokenAmount(fromRpcAmount: 29123456, decimalPlaces: 6)
		let test3_formatUS = test3?.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test3_formatSpain = test3?.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test3?.normalisedRepresentation == "29.123456", test3?.normalisedRepresentation ?? "-")
		XCTAssert(test3?.toNormalisedDecimal() == 29.123456, test3?.toNormalisedDecimal()?.description ?? "-")
		XCTAssert(test3?.rpcRepresentation == "29123456", test3?.rpcRepresentation ?? "-")
		XCTAssert(test3?.toRpcDecimal() == 29123456, test3?.toRpcDecimal()?.description ?? "-")
		XCTAssert(test3_formatUS == "29.123456", test3_formatUS ?? "-")
		XCTAssert(test3_formatSpain == "29,123456", test3_formatSpain ?? "-")
		
		
		let test4 = TokenAmount(fromRpcAmount: "13761512345678901234", decimalPlaces: 8)
		let test4_formatUS = test4?.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test4_formatSpain = test4?.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test4?.normalisedRepresentation == "137615123456.78901234", test4?.normalisedRepresentation ?? "-")
		XCTAssert(test4?.rpcRepresentation == "13761512345678901234", test4?.rpcRepresentation ?? "-")
		XCTAssert(test4?.toRpcDecimal() == Decimal(string: "13761512345678901234"), test4?.toRpcDecimal()?.description ?? "-")
		XCTAssert(test4_formatUS == "137,615,123,456.78901234", test4_formatUS ?? "-")
		XCTAssert(test4_formatSpain == "137.615.123.456,78901234", test4_formatSpain ?? "-")
		
		
		let test5 = TokenAmount(fromRpcAmount: 14.2, decimalPlaces: 8)
		XCTAssert(test5 == nil)
		
		let test6 = TokenAmount(fromRpcAmount: "14.2", decimalPlaces: 8)
		XCTAssert(test6 == nil)
	}
	
	func testArithmetic() {
		
		// Test multiple decimal places fails
		var first = TokenAmount(fromNormalisedAmount: 10, decimalPlaces: 0)
		var second = TokenAmount(fromNormalisedAmount: 17, decimalPlaces: 1)
		var result = first + second
		XCTAssert(result.description == "0", result.description)
		
		
		// Addition
		first = TokenAmount(fromNormalisedAmount: 10, decimalPlaces: 0)
		second = TokenAmount(fromNormalisedAmount: 17, decimalPlaces: 0)
		result = first + second
		XCTAssert(result.description == "27", result.description)
		
		first = TokenAmount(fromNormalisedAmount: 10.14, decimalPlaces: 2)
		second = TokenAmount(fromNormalisedAmount: 17.37, decimalPlaces: 2)
		result = first + second
		XCTAssert(result.description == "27.51", result.description)
		
		
		// Subtraction
		first = TokenAmount(fromNormalisedAmount: 17, decimalPlaces: 0)
		second = TokenAmount(fromNormalisedAmount: 10, decimalPlaces: 0)
		result = first - second
		XCTAssert(result.description == "7", result.description)
		
		first = TokenAmount(fromNormalisedAmount: 17.37, decimalPlaces: 2)
		second = TokenAmount(fromNormalisedAmount: 10.14, decimalPlaces: 2)
		result = first - second
		XCTAssert(result.description == "7.23", result.description)
		
		first = TokenAmount(fromNormalisedAmount: 10.14, decimalPlaces: 2)
		second = TokenAmount(fromNormalisedAmount: 17.37, decimalPlaces: 2)
		result = first - second
		XCTAssert(result.description == "-7.23", result.description)
		
		
		// Multiplcation
		first = TokenAmount(fromNormalisedAmount: 17, decimalPlaces: 0)
		result = first * 4
		XCTAssert(result.description == "68", result.description)
		
		first = TokenAmount(fromNormalisedAmount: 17.42, decimalPlaces: 2)
		let decimalResult = first * 4.5
		XCTAssert(decimalResult.description == "78.39", decimalResult.description)
	}
	
	func testEquatable() {
		var first = TokenAmount(fromNormalisedAmount: 10, decimalPlaces: 0)
		var second = TokenAmount(fromNormalisedAmount: 10, decimalPlaces: 0)
		XCTAssert(first == second)
		
		first = TokenAmount(fromNormalisedAmount: 10, decimalPlaces: 0)
		second = TokenAmount(fromNormalisedAmount: 17, decimalPlaces: 0)
		XCTAssert(first != second)
	}
	
	func testNegativeValues() {
		let first = TokenAmount(fromNormalisedAmount: 916.130192, decimalPlaces: 6)
		let second = TokenAmount(fromNormalisedAmount: 0.000489, decimalPlaces: 6)
		
		let newValue = (first - (first + second))
		XCTAssert(newValue.normalisedRepresentation == "-0.000489", newValue.normalisedRepresentation)
		XCTAssert(newValue.toNormalisedDecimal()?.description == "-0.000489", newValue.toNormalisedDecimal()?.description ?? "-")
		XCTAssert(newValue.rpcRepresentation == "-489", newValue.rpcRepresentation)
		XCTAssert(newValue.toRpcDecimal()?.description == "-489", newValue.toRpcDecimal()?.description ?? "-")
		
		let addition = (newValue + second)
		XCTAssert(addition == TokenAmount.zeroBalance(decimalPlaces: 6), addition.description)
	}
}
