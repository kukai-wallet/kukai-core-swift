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
		
		
		// Send FA1.2
		let tokenOp = OperationFactory.sendOperation(MockConstants.token3Decimals_1, of: MockConstants.token3Decimals, from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
		XCTAssert(tokenOp.count == 1)
		XCTAssert(tokenOp[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(tokenOp[0].counter == "0")
		XCTAssert(tokenOp[0].operationKind == .transaction)
		XCTAssert(tokenOp[0] is OperationTransaction)
		
		if let asTransaction = (tokenOp[0] as? OperationTransaction), let parameters = asTransaction.parameters?.michelsonValue() {
			let address = parameters.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let destination = parameters.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let amount = parameters.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
			
			XCTAssert(address == "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF", address ?? "-")
			XCTAssert(destination == "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG", destination ?? "-")
			XCTAssert(amount == "1000", amount ?? "-")
			
		} else {
			XCTFail("No parameters found")
		}
		
		
		// Send FA2
		let tokenOp2 = OperationFactory.sendOperation(MockConstants.token10Decimals_1, of: MockConstants.token10Decimals, from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
		XCTAssert(tokenOp2.count == 1)
		XCTAssert(tokenOp2[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(tokenOp2[0].counter == "0")
		XCTAssert(tokenOp2[0].operationKind == .transaction)
		XCTAssert(tokenOp2[0] is OperationTransaction)
		
		if let asTransaction2 = (tokenOp2[0] as? OperationTransaction), let parameters2 = asTransaction2.parameters?.michelsonValueArray()?[0] {
			let address = parameters2.michelsonArgsUnknownArray()?.michelsonString(atIndex: 0)
			let destination = parameters2.michelsonArgsUnknownArray()?.michelsonArray(atIndex: 1)?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let tokenId = parameters2.michelsonArgsUnknownArray()?.michelsonArray(atIndex: 1)?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
			let amount = parameters2.michelsonArgsUnknownArray()?.michelsonArray(atIndex: 1)?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
			
			XCTAssert(address == "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF", address ?? "-")
			XCTAssert(destination == "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG", destination ?? "-")
			XCTAssert(tokenId == "0", tokenId ?? "-")
			XCTAssert(amount == "10000000000", amount ?? "-")
			
		} else {
			XCTFail("No parameters found")
		}
		
		
		// Send NFT
		let tokenOp3 = OperationFactory.sendOperation(1, of: (MockConstants.tokenWithNFTs.nfts ?? [])[0], from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
		XCTAssert(tokenOp3.count == 1)
		XCTAssert(tokenOp3[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(tokenOp3[0].counter == "0")
		XCTAssert(tokenOp3[0].operationKind == .transaction)
		XCTAssert(tokenOp3[0] is OperationTransaction)
		
		if let asTransaction3 = (tokenOp3[0] as? OperationTransaction), let parameters3 = asTransaction3.parameters?.michelsonValueArray()?[0] {
			let address = parameters3.michelsonArgsUnknownArray()?.michelsonString(atIndex: 0)
			let destination = parameters3.michelsonArgsUnknownArray()?.michelsonArray(atIndex: 1)?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let tokenId = parameters3.michelsonArgsUnknownArray()?.michelsonArray(atIndex: 1)?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
			let amount = parameters3.michelsonArgsUnknownArray()?.michelsonArray(atIndex: 1)?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
			
			XCTAssert(address == "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF", address ?? "-")
			XCTAssert(destination == "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG", destination ?? "-")
			XCTAssert(tokenId == "4", tokenId ?? "-")
			XCTAssert(amount == "1", amount ?? "-")
			
		} else {
			XCTFail("No parameters found")
		}
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
		XCTAssert(op is OperationTransaction)
	}
	
	func testPayload() {
		let payload = OperationFactory.operationPayload(fromMetadata: MockConstants.operationMetadata, andOperations: MockConstants.sendOperations, withWallet: MockConstants.defaultHdWallet)
		XCTAssert(payload.branch == "BLEDGNuADAwZfKK7iZ6PHnu7gZFSXuRPVFXe2PhSnb6aMyKn3mK", payload.branch)
		XCTAssert(payload.contents.count == 1)
		XCTAssert(payload.contents[0].operationKind == .transaction)
		XCTAssert(payload.contents[0] is OperationTransaction)
		XCTAssert(payload.contents[0].counter == "143231", payload.contents[0].counter ?? "")
	}
	
	func testPayloadNFT() {
		let operation = OperationFactory.sendOperation(1, of: (MockConstants.tokenWithNFTs.nfts ?? [])[0], from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
		let payload = OperationFactory.operationPayload(fromMetadata: MockConstants.operationMetadata, andOperations: operation, withWallet: MockConstants.defaultHdWallet)
		XCTAssert(payload.branch == "BLEDGNuADAwZfKK7iZ6PHnu7gZFSXuRPVFXe2PhSnb6aMyKn3mK", payload.branch)
		XCTAssert(payload.contents.count == 1)
		XCTAssert(payload.contents[0].operationKind == .transaction)
		XCTAssert(payload.contents[0] is OperationTransaction)
		XCTAssert(payload.contents[0].counter == "143231", payload.contents[0].counter ?? "")
		
		if let asTransaction = (payload.contents[0] as? OperationTransaction), let parameters = asTransaction.parameters?.michelsonValueArray()?[0] {
			let address = parameters.michelsonArgsUnknownArray()?.michelsonString(atIndex: 0)
			let destination = parameters.michelsonArgsUnknownArray()?.michelsonArray(atIndex: 1)?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let tokenId = parameters.michelsonArgsUnknownArray()?.michelsonArray(atIndex: 1)?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
			let amount = parameters.michelsonArgsUnknownArray()?.michelsonArray(atIndex: 1)?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
			
			XCTAssert(address == "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF", address ?? "-")
			XCTAssert(destination == "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG", destination ?? "-")
			XCTAssert(tokenId == "4", tokenId ?? "-")
			XCTAssert(amount == "1", amount ?? "-")
			
		} else {
			XCTFail("No parameters found")
		}
	}
	
	func testXtzToToken() {
		let op = OperationFactory.swapXtzToToken(withdex: .lb, xtzAmount: XTZAmount(fromNormalisedAmount: 1.5), minTokenAmount: TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 8), dexContract: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", wallet: MockConstants.defaultHdWallet, timeout: 30)
		
		XCTAssert(op.count == 1)
		XCTAssert(op[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[0].counter == "0")
		XCTAssert(op[0].operationKind == .transaction)
		XCTAssert(op[0] is OperationTransaction)
		
		if let smartOp = op[0] as? OperationTransaction {
			XCTAssert(smartOp.amount == "1500000", smartOp.amount)
			XCTAssert(smartOp.destination == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", smartOp.destination)
			
			let entrypoint = smartOp.parameters?["entrypoint"] as? String
			let value = smartOp.parameters?.michelsonValue()
			let address = value?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let amount = value?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
			
			XCTAssert(entrypoint == "xtzToToken", entrypoint ?? "-")
			XCTAssert(address == "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF", address ?? "-")
			XCTAssert(amount == "100000000", amount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
	}
	
	func testTokenToXTZ() {
		let op = OperationFactory.swapTokenToXTZ(withDex: .lb, tokenAmount: TokenAmount(fromNormalisedAmount: 1.5, decimalPlaces: 8), minXTZAmount: XTZAmount(fromNormalisedAmount: 1), dexContract: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tokenContract: "KT1VqarPDicMFn1ejmQqqshUkUXTCTXwmkCN", currentAllowance: TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 8), wallet: MockConstants.defaultHdWallet, timeout: 30)
		
		XCTAssert(op.count == 4)
		XCTAssert(op[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[1].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[2].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[0].counter == "0")
		XCTAssert(op[1].counter == "0")
		XCTAssert(op[2].counter == "0")
		XCTAssert(op[0].operationKind == .transaction)
		XCTAssert(op[1].operationKind == .transaction)
		XCTAssert(op[2].operationKind == .transaction)
		XCTAssert(op[0] is OperationTransaction)
		XCTAssert(op[1] is OperationTransaction)
		XCTAssert(op[2] is OperationTransaction)
		
		if let smartOp1 = op[0] as? OperationTransaction {
			XCTAssert(smartOp1.amount == "0", smartOp1.amount)
			XCTAssert(smartOp1.destination == "KT1VqarPDicMFn1ejmQqqshUkUXTCTXwmkCN", smartOp1.destination)
			
			let entrypoint = smartOp1.parameters?["entrypoint"] as? String
			let value = smartOp1.parameters?.michelsonValue()
			let address = value?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let amount = value?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
			
			XCTAssert(entrypoint == "approve", entrypoint ?? "-")
			XCTAssert(address == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", address ?? "-")
			XCTAssert(amount == "0", amount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
		
		
		
		if let smartOp2 = op[1] as? OperationTransaction {
			XCTAssert(smartOp2.amount == "0", smartOp2.amount)
			XCTAssert(smartOp2.destination == "KT1VqarPDicMFn1ejmQqqshUkUXTCTXwmkCN", smartOp2.destination)
			
			let entrypoint = smartOp2.parameters?["entrypoint"] as? String
			let value = smartOp2.parameters?.michelsonValue()
			let address = value?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let amount = value?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
			
			XCTAssert(entrypoint == "approve", entrypoint ?? "-")
			XCTAssert(address == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", address ?? "-")
			XCTAssert(amount == "150000000", amount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
		
		
		
		if let smartOp3 = op[2] as? OperationTransaction {
			XCTAssert(smartOp3.amount == "0", smartOp3.amount)
			XCTAssert(smartOp3.destination == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", smartOp3.destination)
			
			let entrypoint = smartOp3.parameters?["entrypoint"] as? String
			let value = smartOp3.parameters?.michelsonValue()
			let address = value?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let amount = value?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
			let minAmount = value?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
			
			XCTAssert(entrypoint == "tokenToXtz", entrypoint ?? "-")
			XCTAssert(address == "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF", address ?? "-")
			XCTAssert(amount == "150000000", amount ?? "-")
			XCTAssert(minAmount == "1000000", amount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
	}
	
	func testAddLiquidity() {
		let op = OperationFactory.addLiquidity(withDex: .lb, xtzToDeposit: XTZAmount(fromNormalisedAmount: 1), tokensToDeposit: TokenAmount(fromNormalisedAmount: 1.5, decimalPlaces: 8), minLiquidtyMinted: TokenAmount(fromNormalisedAmount: 1.5, decimalPlaces: 8), tokenContract: "KT1VqarPDicMFn1ejmQqqshUkUXTCTXwmkCN", dexContract: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", currentAllowance: TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 8), isInitialLiquidity: false, wallet: MockConstants.defaultHdWallet, timeout: 30)
		
		XCTAssert(op.count == 4)
		XCTAssert(op[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[1].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[2].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[0].counter == "0")
		XCTAssert(op[1].counter == "0")
		XCTAssert(op[2].counter == "0")
		XCTAssert(op[0].operationKind == .transaction)
		XCTAssert(op[1].operationKind == .transaction)
		XCTAssert(op[2].operationKind == .transaction)
		XCTAssert(op[0] is OperationTransaction)
		XCTAssert(op[1] is OperationTransaction)
		XCTAssert(op[2] is OperationTransaction)
		
		if let smartOp1 = op[0] as? OperationTransaction {
			XCTAssert(smartOp1.amount == "0", smartOp1.amount)
			XCTAssert(smartOp1.destination == "KT1VqarPDicMFn1ejmQqqshUkUXTCTXwmkCN", smartOp1.destination)
			
			let entrypoint = smartOp1.parameters?["entrypoint"] as? String
			let value = smartOp1.parameters?.michelsonValue()
			let address = value?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let amount = value?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
			
			XCTAssert(entrypoint == "approve", entrypoint ?? "-")
			XCTAssert(address == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", address ?? "-")
			XCTAssert(amount == "0", amount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
		
		
		
		if let smartOp2 = op[1] as? OperationTransaction {
			XCTAssert(smartOp2.amount == "0", smartOp2.amount)
			XCTAssert(smartOp2.destination == "KT1VqarPDicMFn1ejmQqqshUkUXTCTXwmkCN", smartOp2.destination)
			
			let entrypoint = smartOp2.parameters?["entrypoint"] as? String
			let value = smartOp2.parameters?.michelsonValue()
			let address = value?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let amount = value?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
			
			XCTAssert(entrypoint == "approve", entrypoint ?? "-")
			XCTAssert(address == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", address ?? "-")
			XCTAssert(amount == "150000000", amount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
		
		
		
		if let smartOp3 = op[2] as? OperationTransaction {
			XCTAssert(smartOp3.amount == "1000000", smartOp3.amount)
			XCTAssert(smartOp3.destination == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", smartOp3.destination)
			
			let entrypoint = smartOp3.parameters?["entrypoint"] as? String
			let value = smartOp3.parameters?.michelsonValue()
			let address = value?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let tokenAmount = value?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
			let minLqtAmount = value?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
			
			XCTAssert(entrypoint == "addLiquidity", entrypoint ?? "-")
			XCTAssert(address == "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF", address ?? "-")
			XCTAssert(tokenAmount == "150000000", tokenAmount ?? "-")
			XCTAssert(minLqtAmount == "150000000", minLqtAmount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
	}
	
	func testRemoveLiquidity() {
		let op = OperationFactory.removeLiquidity(withDex: .lb, minXTZ: XTZAmount(fromNormalisedAmount: 1), minToken: TokenAmount(fromNormalisedAmount: 1.5, decimalPlaces: 8), liquidityToBurn: TokenAmount(fromNormalisedAmount: 1.5, decimalPlaces: 8), dexContract: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", wallet: MockConstants.defaultHdWallet, timeout: 30)
		
		XCTAssert(op.count == 1)
		XCTAssert(op[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[0].counter == "0")
		XCTAssert(op[0].operationKind == .transaction)
		XCTAssert(op[0] is OperationTransaction)
		
		if let smartOp = op[0] as? OperationTransaction {
			XCTAssert(smartOp.amount == "0", smartOp.amount)
			XCTAssert(smartOp.destination == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", smartOp.destination)
			
			let entrypoint = smartOp.parameters?["entrypoint"] as? String
			let value = smartOp.parameters?.michelsonValue()
			let address = value?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let lqtBurnAmount = value?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
			let xtzAmount = value?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
			let tokenAmount = value?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
			
			XCTAssert(entrypoint == "removeLiquidity", entrypoint ?? "-")
			XCTAssert(address == "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF", address ?? "-")
			XCTAssert(lqtBurnAmount == "150000000", lqtBurnAmount ?? "-")
			XCTAssert(xtzAmount == "1000000", xtzAmount ?? "-")
			XCTAssert(tokenAmount == "150000000", tokenAmount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
	}
}
