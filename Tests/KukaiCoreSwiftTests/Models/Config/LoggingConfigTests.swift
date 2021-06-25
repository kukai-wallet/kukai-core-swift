//
//  LoggingConfigTests.swift
//  
//
//  Created by Simon Mcloughlin on 25/06/2021.
//

import XCTest
@testable import KukaiCoreSwift

class LoggingConfigTests: XCTestCase {

	override func setUpWithError() throws {
		
	}

	override func tearDownWithError() throws {
		
	}
	
	func testLoggingConfig() {
		var loggingConfig = LoggingConfig(logNetworkFailures: true, logNetworkSuccesses: true)
		XCTAssert(loggingConfig.logNetworkFailures == true)
		XCTAssert(loggingConfig.logNetworkSuccesses == true)
		
		loggingConfig.allOff()
		XCTAssert(loggingConfig.logNetworkFailures == false)
		XCTAssert(loggingConfig.logNetworkSuccesses == false)
		
		loggingConfig.allOn()
		XCTAssert(loggingConfig.logNetworkFailures == true)
		XCTAssert(loggingConfig.logNetworkSuccesses == true)
	}
}

