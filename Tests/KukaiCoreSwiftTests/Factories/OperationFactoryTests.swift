//
//  OperationFactoryTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class OperationFactoryTests: XCTestCase {

    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }
	
	func testSend() {
		let xtzOp = OperationFactory.sendOperation(MockConstants.xtz_1, of: MockConstants.tokenXTZ, from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
		XCTAssert(xtzOp.count == 1)
		XCTAssert(xtzOp[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(xtzOp[0].counter == "0")
		XCTAssert(xtzOp[0].operationKind == .transaction)
		XCTAssert(xtzOp[0] is OperationTransaction)
		
		let tokenOp = OperationFactory.sendOperation(MockConstants.token3Decimals_1, of: MockConstants.token3Decimals, from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
		XCTAssert(tokenOp.count == 1)
		XCTAssert(tokenOp[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(tokenOp[0].counter == "0")
		XCTAssert(tokenOp[0].operationKind == .transaction)
		XCTAssert(tokenOp[0] is OperationSmartContractInvocation)
	}
	
	func testDelegate() {
		let op = OperationFactory.delegateOperation(to: MockConstants.defaultLinearWallet.address, from: MockConstants.defaultHdWallet.address)
		XCTAssert(op.count == 1)
		XCTAssert(op[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[0].counter == "0")
		XCTAssert(op[0].operationKind == .delegation)
		XCTAssert(op[0] is OperationDelegation)
	}
	
	func testUnDelegate() {
		let op = OperationFactory.undelegateOperation(address: MockConstants.defaultHdWallet.address)
		XCTAssert(op.count == 1)
		XCTAssert(op[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[0].counter == "0")
		XCTAssert(op[0].operationKind == .delegation)
		XCTAssert(op[0] is OperationDelegation)
	}
	
	func testAllowance() {
		let op = OperationFactory.allowanceOperation(tokenAddress: MockConstants.token3Decimals.tokenContractAddress ?? "", spenderAddress: MockConstants.defaultHdWallet.address, allowance: MockConstants.token3Decimals_1, wallet: MockConstants.defaultHdWallet)
		XCTAssert(op.source == MockConstants.defaultHdWallet.address)
		XCTAssert(op.counter == "0")
		XCTAssert(op.operationKind == .transaction)
		XCTAssert(op is OperationSmartContractInvocation)
	}
	
	func testPayload() {
		let payload = OperationFactory.operationPayload(fromMetadata: MockConstants.operationMetadata, andOperations: MockConstants.sendOperations, withWallet: MockConstants.defaultHdWallet)
		XCTAssert(payload.branch == "BLEDGNuADAwZfKK7iZ6PHnu7gZFSXuRPVFXe2PhSnb6aMyKn3mK", payload.branch)
		XCTAssert(payload.contents.count == 1)
		XCTAssert(payload.contents[0].operationKind == .transaction)
		XCTAssert(payload.contents[0] is OperationTransaction)
		XCTAssert(payload.contents[0].counter == "143231", payload.contents[0].counter ?? "")
	}
	
	func testXtzToToken() {
		let op = OperationFactory.liquidityBakingXtzToToken(xtzAmount: XTZAmount(fromNormalisedAmount: 1.5), minTokenAmount: TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 8), contract: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", wallet: MockConstants.defaultHdWallet, timeout: 30)
		
		XCTAssert(op.count == 1)
		XCTAssert(op[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[0].counter == "0")
		XCTAssert(op[0].operationKind == .transaction)
		XCTAssert(op[0] is OperationSmartContractInvocation)
		
		if let smartOp = op[0] as? OperationSmartContractInvocation {
			XCTAssert(smartOp.amount == "1500000", smartOp.amount)
			XCTAssert(smartOp.destination == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", smartOp.destination)
			
			let entrypoint = smartOp.parameters["entrypoint"] as? String
			let value = smartOp.parameters["value"] as? MichelsonPair
			let address = value?.argIndexAsValue(0)?.value
			let amount = value?.argIndexAsValue(1)?.value
			
			XCTAssert(entrypoint == "xtzToToken", entrypoint ?? "-")
			XCTAssert(address == "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF", address ?? "-")
			XCTAssert(amount == "100000000", amount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
	}
	
	func testTokenToXTZ() {
		let op = OperationFactory.liquidityBakingTokenToXTZ(tokenAmount: TokenAmount(fromNormalisedAmount: 1.5, decimalPlaces: 8), minXTZAmount: XTZAmount(fromNormalisedAmount: 1), contract: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tokenContract: "KT1VqarPDicMFn1ejmQqqshUkUXTCTXwmkCN", currentAllowance: TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 8), wallet: MockConstants.defaultHdWallet, timeout: 30)
		
		XCTAssert(op.count == 3)
		XCTAssert(op[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[1].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[2].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[0].counter == "0")
		XCTAssert(op[1].counter == "0")
		XCTAssert(op[2].counter == "0")
		XCTAssert(op[0].operationKind == .transaction)
		XCTAssert(op[1].operationKind == .transaction)
		XCTAssert(op[2].operationKind == .transaction)
		XCTAssert(op[0] is OperationSmartContractInvocation)
		XCTAssert(op[1] is OperationSmartContractInvocation)
		XCTAssert(op[2] is OperationSmartContractInvocation)
		
		if let smartOp1 = op[0] as? OperationSmartContractInvocation {
			XCTAssert(smartOp1.amount == "0", smartOp1.amount)
			XCTAssert(smartOp1.destination == "KT1VqarPDicMFn1ejmQqqshUkUXTCTXwmkCN", smartOp1.destination)
			
			let entrypoint = smartOp1.parameters["entrypoint"] as? String
			let value = smartOp1.parameters["value"] as? MichelsonPair
			let address = value?.argIndexAsValue(0)?.value
			let amount = value?.argIndexAsValue(1)?.value
			
			XCTAssert(entrypoint == "approve", entrypoint ?? "-")
			XCTAssert(address == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", address ?? "-")
			XCTAssert(amount == "0", amount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
		
		
		
		if let smartOp2 = op[1] as? OperationSmartContractInvocation {
			XCTAssert(smartOp2.amount == "0", smartOp2.amount)
			XCTAssert(smartOp2.destination == "KT1VqarPDicMFn1ejmQqqshUkUXTCTXwmkCN", smartOp2.destination)
			
			let entrypoint = smartOp2.parameters["entrypoint"] as? String
			let value = smartOp2.parameters["value"] as? MichelsonPair
			let address = value?.argIndexAsValue(0)?.value
			let amount = value?.argIndexAsValue(1)?.value
			
			XCTAssert(entrypoint == "approve", entrypoint ?? "-")
			XCTAssert(address == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", address ?? "-")
			XCTAssert(amount == "150000000", amount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
		
		
		
		if let smartOp3 = op[2] as? OperationSmartContractInvocation {
			XCTAssert(smartOp3.amount == "0", smartOp3.amount)
			XCTAssert(smartOp3.destination == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", smartOp3.destination)
			
			let entrypoint = smartOp3.parameters["entrypoint"] as? String
			let value = smartOp3.parameters["value"] as? MichelsonPair
			let address = value?.argIndexAsValue(0)?.value
			let amount = value?.argIndexAsValue(1)?.value
			let minAmount = value?.argIndexAsValue(2)?.value
			
			XCTAssert(entrypoint == "tokenToXtz", entrypoint ?? "-")
			XCTAssert(address == "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF", address ?? "-")
			XCTAssert(amount == "150000000", amount ?? "-")
			XCTAssert(minAmount == "1000000", amount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
	}
}
