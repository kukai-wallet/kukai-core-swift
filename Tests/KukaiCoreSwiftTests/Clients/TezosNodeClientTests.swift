//
//  TezosNodeClientTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class TezosNodeClientTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
		
    }
	
	func testBalance() {
		let expectation = XCTestExpectation(description: "tezos node client")
		MockConstants.shared.tezosNodeClient.getBalance(forAddress: MockConstants.defaultHdWallet.address) { result in
			switch result {
				case .success(let amount):
					XCTAssert(amount.normalisedRepresentation == "0.097575", amount.normalisedRepresentation)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
	
	func testDelegate() {
		let expectation = XCTestExpectation(description: "tezos node client")
		MockConstants.shared.tezosNodeClient.getDelegate(forAddress: MockConstants.defaultHdWallet.address) { result in
			switch result {
				case .success(let address):
					XCTAssert(address == "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF", address)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
	
	func testEstiamte() {
		let expectation = XCTestExpectation(description: "tezos node client")
		MockConstants.shared.tezosNodeClient.estimate(operations: MockConstants.sendOperationWithReveal, withWallet: MockConstants.defaultHdWallet) { result in
			switch result {
				case .success(let ops):
					XCTAssert(ops.count == 2)
					XCTAssert(ops[0].operationFees.allFees() == XTZAmount(fromNormalisedAmount: 0), ops[0].operationFees.allFees().description)
					XCTAssert(ops[1].operationFees.allFees() == XTZAmount(fromNormalisedAmount: "0.000682", decimalPlaces: 6), ops[1].operationFees.allFees().description)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 300)
	}
	
	func testSendOperations() {
		let expectation = XCTestExpectation(description: "tezos node client")
		MockConstants.shared.tezosNodeClient.send(operations: MockConstants.sendOperations, withWallet: MockConstants.defaultHdWallet) { result in
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
	
	func testSendPayload() {
		let expectation = XCTestExpectation(description: "tezos node client")
		MockConstants.shared.tezosNodeClient.send(operationPayload: MockConstants.sendOperationPayload, operationMetadata: MockConstants.operationMetadata, withWallet: MockConstants.defaultHdWallet) { result in
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
	
	func testGetMetadata() {
		let expectation = XCTestExpectation(description: "tezos node client")
		MockConstants.shared.tezosNodeClient.getOperationMetadata(forWallet: MockConstants.defaultHdWallet) { result in
			switch result {
				case .success(let metadata):
					XCTAssert(metadata.branch == "BMLWVn1nEWeEzf6pxn3VYx7YcQ3zPay7HQtQ3rBMxuc7bXCG8BB", metadata.branch)
					XCTAssert(metadata.chainID == "NetXxkAx4woPLyu", metadata.chainID)
					XCTAssert(metadata.protocol == "PsFLorenaUUuikDWvMDr6fGBRG8kt3e3D3fHoXK1j1BFRxeSH4i", metadata.protocol)
					XCTAssert(metadata.counter == 143230, "\(metadata.counter)")
					XCTAssert(metadata.managerKey == "edpkvCbYCa6d6g9hEcK6tvwgsY9jfB4HDzp3jZSBwfuWNSvxE5T5KR", metadata.managerKey ?? "")
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
	
	/*
	func testGetContractStorage() {
		let expectation = XCTestExpectation(description: "tezos node client")
		MockConstants.shared.tezosNodeClient.getContractStorage(contractAddress: MockConstants.token3Decimals.tokenContractAddress ?? "") { result in
			switch result {
				case .success(let michelson):
					XCTAssert(michelson.args.count == 4, "\(michelson.args.count)")
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
	*/
	
	func testGetNetworkInformation() {
		let expectation = XCTestExpectation(description: "tezos node client")
		MockConstants.shared.tezosNodeClient.getNetworkInformation(completion: { success, error in
			XCTAssert(success)
			XCTAssert(error == nil)
			XCTAssert(MockConstants.shared.tezosNodeClient.networkVersion?.isMainnet() == false)
			XCTAssert(MockConstants.shared.tezosNodeClient.networkVersion?.chainName() == "ithacanet", MockConstants.shared.tezosNodeClient.networkVersion?.chainName() ?? "-")
			
			expectation.fulfill()
		})
		
		wait(for: [expectation], timeout: 3)
	}
}
