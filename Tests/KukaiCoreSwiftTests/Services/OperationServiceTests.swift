//
//  OperationServiceTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class OperationServiceTests: XCTestCase {
	
	let operationService = OperationService(config: MockConstants.shared.config, networkService: MockConstants.shared.networkService)
	
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }
	
	
	func testRemoteForgeParseSignPreapplyInject() {
		let expectation = XCTestExpectation(description: "operation service remote")
		operationService.remoteForgeParseSignPreapplyInject(operationMetadata: MockConstants.operationMetadata, operationPayload: MockConstants.sendOperationPayload, wallet: MockConstants.defaultHdWallet) { result in
			switch result {
				case .success(let opHash):
					XCTAssert(opHash == "ooYfbDtBXixvdq1Tjwz6XQWPUwsyio458TXMxtxzomgzJ4z32dB", opHash)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testLocalForgeSignPreapplyInject() {
		let expectation = XCTestExpectation(description: "operation service local")
		operationService.localForgeSignPreapplyInject(operationMetadata: MockConstants.operationMetadata, operationPayload: MockConstants.sendOperationPayload, wallet: MockConstants.defaultHdWallet) { result in
			switch result {
				case .success(let opHash):
					XCTAssert(opHash == "ooYfbDtBXixvdq1Tjwz6XQWPUwsyio458TXMxtxzomgzJ4z32dB", opHash)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
}
