//
//  MichelsonFactoryTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class MichelsonFactoryTests: XCTestCase {
	
	var michelsonString: [String: Any] = [:]
	var michelsonInt: [String: Any] = [:]
	var michelsonPair: [String: Any] = [:]
	
    override func setUpWithError() throws {
		michelsonString = ["string": "mString"]
		michelsonInt = ["int": "14"]
		michelsonPair = ["prim": "Pair", "args": [ michelsonString, michelsonInt ]]
    }

    override func tearDownWithError() throws {
		
    }
	
	func testTypeCheckers() {
		let michelsonString = ["string": "mString"]
		let michelsonInt = ["int": "14"]
		let michelsonPair: [String: Any] = ["prim": "Pair", "args": [ michelsonString, michelsonInt ]]
		
		XCTAssert(MichelsonFactory.isString(michelsonString))
		XCTAssertFalse(MichelsonFactory.isString(michelsonInt))
		XCTAssertFalse(MichelsonFactory.isString(michelsonPair))
		
		XCTAssert(MichelsonFactory.isInt(michelsonInt))
		XCTAssertFalse(MichelsonFactory.isInt(michelsonString))
		XCTAssertFalse(MichelsonFactory.isInt(michelsonPair))
		
		XCTAssert(MichelsonFactory.isPair(michelsonPair))
		XCTAssertFalse(MichelsonFactory.isPair(michelsonString))
		XCTAssertFalse(MichelsonFactory.isPair(michelsonInt))
	}
	
	func testExtractors() {
		let extractedInt = MichelsonFactory.int(michelsonInt)
		let extractedString = MichelsonFactory.string(michelsonString)
		let extractedLeft = MichelsonFactory.left(michelsonPair)
		let extractedRight = MichelsonFactory.right(michelsonPair)
		
		XCTAssert(extractedInt == 14)
		XCTAssert(extractedString == "mString")
		XCTAssert(extractedLeft?.keys == michelsonString.keys)
		XCTAssert(extractedRight?.keys == michelsonInt.keys)
	}
	
	func testBuilders() {
		let mInt = MichelsonFactory.createInt(TokenAmount(fromNormalisedAmount: 14, decimalPlaces: 0))
		let mString = MichelsonFactory.createString("mString")
		
		XCTAssert(mInt.key == .int)
		XCTAssert(mInt.value == "14")
		
		XCTAssert(mString.key == .string)
		XCTAssert(mString.value == "mString")
	}
}
