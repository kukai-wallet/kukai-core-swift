//
//  BetterCallDevClientTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 17/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class BetterCallDevClientTests: XCTestCase {
	
	func testMoreDetailedError() {
		let expectation = XCTestExpectation(description: "bcd-testMoreDetailedError")
		MockConstants.shared.betterCallDevClient.getMoreDetailedError(byHash: MockConstants.operationHashToSearch) { bcdError, kukaiError in
			
			XCTAssert(bcdError?.kind == "temporary", bcdError?.kind ?? "-")
			XCTAssert(bcdError?.title == "Script failed", bcdError?.title ?? "-")
			XCTAssert(bcdError?.descr == "A FAILWITH instruction was reached", bcdError?.descr ?? "-")
			XCTAssert(bcdError?.with == "xtzBought is less than minXtzBought.", bcdError?.with ?? "-")
			
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 3)
	}
}
