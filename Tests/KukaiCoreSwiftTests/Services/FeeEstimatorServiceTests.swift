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
	
	func testEstimationTransaction() {
		MockConstants.resetOperations()
		
		let expectation = XCTestExpectation(description: "Estimation service")
		let address = MockConstants.defaultHdWallet.address
		let key = MockConstants.defaultHdWallet.publicKeyBase58encoded()
		estimationService.estimate(operations: MockConstants.sendOperationWithReveal, operationMetadata: MockConstants.operationMetadata, constants: MockConstants.networkConstants, walletAddress: address, base58EncodedPublicKey: key) { result in
			switch result {
				case .success(let result):
					XCTAssert(result.operations.count == 2)
					XCTAssert(result.operations[0].operationFees.allFees() == XTZAmount(fromNormalisedAmount:  0), result.operations[0].operationFees.allFees().description)
					XCTAssert(result.operations[1].operationFees.allFees() == XTZAmount(fromNormalisedAmount: 0.000598), result.operations[1].operationFees.allFees().description)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testEstimationWithSuggestedGas() {
		MockConstants.resetOperations()
		
		// Sample suggested operations = fees coming back from a dApp
		let op1 = OperationReveal(wallet: MockConstants.defaultHdWallet)
		let op2 = OperationTransaction(amount: MockConstants.xtz_1, source: MockConstants.defaultHdWallet.address, destination: MockConstants.defaultLinearWallet.address)
		op2.operationFees.gasLimit = 140000
		
		let suggestOperationsWithFees = [op1, op2]
		
		let expectation = XCTestExpectation(description: "Estimation service")
		let address = MockConstants.defaultHdWallet.address
		let key = MockConstants.defaultHdWallet.publicKeyBase58encoded()
		estimationService.estimate(operations: suggestOperationsWithFees, operationMetadata: MockConstants.operationMetadata, constants: MockConstants.networkConstants, walletAddress: address, base58EncodedPublicKey: key) { result in
			switch result {
				case .success(let result):
					XCTAssert(result.operations.count == 2)
					XCTAssert(result.operations[0].operationFees.allFees() == XTZAmount(fromNormalisedAmount:  0), result.operations[0].operationFees.allFees().description)
					XCTAssert(result.operations[1].operationFees.allFees() == XTZAmount(fromNormalisedAmount: 0.014339), result.operations[1].operationFees.allFees().description)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 10)
	}
}
