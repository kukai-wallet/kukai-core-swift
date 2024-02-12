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
					XCTAssert(result.operations[1].operationFees.allFees() == XTZAmount(fromNormalisedAmount: 0.000588), result.operations[1].operationFees.allFees().description)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
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
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testJSONPayload1() {
		let decoder = JSONDecoder()
		
		let jsonDataRequest1 = MockConstants.jsonStub(fromFilename: "simulate_operation-crunchy-stake-operations")
		let jsonRequestOps1 = (try? decoder.decode([OperationTransaction].self, from: jsonDataRequest1)) ?? []
		XCTAssert(jsonRequestOps1.count != 0)
		
		let expectation1 = XCTestExpectation(description: "Estimation service")
		let address = MockConstants.defaultHdWallet.address
		let key = MockConstants.defaultHdWallet.publicKeyBase58encoded()
		estimationService.estimate(operations: jsonRequestOps1, operationMetadata: MockConstants.operationMetadata, constants: MockConstants.networkConstants, walletAddress: address, base58EncodedPublicKey: key) { result in
			switch result {
				case .success(let result):
					XCTAssert(result.operations.count == 3)
					XCTAssert(result.operations[0].operationFees.gasLimit == 770, result.operations[0].operationFees.gasLimit.description)
					XCTAssert(result.operations[0].operationFees.storageLimit == 0, result.operations[0].operationFees.storageLimit.description)
					XCTAssert(result.operations[0].operationFees.allFees().normalisedRepresentation == "0", result.operations[0].operationFees.allFees().normalisedRepresentation)
					XCTAssert(result.operations[1].operationFees.gasLimit == 6083, result.operations[1].operationFees.gasLimit.description)
					XCTAssert(result.operations[1].operationFees.storageLimit == 1313, result.operations[1].operationFees.storageLimit.description)
					XCTAssert(result.operations[1].operationFees.allFees().normalisedRepresentation == "0", result.operations[1].operationFees.allFees().normalisedRepresentation)
					XCTAssert(result.operations[2].operationFees.gasLimit == 659, result.operations[2].operationFees.gasLimit.description)
					XCTAssert(result.operations[2].operationFees.storageLimit == 0, result.operations[2].operationFees.storageLimit.description)
					XCTAssert(result.operations[2].operationFees.allFees().normalisedRepresentation == "0.329652", result.operations[2].operationFees.allFees().normalisedRepresentation)
					
					let totalGas = result.operations.map({ $0.operationFees.gasLimit }).reduce(0, +)
					XCTAssert(totalGas == 7512, totalGas.description)
					
					let totalStorage = result.operations.map({ $0.operationFees.storageLimit }).reduce(0, +)
					XCTAssert(totalStorage == 1313, totalStorage.description)
					
					let totalFee = result.operations.map({ $0.operationFees.allFees() }).reduce(XTZAmount.zero(), +)
					XCTAssert(totalFee.normalisedRepresentation == "0.329652", totalFee.normalisedRepresentation)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation1.fulfill()
		}
		
		wait(for: [expectation1], timeout: 120)
	}
	
	/*
	func testJSONPayload2() {
		let decoder = JSONDecoder()
		
		let jsonDataRequest1 = MockConstants.jsonStub(fromFilename: "simulate_operation-crunchy-swap-operations")
		let jsonRequestOps1 = (try? decoder.decode([OperationTransaction].self, from: jsonDataRequest1)) ?? []
		XCTAssert(jsonRequestOps1.count != 0)
		
		let expectation1 = XCTestExpectation(description: "Estimation service")
		let address = MockConstants.defaultHdWallet.address
		let key = MockConstants.defaultHdWallet.publicKeyBase58encoded()
		estimationService.estimate(operations: jsonRequestOps1, operationMetadata: MockConstants.operationMetadata, constants: MockConstants.networkConstants, walletAddress: address, base58EncodedPublicKey: key) { result in
			switch result {
				case .success(let result):
					XCTAssert(result.operations.count == 12, result.operations.count.description)
					XCTAssert(result.operations[0].operationFees.gasLimit == 770, result.operations[0].operationFees.gasLimit.description)
					XCTAssert(result.operations[0].operationFees.storageLimit == 0, result.operations[0].operationFees.storageLimit.description)
					XCTAssert(result.operations[0].operationFees.allFees().normalisedRepresentation == "0", result.operations[0].operationFees.allFees().normalisedRepresentation)
					XCTAssert(result.operations[1].operationFees.gasLimit == 6083, result.operations[1].operationFees.gasLimit.description)
					XCTAssert(result.operations[1].operationFees.storageLimit == 1313, result.operations[1].operationFees.storageLimit.description)
					XCTAssert(result.operations[1].operationFees.allFees().normalisedRepresentation == "0", result.operations[1].operationFees.allFees().normalisedRepresentation)
					XCTAssert(result.operations[2].operationFees.gasLimit == 659, result.operations[2].operationFees.gasLimit.description)
					XCTAssert(result.operations[2].operationFees.storageLimit == 0, result.operations[2].operationFees.storageLimit.description)
					XCTAssert(result.operations[2].operationFees.allFees().normalisedRepresentation == "0.329652", result.operations[2].operationFees.allFees().normalisedRepresentation)
					
					let totalGas = result.operations.map({ $0.operationFees.gasLimit }).reduce(0, +)
					XCTAssert(totalGas == 7512, totalGas.description)
					
					let totalStorage = result.operations.map({ $0.operationFees.storageLimit }).reduce(0, +)
					XCTAssert(totalStorage == 1313, totalStorage.description)
					
					let totalFee = result.operations.map({ $0.operationFees.allFees() }).reduce(XTZAmount.zero(), +)
					XCTAssert(totalFee.normalisedRepresentation == "0.329652", totalFee.normalisedRepresentation)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation1.fulfill()
		}
		
		wait(for: [expectation1], timeout: 120)
	}
	*/
}
