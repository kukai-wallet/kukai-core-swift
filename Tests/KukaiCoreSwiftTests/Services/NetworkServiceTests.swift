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
		MockConstants.shared.networkService.send(rpc: RPC.xtzBalance(forAddress: MockConstants.defaultHdWallet.address), withNodeURLs: MockConstants.shared.config.nodeURLs) { result in
			
			switch result {
				case .success(let string):
					XCTAssert(string == "97575")
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testPost() {
		let expectation = XCTestExpectation(description: "network service POST")
		
		if let rpc = RPC.forge(operationPayload: MockConstants.sendOperationPayload) {
			MockConstants.shared.networkService.send(rpc: rpc, withNodeURLs: MockConstants.shared.config.nodeURLs) { result in
				
				switch result {
					case .success(let string):
						XCTAssert(string == MockConstants.sendOperationForged, string)
						
					case .failure(let error):
						XCTFail(error.description)
				}
				
				expectation.fulfill()
			}
			
			wait(for: [expectation], timeout: 120)
			
		} else {
			XCTFail("Couldn't parse RPC")
		}
	}
	
	func testErrorGas() {
		MockURLProtocol.triggerGasExhaustedErrorOnRunOperation(nodeUrl: 0)
		MockURLProtocol.triggerGasExhaustedErrorOnRunOperation(nodeUrl: 1)
		
		let expectation = XCTestExpectation(description: "network service error gas")
		
		if let rpc = RPC.runOperation(runOperationPayload: RunOperationPayload(chainID: MockConstants.blockchainHead.chainID, operation: MockConstants.sendOperationPayload)) {
			MockConstants.shared.networkService.send(rpc: rpc, withNodeURLs: MockConstants.shared.config.nodeURLs) { result in
				
				switch result {
					case .success(_):
						XCTFail("Should have failed")
						
					case .failure(let error):
						XCTAssert(error.errorType == .rpc, error.description)
						XCTAssert(error.requestURL?.absoluteString == MockConstants.shared.config.nodeURLs[1].appendingPathComponent("chains/main/blocks/head/helpers/scripts/run_operation").absoluteString, error.requestURL?.absoluteString ?? "-")
						XCTAssert(error.requestJSON != nil)
						XCTAssert(error.responseJSON != nil)
				}
				
				expectation.fulfill()
			}
			
			wait(for: [expectation], timeout: 120)
			
		} else {
			XCTFail("Couldn't parse RPC")
		}
	}
	
	func testErrorAssert() {
		MockURLProtocol.triggerAssertErrorOnRunOperation()
		
		let expectation = XCTestExpectation(description: "network service error gas")
		
		if let rpc = RPC.runOperation(runOperationPayload: RunOperationPayload(chainID: MockConstants.blockchainHead.chainID, operation: MockConstants.sendOperationPayload)) {
			MockConstants.shared.networkService.send(rpc: rpc, withNodeURLs: MockConstants.shared.config.nodeURLs) { result in
				
				switch result {
					case .success(_):
						XCTFail("Should have failed")
						
					case .failure(let error):
						XCTAssert(error.errorType == .unknown)
						XCTAssert(error.description == "Unknown: Assert_failure src/proto_009_PsFLoren/lib_protocol/operation_repr.ml:203:6", error.description)
						XCTAssert(error.requestURL?.absoluteString == MockConstants.shared.config.nodeURLs[0].appendingPathComponent("chains/main/blocks/head/helpers/scripts/run_operation").absoluteString)
						XCTAssert(error.requestJSON != nil)
						XCTAssert(error.responseJSON != nil)
				}
				
				expectation.fulfill()
			}
			
			wait(for: [expectation], timeout: 120)
			
		} else {
			XCTFail("Couldn't parse RPC")
		}
	}
	
	func testCounterInFutureErrorSingleError() {
		MockURLProtocol.triggerCounterInFutureError(nodeUrl: 0)
		
		let expectation = XCTestExpectation(description: "checking retry logic with counter in future")
		var operationPayload = OperationPayload(branch: MockConstants.blockchainHead.hash, contents: MockConstants.sendOperations)
		operationPayload.addProtcol(fromMetadata: MockConstants.operationMetadata)
		operationPayload.addSignature([], signingCurve: MockConstants.defaultHdWallet.privateKeyCurve())
		
		if let rpc = RPC.preapply(operationPayload: operationPayload) {
			MockConstants.shared.networkService.send(rpc: rpc, withNodeURLs: MockConstants.shared.config.nodeURLs) { result in
				
				switch result {
					case .success(let opResponse):
						XCTAssert(opResponse.count == 1, opResponse.count.description)
						
					case .failure(_):
						XCTFail("Should have passed on second attempt")
				}
				
				expectation.fulfill()
			}
			
			wait(for: [expectation], timeout: 120)
			
		} else {
			XCTFail("Couldn't parse RPC")
		}
	}
	
	func testCounterInFutureErrorDoubleError() {
		MockURLProtocol.triggerCounterInFutureError(nodeUrl: 0)
		MockURLProtocol.triggerCounterInFutureError(nodeUrl: 1)
		
		let expectation = XCTestExpectation(description: "checking retry logic with counter in future")
		var operationPayload = OperationPayload(branch: MockConstants.blockchainHead.hash, contents: MockConstants.sendOperations)
		operationPayload.addProtcol(fromMetadata: MockConstants.operationMetadata)
		operationPayload.addSignature([], signingCurve: MockConstants.defaultHdWallet.privateKeyCurve())
		
		if let rpc = RPC.preapply(operationPayload: operationPayload) {
			MockConstants.shared.networkService.send(rpc: rpc, withNodeURLs: MockConstants.shared.config.nodeURLs) { result in
				
				switch result {
					case .success(_):
						XCTFail("Should have failed")
						
					case .failure(let error):
						XCTAssert(error.errorType == .rpc)
						XCTAssert(error.description == "RPC: contract.counter_in_the_future", error.description)
						XCTAssert(error.requestURL?.absoluteString == MockConstants.shared.config.nodeURLs[1].appendingPathComponent("chains/main/blocks/head/helpers/preapply/operations").absoluteString, error.requestURL?.absoluteString ?? "-")
				}
				
				expectation.fulfill()
			}
			
			wait(for: [expectation], timeout: 120)
			
		} else {
			XCTFail("Couldn't parse RPC")
		}
	}
	
	func testRpcRetryLogic() {
		MockURLProtocol.triggerHttp500ErrorOnRunOperation()
		
		let expectation = XCTestExpectation(description: "network service retry logic")
		
		if let rpc = RPC.runOperation(runOperationPayload: RunOperationPayload(chainID: MockConstants.blockchainHead.chainID, operation: MockConstants.sendOperationPayload)) {
			MockConstants.shared.networkService.send(rpc: rpc, withNodeURLs: MockConstants.shared.config.nodeURLs) { result in
				
				switch result {
					case .success(let opResponse):
						XCTAssert(opResponse.contents.count == 2, opResponse.contents.count.description)
						
					case .failure(_):
						XCTFail("Should have passed on second attempt")
				}
				
				expectation.fulfill()
			}
			
			wait(for: [expectation], timeout: 120)
			
		} else {
			XCTFail("Couldn't parse RPC")
		}
	}
}
