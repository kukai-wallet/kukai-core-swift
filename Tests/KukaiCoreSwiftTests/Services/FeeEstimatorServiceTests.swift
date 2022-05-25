//
//  FeeEstimatorServiceTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class FeeEstimatorServiceTests: XCTestCase {
	
	let estimationService = FeeEstimatorService(config: MockConstants.shared.config, operationService: OperationService(config: MockConstants.shared.config, networkService: MockConstants.shared.networkService), networkService: MockConstants.shared.networkService)
	
    override func setUpWithError() throws {
		
    }

    override func tearDownWithError() throws {
		
    }
	
	func testEstimation1() {
		MockConstants.resetOperations()
		
		let expectation = XCTestExpectation(description: "Estimation service")
		estimationService.estimate(operations: MockConstants.sendOperationWithReveal, operationMetadata: MockConstants.operationMetadata, constants: MockConstants.networkConstants, withWallet: MockConstants.defaultHdWallet, receivedSuggestedGas: false) { result in
			switch result {
				case .success(let operations):
					XCTAssert(operations.count == 2)
					XCTAssert(operations[0].operationFees?.allFees() == XTZAmount(fromNormalisedAmount:  0), operations[0].operationFees?.allFees().description ?? "")
					XCTAssert(operations[1].operationFees?.allFees() == XTZAmount(fromNormalisedAmount: 0.000674), operations[1].operationFees?.allFees().description ?? "")
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
	
	func testEstimation2() {
		MockConstants.resetOperations()
		
		let expectation = XCTestExpectation(description: "Estimation service")
		estimationService.estimate(operations: MockConstants.sendOperationWithReveal, operationMetadata: MockConstants.operationMetadata, constants: MockConstants.networkConstants, withWallet: MockConstants.defaultHdWallet, receivedSuggestedGas: true) { result in
			switch result {
				case .success(let operations):
					XCTAssert(operations.count == 2)
					XCTAssert(operations[0].operationFees?.allFees() == XTZAmount(fromNormalisedAmount:  0), operations[0].operationFees?.allFees().description ?? "")
					XCTAssert(operations[1].operationFees?.allFees() == XTZAmount(fromNormalisedAmount: 0.130927), operations[1].operationFees?.allFees().description ?? "")
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
}
