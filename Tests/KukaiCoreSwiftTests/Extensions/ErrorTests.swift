//
//  ErrorTetss.swift
//  
//
//  Created by Simon Mcloughlin on 25/06/2021.
//

import XCTest
@testable import KukaiCoreSwift

class ErrorTests: XCTestCase {
	
	public enum TestError: Error {
		case testCase
	}
	
	override func setUpWithError() throws {
	}

	override func tearDownWithError() throws {
	}
	
	func testErrorExtensions() {
		let innerError = NSError(domain: "com.test.domain.inner", code: 123, userInfo: nil)
		let swiftError: Error = NSError(domain: "com.test.domain", code: 417, userInfo: [NSUnderlyingErrorKey: innerError, "test": "test-value"])
		
		XCTAssert(swiftError.code == 417)
		XCTAssert(swiftError.domain == "com.test.domain")
		XCTAssert(swiftError.underlyingError?.code == 123)
		XCTAssert(swiftError.userInfo["test"] as? String == "test-value")
	}
}
