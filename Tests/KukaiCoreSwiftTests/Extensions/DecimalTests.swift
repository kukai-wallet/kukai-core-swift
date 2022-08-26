//
//  DecimalTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class DecimalTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }
	
	func testDecimalRounding() {
		let test1: Decimal = 1.4176932
		XCTAssert(test1.rounded(scale: 3, roundingMode: .down) == 1.417, test1.rounded(scale: 3, roundingMode: .down).description)
		XCTAssert(test1.rounded(scale: 3, roundingMode: .up) == 1.418, test1.rounded(scale: 3, roundingMode: .up).description)
		XCTAssert(test1.rounded(scale: 3, roundingMode: .bankers) == 1.418, test1.rounded(scale: 3, roundingMode: .bankers).description)
		
		let test2: Decimal = 11936782.417693223423
		XCTAssert(test2.rounded(scale: 5, roundingMode: .down).description == "11936782.41769", test2.rounded(scale: 5, roundingMode: .down).description)
		XCTAssert(test2.rounded(scale: 5, roundingMode: .up).description == "11936782.4177", test2.rounded(scale: 5, roundingMode: .up).description)
		XCTAssert(test2.rounded(scale: 5, roundingMode: .bankers).description == "11936782.41769", test2.rounded(scale: 5, roundingMode: .bankers).description)
		
		let test3: Decimal = 1.41769323453453
		XCTAssert(test3.rounded(scale: 7, roundingMode: .down).description == "1.4176932", test3.rounded(scale: 7, roundingMode: .down).description)
		XCTAssert(test3.rounded(scale: 7, roundingMode: .up).description == "1.4176933", test3.rounded(scale: 7, roundingMode: .up).description)
		XCTAssert(test3.rounded(scale: 7, roundingMode: .bankers).description == "1.4176932", test3.rounded(scale: 7, roundingMode: .bankers).description)
	}
	
	func testIntValue() {
		let test1: Decimal = 1.4176932
		XCTAssert(test1.intValue() == 1, test1.intValue().description)
		
		let test2: Decimal = 11936782.417693223423
		XCTAssert(test2.intValue() == 11936782, test2.intValue().description)
		
		let test3: Decimal = 3.41769323453453
		XCTAssert(test3.intValue() == 3, test3.intValue().description)
	}
}
