//
//  CurrentDeviceTests.swift
//  
//
//  Created by Simon Mcloughlin on 25/06/2021.
//

import XCTest
@testable import KukaiCoreSwift

class CurrentDeviceTests: XCTestCase {

	override func setUpWithError() throws {
		
	}

	override func tearDownWithError() throws {
		
	}
	
	func testCurrentDevice() {
		XCTAssert(CurrentDevice.isSimulator == true)
	}
	
	func testBiometrics() {
		XCTAssert(CurrentDevice.biometricTypeSupported() == .none)
	}
}
