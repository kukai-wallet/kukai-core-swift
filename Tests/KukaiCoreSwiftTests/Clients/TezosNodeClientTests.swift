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
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testStakedBalanceNull() {
		let expectation = XCTestExpectation(description: "tezos node client")
		MockConstants.shared.tezosNodeClient.getStakedBalance(forAddress: MockConstants.defaultLinearWallet.address) { result in
			switch result {
				case .success(let amount):
					XCTAssert(amount.normalisedRepresentation == "0", amount.normalisedRepresentation)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testAllBalances() {
		let expectation = XCTestExpectation(description: "tezos node client")
		MockConstants.shared.tezosNodeClient.getAllBalances(forAddress: MockConstants.defaultHdWallet.address) { result in
			switch result {
				case .success(let tuple):
					XCTAssert(tuple.balance.normalisedRepresentation == "0.527575", tuple.balance.normalisedRepresentation)
					XCTAssert(tuple.staked.normalisedRepresentation == "0.43035", tuple.staked.normalisedRepresentation)
					XCTAssert(tuple.unstaked.normalisedRepresentation == "0.0015", tuple.unstaked.normalisedRepresentation)
					XCTAssert(tuple.finalisable.normalisedRepresentation == "0.00035", tuple.finalisable.normalisedRepresentation)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testDelegate() {
		let expectation = XCTestExpectation(description: "tezos node client")
		MockConstants.shared.tezosNodeClient.getDelegate(forAddress: MockConstants.defaultHdWallet.address) { result in
			switch result {
				case .success(let address):
					XCTAssert(address == "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss", address)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testEstiamte() {
		let expectation = XCTestExpectation(description: "tezos node client")
		let address = MockConstants.defaultHdWallet.address
		let key = MockConstants.defaultHdWallet.publicKeyBase58encoded()
		MockConstants.shared.tezosNodeClient.estimate(operations: MockConstants.sendOperationWithReveal, walletAddress: address, base58EncodedPublicKey: key) { result in
			switch result {
				case .success(let result):
					XCTAssert(result.operations.count == 2)
					XCTAssert(result.operations[0].operationFees.allFees() == XTZAmount(fromNormalisedAmount: 0), result.operations[0].operationFees.allFees().description)
					XCTAssert(result.operations[1].operationFees.allFees() == XTZAmount(fromNormalisedAmount: 0.000586), result.operations[1].operationFees.allFees().description)
					
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
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testSendOperationsError() {
		MockURLProtocol.triggerCounterInFutureError(nodeUrl: 0)
		MockURLProtocol.triggerCounterInFutureError(nodeUrl: 1)
		
		let expectation = XCTestExpectation(description: "tezos node client")
		MockConstants.shared.tezosNodeClient.send(operations: MockConstants.sendOperations, withWallet: MockConstants.defaultHdWallet) { result in
			switch result {
				case .success(_):
					XCTFail("Should have failed, got opHash instead")
					
				case .failure(let error):
					XCTAssert(error.description == "RPC error code: contract.counter_in_the_future", error.description)
			}
			
			expectation.fulfill()
			
		}
		
		wait(for: [expectation], timeout: 120)
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
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testGetMetadata() {
		let expectation = XCTestExpectation(description: "tezos node client")
		let address = MockConstants.defaultHdWallet.address
		MockConstants.shared.tezosNodeClient.getOperationMetadata(forWalletAddress: address) { result in
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
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testGetContractStorage() {
		let expectation = XCTestExpectation(description: "tezos node client")
		MockConstants.shared.tezosNodeClient.getContractStorage(contractAddress: MockConstants.token3Decimals.tokenContractAddress ?? "") { result in
			switch result {
				case .success(let json):
					XCTAssert(json.michelsonArgsArray()?.count == 4, "\(json.michelsonArgsArray()?.count ?? 0)")
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testGetNetworkInformation() {
		let expectation = XCTestExpectation(description: "tezos node client")
		MockConstants.shared.tezosNodeClient.getNetworkInformation(completion: { success, error in
			XCTAssert(success)
			XCTAssert(error == nil)
			XCTAssert(MockConstants.shared.tezosNodeClient.networkVersion?.isMainnet() == false)
			XCTAssert(MockConstants.shared.tezosNodeClient.networkVersion?.chainName() == "ithacanet", MockConstants.shared.tezosNodeClient.networkVersion?.chainName() ?? "-")
			
			expectation.fulfill()
		})
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testLiquidityBakingAddresses() {
		let expectation = XCTestExpectation(description: "tezos node client")
		MockConstants.shared.tezosNodeClient.getLiquidityBakingAddresses { result in
			switch result {
				case .success(let tuple):
					XCTAssert(tuple.cpmm == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tuple.cpmm)
					XCTAssert(tuple.tzbtc == "KT1VqarPDicMFn1ejmQqqshUkUXTCTXwmkCN", tuple.tzbtc)
					XCTAssert(tuple.sirs == "KT1AafHA1C1vk959wvHWBispY9Y2f3fxBUUo", tuple.sirs)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
}
