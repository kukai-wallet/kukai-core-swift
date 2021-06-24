//
//  MichelsonTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class MichelsonTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
	
	func testMichelson() {
		let rawPair = "{\"prim\":\"Pair\",\"args\":[{\"string\":\"tz1X2yA7evDKputSBthrwuGpxpAYHkDUkVCN\"},{\"prim\":\"Pair\",\"args\":[{\"string\":\"tz1RKLWbGm7T4mnxDZHWazkbnvaryKsxxZTF\"},{\"int\":\"10\"}]}]}"
		guard let dict = try? JSONSerialization.jsonObject(with: rawPair.data(using: .utf8) ?? Data(), options: .allowFragments) as? [String: Any] else {
			XCTFail("Failed to parse JSON string")
			return
		}
		
		let pair = MichelsonPair.create(fromDictionary: dict)
		XCTAssert(pair?.argIndexAsValue(0)?.value == "tz1X2yA7evDKputSBthrwuGpxpAYHkDUkVCN", pair?.argIndexAsValue(0)?.value ?? "-")
		
		let innerPair = pair?.argIndexAsPair(1)
		XCTAssert(innerPair?.argIndexAsValue(0)?.value == "tz1RKLWbGm7T4mnxDZHWazkbnvaryKsxxZTF", innerPair?.argIndexAsValue(0)?.value ?? "-")
		XCTAssert(innerPair?.argIndexAsValue(1)?.value == "10", innerPair?.argIndexAsValue(1)?.value ?? "-")
	}
}
