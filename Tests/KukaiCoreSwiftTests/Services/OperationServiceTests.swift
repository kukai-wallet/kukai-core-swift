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
		
		wait(for: [expectation], timeout: 10)
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
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testLedgerWithoutReveal() {
		let stringToSign = operationService.ledgerStringToSign(
			forgedHash: "43f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6c00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d00ffde080000c0843d00005134b25890279835eb946e6369a3d719bc0d617700",
			operationPayload: MockConstants.sendOperationPayload
		)
		
		// Should be an operation starting with "03"
		XCTAssert(stringToSign == "0343f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6c00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d00ffde080000c0843d00005134b25890279835eb946e6369a3d719bc0d617700", stringToSign)
	}
	
	func testLedgerWithReveal() {
		let stringToSign = operationService.ledgerStringToSign(
			forgedHash: "43f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6c00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d00ffde080000c0843d00005134b25890279835eb946e6369a3d719bc0d617700",
			operationPayload: MockConstants.sendOperationWithRevealPayload
		)
		
		// Should be a 32 character long blake2b hash
		XCTAssert(stringToSign == "a49d693a7bf5c22564bbb9368c94362ea64f07e5c5d1c443b63190ae5c85adf2", stringToSign)
	}
}
