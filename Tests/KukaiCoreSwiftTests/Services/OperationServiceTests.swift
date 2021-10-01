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
				case .success(let objects):
					XCTAssert(objects.payload.count == 1, "\(objects.payload.count)")
					XCTAssert(objects.forgedOp.count == 1, "\(objects.forgedOp.count)")
					XCTAssert(objects.watermarkedOp.count == 1, "\(objects.watermarkedOp.count)")
					
					XCTAssert(objects.forgedOp.first == "43f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6c00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d820bffde0884528102c0843d00005134b25890279835eb946e6369a3d719bc0d617700", objects.forgedOp.first ?? "")
					XCTAssert(objects.watermarkedOp.first == "0343f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6c00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d820bffde0884528102c0843d00005134b25890279835eb946e6369a3d719bc0d617700", objects.watermarkedOp.first ?? "")
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
	
	func testLedgerPrepWithReveal() {
		let expectation = XCTestExpectation(description: "operation service ledger no reveal")
		operationService.ledgerOperationPrepWithLocalForge(metadata: MockConstants.operationMetadataNoManager, operations: MockConstants.sendOperations, wallet: MockConstants.defaultHdWallet) { ledgerResult in
			switch ledgerResult {
				case .success(let objects):
					XCTAssert(objects.payload.count == 2, "\(objects.payload.count)")
					XCTAssert(objects.forgedOp.count == 2, "\(objects.forgedOp.count)")
					XCTAssert(objects.watermarkedOp.count == 2, "\(objects.watermarkedOp.count)")
					
					XCTAssert(objects.forgedOp.first == "43f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6b00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d820bffde0884528102001e4291f2501ce283e55ce583d4388ec8d247dd6c72fff3ff2d48b2af84cc9a23", objects.forgedOp.first ?? "")
					XCTAssert(objects.forgedOp.last == "43f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6c00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d820b80df0884528102c0843d00005134b25890279835eb946e6369a3d719bc0d617700", objects.forgedOp.last ?? "")
					
					XCTAssert(objects.watermarkedOp.first == "0343f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6b00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d820bffde0884528102001e4291f2501ce283e55ce583d4388ec8d247dd6c72fff3ff2d48b2af84cc9a23", objects.watermarkedOp.first ?? "")
					XCTAssert(objects.watermarkedOp.last == "0343f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6c00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d820b80df0884528102c0843d00005134b25890279835eb946e6369a3d719bc0d617700", objects.watermarkedOp.last ?? "")
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
}
