//
//  ArrayTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class ArrayTests: XCTestCase {

    override func setUpWithError() throws {
		
    }

    override func tearDownWithError() throws {
		
    }
	
	func testArrayextensions() {
		let hexArray = Array<UInt8>(hex: "48656c6c6f2c20576f726c64")
		XCTAssert(hexArray == [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100], "\(hexArray)")
		
		let bytesArray: [UInt8] = [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100]
		XCTAssert(bytesArray.toHexString() == "48656c6c6f2c20576f726c64", bytesArray.toHexString())
	}
}
