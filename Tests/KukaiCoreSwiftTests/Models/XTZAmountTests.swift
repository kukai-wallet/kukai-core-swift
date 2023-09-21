//
//  XTZAmountTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class XTZAmountTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }
	
	
	func testNormalisedAmounts() {
		let test1 = XTZAmount(fromNormalisedAmount: 1)
		let test1_formatUS = test1.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test1_formatSpain = test1.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test1.normalisedRepresentation == "1", test1.normalisedRepresentation)
		XCTAssert(test1.toNormalisedDecimal() == 1, test1.toNormalisedDecimal()?.description ?? "-")
		XCTAssert(test1.rpcRepresentation == "1000000", test1.rpcRepresentation)
		XCTAssert(test1.toRpcDecimal() == 1000000, test1.toRpcDecimal()?.description ?? "-")
		XCTAssert(test1_formatUS == "1", test1_formatUS ?? "-")
		XCTAssert(test1_formatSpain == "1", test1_formatSpain ?? "-")
		
		
		let test2 = XTZAmount(fromNormalisedAmount: 17)
		let test2_formatUS = test2.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test2_formatSpain = test2.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test2.normalisedRepresentation == "17", test2.normalisedRepresentation)
		XCTAssert(test2.toNormalisedDecimal() == 17, test2.toNormalisedDecimal()?.description ?? "-")
		XCTAssert(test2.rpcRepresentation == "17000000", test2.rpcRepresentation)
		XCTAssert(test2.toRpcDecimal() == 17000000, test2.toRpcDecimal()?.description ?? "-")
		XCTAssert(test2_formatUS == "17", test2_formatUS ?? "-")
		XCTAssert(test2_formatSpain == "17", test2_formatSpain ?? "-")
		
		
		let test3 = XTZAmount(fromNormalisedAmount: 29.123456)
		let test3_formatUS = test3.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test3_formatSpain = test3.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test3.normalisedRepresentation == "29.123456", test3.normalisedRepresentation)
		XCTAssert(test3.toNormalisedDecimal() == 29.123456, test3.toNormalisedDecimal()?.description ?? "-")
		XCTAssert(test3.rpcRepresentation == "29123456", test3.rpcRepresentation)
		XCTAssert(test3.toRpcDecimal() == 29123456, test3.toRpcDecimal()?.description ?? "-")
		XCTAssert(test3_formatUS == "29.123456", test3_formatUS ?? "-")
		XCTAssert(test3_formatSpain == "29,123456", test3_formatSpain ?? "-")
		
		
		let test4 = XTZAmount(fromNormalisedAmount: 137615.123456)
		let test4_formatUS = test4.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test4_formatSpain = test4.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test4.normalisedRepresentation == "137615.123456", test4.normalisedRepresentation)
		XCTAssert(test4.toNormalisedDecimal() == Decimal(137615.123456).rounded(scale: 8, roundingMode: .down), test4.toNormalisedDecimal()?.description ?? "-")
		XCTAssert(test4.rpcRepresentation == "137615123456", test4.rpcRepresentation)
		XCTAssert(test4.toRpcDecimal() == Decimal(137615123456), test4.toRpcDecimal()?.description ?? "-")
		XCTAssert(test4_formatUS == "137,615.123456", test4_formatUS ?? "-")
		XCTAssert(test4_formatSpain == "137.615,123456", test4_formatSpain ?? "-")
	}
	
	func testRpcAmounts() {
		let test1 = XTZAmount(fromRpcAmount: 1)
		let test1_formatUS = test1?.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test1_formatSpain = test1?.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test1?.normalisedRepresentation == "0.000001", test1?.normalisedRepresentation ?? "-")
		XCTAssert(test1?.toNormalisedDecimal() == 0.000001, test1?.toNormalisedDecimal()?.description ?? "-")
		XCTAssert(test1?.rpcRepresentation == "1", test1?.rpcRepresentation ?? "-")
		XCTAssert(test1?.toRpcDecimal() == 1, test1?.toRpcDecimal()?.description ?? "-")
		XCTAssert(test1_formatUS == "0.000001", test1_formatUS ?? "-")
		XCTAssert(test1_formatSpain == "0,000001", test1_formatSpain ?? "-")
		
		
		let test2 = XTZAmount(fromRpcAmount: 17)
		let test2_formatUS = test2?.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test2_formatSpain = test2?.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test2?.normalisedRepresentation == "0.000017", test2?.normalisedRepresentation ?? "-")
		XCTAssert(test2?.toNormalisedDecimal() == 0.000017, test2?.toNormalisedDecimal()?.description ?? "-")
		XCTAssert(test2?.rpcRepresentation == "17", test2?.rpcRepresentation ?? "-")
		XCTAssert(test2?.toRpcDecimal() == 17, test2?.toRpcDecimal()?.description ?? "-")
		XCTAssert(test2_formatUS == "0.000017", test2_formatUS ?? "-")
		XCTAssert(test2_formatSpain == "0,000017", test2_formatSpain ?? "-")
		
		
		let test3 = XTZAmount(fromRpcAmount: 29123456)
		let test3_formatUS = test3?.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test3_formatSpain = test3?.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test3?.normalisedRepresentation == "29.123456", test3?.normalisedRepresentation ?? "-")
		XCTAssert(test3?.toNormalisedDecimal() == 29.123456, test3?.toNormalisedDecimal()?.description ?? "-")
		XCTAssert(test3?.rpcRepresentation == "29123456", test3?.rpcRepresentation ?? "-")
		XCTAssert(test3?.toRpcDecimal() == 29123456, test3?.toRpcDecimal()?.description ?? "-")
		XCTAssert(test3_formatUS == "29.123456", test3_formatUS ?? "-")
		XCTAssert(test3_formatSpain == "29,123456", test3_formatSpain ?? "-")
		
		
		let test4 = XTZAmount(fromRpcAmount: "13761512345678901234")
		let test4_formatUS = test4?.formatNormalisedRepresentation(locale: Locale(identifier: "en_US"))
		let test4_formatSpain = test4?.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		XCTAssert(test4?.normalisedRepresentation == "13761512345678.901234", test4?.normalisedRepresentation ?? "-")
		XCTAssert(test4?.rpcRepresentation == "13761512345678901234", test4?.rpcRepresentation ?? "-")
		XCTAssert(test4?.toRpcDecimal() == Decimal(string: "13761512345678901234"), test4?.toRpcDecimal()?.description ?? "-")
		XCTAssert(test4_formatUS == "13,761,512,345,678.901234", test4_formatUS ?? "-")
		XCTAssert(test4_formatSpain == "13.761.512.345.678,901234", test4_formatSpain ?? "-")
		
		
		let test5 = XTZAmount(fromRpcAmount: 14.2)
		XCTAssert(test5 == nil)
		
		let test6 = XTZAmount(fromRpcAmount: "14.2")
		XCTAssert(test6 == nil)
	}
	
	func testArithmetic() {
		
		// Addition
		var first = XTZAmount(fromNormalisedAmount: 10)
		var second = XTZAmount(fromNormalisedAmount: 17)
		var result = first + second
		XCTAssert(result.description == "27", result.description)
		
		first = XTZAmount(fromNormalisedAmount: 10.14)
		second = XTZAmount(fromNormalisedAmount: 17.37)
		result = first + second
		XCTAssert(result.description == "27.51", result.description)
		
		
		// Subtraction
		first = XTZAmount(fromNormalisedAmount: 17)
		second = XTZAmount(fromNormalisedAmount: 10)
		result = first - second
		XCTAssert(result.description == "7", result.description)
		
		first = XTZAmount(fromNormalisedAmount: 17.37)
		second = XTZAmount(fromNormalisedAmount: 10.14)
		result = first - second
		XCTAssert(result.description == "7.23", result.description)
		
		first = XTZAmount(fromNormalisedAmount: 10.14)
		second = XTZAmount(fromNormalisedAmount: 17.37)
		result = first - second
		XCTAssert(result.description == "-7.23", result.description)
		
		
		// Multiplcation
		first = XTZAmount(fromNormalisedAmount: 17)
		result = first * 4
		XCTAssert(result.description == "68", result.description)
		
		first = XTZAmount(fromNormalisedAmount: 17.42)
		let decimalResult = first * 4.5
		XCTAssert(decimalResult.description == "78.39", decimalResult.description)
	}
	
	func testEquatable() {
		var first = XTZAmount(fromNormalisedAmount: 10)
		var second = XTZAmount(fromNormalisedAmount: 10)
		XCTAssert(first == second)
		
		first = XTZAmount(fromNormalisedAmount: 10)
		second = XTZAmount(fromNormalisedAmount: 17)
		XCTAssert(first != second)
	}
	
	func testDecoder() {
		let decoder = JSONDecoder()
		
		let json1 = "{\"balance\": \"123456\", \"decimalPlaces\": 3}"
		let amount1 = try? decoder.decode(XTZAmount.self, from: json1.data(using: .utf8) ?? Data())
		XCTAssert(amount1?.description == "0.123456", amount1?.description ?? "-")
		
		let json2 = "{\"balance\": \"123456\"}"
		let amount2 = try? decoder.decode(XTZAmount.self, from: json2.data(using: .utf8) ?? Data())
		XCTAssert(amount2?.description == "0.123456", amount2?.description ?? "-")
		
		let json3 = "\"123456\""
		let amount3 = try? decoder.decode(XTZAmount.self, from: json3.data(using: .utf8) ?? Data())
		XCTAssert(amount3?.description == "0.123456", amount3?.description ?? "-")
		
		let json4 = "123456"
		let amount4 = try? decoder.decode(XTZAmount.self, from: json4.data(using: .utf8) ?? Data())
		XCTAssert(amount4?.description == "0.123456", amount4?.description ?? "-")
	}
}
