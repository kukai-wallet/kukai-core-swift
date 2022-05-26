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
		
		wait(for: [expectation], timeout: 3)
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
		
		wait(for: [expectation], timeout: 3)
	}
	
	func testLedgerPrepWithoutReveal() {
		let expectation = XCTestExpectation(description: "operation service ledger no reveal")
		operationService.ledgerOperationPrepWithLocalForge(metadata: MockConstants.operationMetadata, operations: MockConstants.sendOperations, wallet: MockConstants.defaultHdWallet) { ledgerResult in
			switch ledgerResult {
				case .success(let object):
					
					XCTAssert(object.payload.contents.count == 1, "\(object.payload.contents.count)")
					XCTAssert(object.payload.contents.first is OperationTransaction, "\(String(describing: object.payload.contents.first))")
					
					XCTAssert(object.forgedOp == "43f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6c00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d00ffde080000c0843d00005134b25890279835eb946e6369a3d719bc0d617700", object.forgedOp)
					XCTAssert(object.watermarkedOp == "0343f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6c00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d00ffde080000c0843d00005134b25890279835eb946e6369a3d719bc0d617700", object.watermarkedOp)
					XCTAssert(object.blake2bHash == "a49d693a7bf5c22564bbb9368c94362ea64f07e5c5d1c443b63190ae5c85adf2", object.blake2bHash)
					XCTAssert(object.canLedgerParse == true)
				
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
	
	func testLedgerPrepWithReveal() {
		let expectation = XCTestExpectation(description: "operation service ledger reveal")
		operationService.ledgerOperationPrepWithLocalForge(metadata: MockConstants.operationMetadataNoManager, operations: MockConstants.sendOperations, wallet: MockConstants.defaultHdWallet) { ledgerResult in
			switch ledgerResult {
				case .success(let object):
					
					XCTAssert(object.payload.contents.count == 2, "\(object.payload.contents.count)")
					XCTAssert(String(object.forgedOp.prefix(50)) == "43f597d84037e88354ed041cc6356f737cc6638691979bb644", String(object.forgedOp.prefix(50)))
					XCTAssert(String(object.watermarkedOp.prefix(50)) == "0343f597d84037e88354ed041cc6356f737cc6638691979bb6", String(object.watermarkedOp.prefix(50)))
					XCTAssert(object.blake2bHash == "0d2efb76df791a2e29fd7e47b09ba76e842a230c47393b7ba172b95313520970", object.blake2bHash)
					XCTAssert(object.canLedgerParse == false)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
}
