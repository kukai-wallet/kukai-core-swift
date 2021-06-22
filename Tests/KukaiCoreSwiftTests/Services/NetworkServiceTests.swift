//
//  NetworkServiceTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class NetworkServiceTests: XCTestCase {

    override func setUpWithError() throws {
		
    }

    override func tearDownWithError() throws {
		
    }
	
	func testGet() {
		let expectation = XCTestExpectation(description: "network service GET")
		MockConstants.shared.networkService.send(rpc: RPC.xtzBalance(forAddress: MockConstants.defaultHdWallet.address), withBaseURL: MockConstants.shared.config.primaryNodeURL) { result in
			
			switch result {
				case .success(let string):
					XCTAssert(string == "97575")
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
	
	func testPost() {
		let expectation = XCTestExpectation(description: "network service POST")
		
		if let rpc = RPC.forge(operationPayload: MockConstants.sendOperationPayload, withMetadata: MockConstants.operationMetadata) {
			MockConstants.shared.networkService.send(rpc: rpc, withBaseURL: MockConstants.shared.config.primaryNodeURL) { result in
				
				switch result {
					case .success(let string):
						XCTAssert(string == MockConstants.sendOperationForged, string)
						
					case .failure(let error):
						XCTFail(error.description)
				}
				
				expectation.fulfill()
			}
			
			wait(for: [expectation], timeout: 3)
			
		} else {
			XCTFail("Couldn't parse RPC")
		}
	}
	
	func testErrorGas() {
		MockURLProtocol.triggerGasExhaustedErrorOnRunOperation()
		
		let expectation = XCTestExpectation(description: "network service error gas")
		
		if let rpc = RPC.runOperation(runOperationPayload: RunOperationPayload(chainID: MockConstants.blockchainHead.chainID, operation: MockConstants.sendOperationPayload)) {
			MockConstants.shared.networkService.send(rpc: rpc, withBaseURL: MockConstants.shared.config.primaryNodeURL) { result in
				
				switch result {
					case .success(_):
						XCTFail("Should have failed")
						
					case .failure(let error):
						XCTAssert(error.errorType == .unknownError)
						XCTAssert(error.requestURL?.absoluteString == MockConstants.shared.config.primaryNodeURL.appendingPathComponent("chains/main/blocks/head/helpers/scripts/run_operation").absoluteString)
						XCTAssert(error.requestJSON != nil)
						XCTAssert(error.responseJSON != nil)
				}
				
				expectation.fulfill()
			}
			
			wait(for: [expectation], timeout: 3)
			
		} else {
			XCTFail("Couldn't parse RPC")
		}
	}
	
	func testErrorAssert() {
		MockURLProtocol.triggerAssertErrorOnRunOperation()
		
		let expectation = XCTestExpectation(description: "network service error gas")
		
		if let rpc = RPC.runOperation(runOperationPayload: RunOperationPayload(chainID: MockConstants.blockchainHead.chainID, operation: MockConstants.sendOperationPayload)) {
			MockConstants.shared.networkService.send(rpc: rpc, withBaseURL: MockConstants.shared.config.primaryNodeURL) { result in
				
				switch result {
					case .success(_):
						XCTFail("Should have failed")
						
					case .failure(let error):
						XCTAssert(error.errorType == .unknownError)
						XCTAssert(error.requestURL?.absoluteString == MockConstants.shared.config.primaryNodeURL.appendingPathComponent("chains/main/blocks/head/helpers/scripts/run_operation").absoluteString)
						XCTAssert(error.requestJSON != nil)
						XCTAssert(error.responseJSON != nil)
				}
				
				expectation.fulfill()
			}
			
			wait(for: [expectation], timeout: 3)
			
		} else {
			XCTFail("Couldn't parse RPC")
		}
	}
}
