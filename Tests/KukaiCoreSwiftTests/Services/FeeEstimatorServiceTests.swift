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
		estimationService.estimate(operations: MockConstants.sendOperationWithReveal, operationMetadata: MockConstants.operationMetadata, constants: MockConstants.networkConstants, withWallet: MockConstants.defaultHdWallet, suggestedOpsAndFees: nil) { result in
			switch result {
				case .success(let operations):
					XCTAssert(operations.count == 2)
					XCTAssert(operations[0].operationFees.allFees() == XTZAmount(fromNormalisedAmount:  0), operations[0].operationFees.allFees().description)
					XCTAssert(operations[1].operationFees.allFees() == XTZAmount(fromNormalisedAmount: 0.000674), operations[1].operationFees.allFees().description)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
	
	func testEstimation2() {
		MockConstants.resetOperations()
		
		// Sample suggested operations = fees coming back from a dApp
		let op1 = OperationReveal(wallet: MockConstants.defaultHdWallet)
		let op2 = OperationTransaction(amount: MockConstants.xtz_1, source: MockConstants.defaultHdWallet.address, destination: MockConstants.defaultLinearWallet.address)
		op2.operationFees.gasLimit = 140000
		
		let suggestOperationsWithFees = [op1, op2]
		
		let expectation = XCTestExpectation(description: "Estimation service")
		estimationService.estimate(operations: MockConstants.sendOperationWithReveal, operationMetadata: MockConstants.operationMetadata, constants: MockConstants.networkConstants, withWallet: MockConstants.defaultHdWallet, suggestedOpsAndFees: suggestOperationsWithFees) { result in
			switch result {
				case .success(let operations):
					XCTAssert(operations.count == 2)
					XCTAssert(operations[0].operationFees.allFees() == XTZAmount(fromNormalisedAmount:  0), operations[0].operationFees.allFees().description)
					XCTAssert(operations[1].operationFees.allFees() == XTZAmount(fromNormalisedAmount: 0.014331), operations[1].operationFees.allFees().description)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
}
