//
//  DataTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest

class DataTests: XCTestCase {

    override func setUpWithError() throws {
		
    }

    override func tearDownWithError() throws {
		
    }
	
	func testData() {
		let data = "Hello, World".data(using: .utf8)
		
		XCTAssert(data?.bytes() == [72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100], "\(data?.bytes() ?? [0])")
		XCTAssert(data?.hexString == "48656c6c6f2c20576f726c64", data?.hexString ?? "-")
	}
}
