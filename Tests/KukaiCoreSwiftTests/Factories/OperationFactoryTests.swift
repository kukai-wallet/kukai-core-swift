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
			
			XCTAssert(address == "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss", address ?? "-")
			XCTAssert(destination == "tz1iQpiBTKtzfbVgogjyhPiGrrV5zAKUKNvy", destination ?? "-")
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
			
			XCTAssert(address == "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss", address ?? "-")
			XCTAssert(destination == "tz1iQpiBTKtzfbVgogjyhPiGrrV5zAKUKNvy", destination ?? "-")
			XCTAssert(tokenId == "0", tokenId ?? "-")
			XCTAssert(amount == "10000000000", amount ?? "-")
			
		} else {
			XCTFail("No parameters found")
		}
		
		
		// Send NFT
		let tokenOp3 = OperationFactory.sendOperation(1, ofNft: (MockConstants.tokenWithNFTs.nfts ?? [])[0], from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
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
			
			XCTAssert(address == "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss", address ?? "-")
			XCTAssert(destination == "tz1iQpiBTKtzfbVgogjyhPiGrrV5zAKUKNvy", destination ?? "-")
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
	
	func testStake() {
		let op = OperationFactory.stakeOperation(from: MockConstants.defaultHdWallet.address, amount: XTZAmount(fromNormalisedAmount: 5))
		XCTAssert(op.count == 1)
		XCTAssert(op[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[0].counter == "0")
		XCTAssert(op[0].operationKind == .transaction)
		XCTAssert(op[0] is OperationTransaction)
		
		XCTAssert((op[0] as? OperationTransaction)?.amount.description == "5000000", (op[0] as? OperationTransaction)?.amount.description ?? "-")
	}
	
	func testUnstake() {
		let op = OperationFactory.unstakeOperation(from: MockConstants.defaultHdWallet.address, amount: XTZAmount(fromNormalisedAmount: 6))
		XCTAssert(op.count == 1)
		XCTAssert(op[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[0].counter == "0")
		XCTAssert(op[0].operationKind == .transaction)
		XCTAssert(op[0] is OperationTransaction)
		
		XCTAssert((op[0] as? OperationTransaction)?.amount.description == "6000000", (op[0] as? OperationTransaction)?.amount.description ?? "-")
	}
	
	func testFinaliseUnstake() {
		let op = OperationFactory.finaliseUnstakeOperation(from: MockConstants.defaultHdWallet.address)
		XCTAssert(op.count == 1)
		XCTAssert(op[0].source == MockConstants.defaultHdWallet.address)
		XCTAssert(op[0].counter == "0")
		XCTAssert(op[0].operationKind == .transaction)
		XCTAssert(op[0] is OperationTransaction)
		
		XCTAssert((op[0] as? OperationTransaction)?.amount.description == "0", (op[0] as? OperationTransaction)?.amount.description ?? "-")
	}
	
	func testAllowance() {
		let address = MockConstants.defaultHdWallet.address
		let op = OperationFactory.allowanceOperation(standard: .fa12, tokenAddress: MockConstants.token3Decimals.tokenContractAddress ?? "", tokenId: nil, spenderAddress: address, allowance: MockConstants.token3Decimals_1, walletAddress: address)
		XCTAssert(op.source == MockConstants.defaultHdWallet.address)
		XCTAssert(op.counter == "0")
		XCTAssert(op.operationKind == .transaction)
		XCTAssert(op is OperationTransaction)
		
		let op2 = OperationFactory.allowanceOperation(standard: .fa2, tokenAddress: MockConstants.token3Decimals.tokenContractAddress ?? "", tokenId: "0", spenderAddress: address, allowance: MockConstants.token3Decimals_1, walletAddress: address)
		XCTAssert(op2.source == MockConstants.defaultHdWallet.address)
		XCTAssert(op2.counter == "0")
		XCTAssert(op2.operationKind == .transaction)
		XCTAssert(op2 is OperationTransaction)
	}
	
	func testPayload() {
		let address = MockConstants.defaultHdWallet.address
		let key = MockConstants.defaultHdWallet.publicKeyBase58encoded()
		let payload = OperationFactory.operationPayload(fromMetadata: MockConstants.operationMetadata, andOperations: MockConstants.sendOperations, walletAddress: address, base58EncodedPublicKey: key)
		XCTAssert(payload.branch == "BLEDGNuADAwZfKK7iZ6PHnu7gZFSXuRPVFXe2PhSnb6aMyKn3mK", payload.branch)
		XCTAssert(payload.contents.count == 1)
		XCTAssert(payload.contents[0].operationKind == .transaction)
		XCTAssert(payload.contents[0] is OperationTransaction)
		XCTAssert(payload.contents[0].counter == "143231", payload.contents[0].counter ?? "")
	}
	
	func testPayloadNFT() {
		let address = MockConstants.defaultHdWallet.address
		let key = MockConstants.defaultHdWallet.publicKeyBase58encoded()
		let operation = OperationFactory.sendOperation(1, ofNft: (MockConstants.tokenWithNFTs.nfts ?? [])[0], from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
		let payload = OperationFactory.operationPayload(fromMetadata: MockConstants.operationMetadata, andOperations: operation, walletAddress: address, base58EncodedPublicKey: key)
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
			
			XCTAssert(address == "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss", address ?? "-")
			XCTAssert(destination == "tz1iQpiBTKtzfbVgogjyhPiGrrV5zAKUKNvy", destination ?? "-")
			XCTAssert(tokenId == "4", tokenId ?? "-")
			XCTAssert(amount == "1", amount ?? "-")
			
		} else {
			XCTFail("No parameters found")
		}
	}
	
	func testXtzToToken() {
		let address = MockConstants.defaultHdWallet.address
		let token = DipDupToken(symbol: "TEST", address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tokenId: 0, decimals: 0, standard: .fa12, thumbnailUri: nil)
		let dex = DipDupExchange(name: .lb, address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tezPool: "10000000000", tokenPool: "100000", sharesTotal: "1000", midPrice: "1", token: token)
		let op = OperationFactory.swapXtzToToken(withDex: dex, xtzAmount: XTZAmount(fromNormalisedAmount: 1.5), minTokenAmount: TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 8), walletAddress: address, timeout: 30)
		
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
			XCTAssert(address == "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss", address ?? "-")
			XCTAssert(amount == "100000000", amount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
	}
	
	/*
	func testTokenToXTZ_LB() {
		let address = MockConstants.defaultHdWallet.address
		let token = DipDupToken(symbol: "TEST", address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tokenId: 0, decimals: 0, standard: .fa12)
		let dex = DipDupExchange(name: .lb, address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tezPool: "10000000000", tokenPool: "100000", sharesTotal: "1000", midPrice: "1", token: token)
		let op = OperationFactory.swapTokenToXTZ(withDex: dex, tokenAmount: TokenAmount(fromNormalisedAmount: 1.5, decimalPlaces: 8), minXTZAmount: XTZAmount(fromNormalisedAmount: 1), walletAddress: address, timeout: 30)
		
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
			XCTAssert(smartOp1.destination == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", smartOp1.destination)
			
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
			XCTAssert(smartOp2.destination == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", smartOp2.destination)
			
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
			XCTAssert(address == "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss", address ?? "-")
			XCTAssert(amount == "150000000", amount ?? "-")
			XCTAssert(minAmount == "1000000", amount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
	}
	*/
	
	/*
	func testTokenToXTZ_QUIPU() {
		let address = MockConstants.defaultHdWallet.address
		let token = DipDupToken(symbol: "TEST", address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tokenId: 0, decimals: 0, standard: .fa2)
		let dex = DipDupExchange(name: .quipuswap, address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tezPool: "10000000000", tokenPool: "100000", sharesTotal: "1000", midPrice: "1", token: token)
		let op = OperationFactory.swapTokenToXTZ(withDex: dex, tokenAmount: TokenAmount(fromNormalisedAmount: 1.5, decimalPlaces: 8), minXTZAmount: XTZAmount(fromNormalisedAmount: 1), walletAddress: address, timeout: 30)
		
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
			XCTAssert(smartOp1.destination == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", smartOp1.destination)
			
			let entrypoint = smartOp1.parameters?["entrypoint"] as? String
			let value = smartOp1.parameters?.michelsonValueArray()?[0]
			let address = value?.michelsonArgsUnknownArray()?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let amount = value?.michelsonArgsUnknownArray()?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
			
			XCTAssert(entrypoint == "update_operators", entrypoint ?? "-")
			XCTAssert(address == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", address ?? "-")
			XCTAssert(amount == "0", amount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
		
		if let smartOp2 = op[1] as? OperationTransaction {
			XCTAssert(smartOp2.amount == "0", smartOp2.amount)
			XCTAssert(smartOp2.destination == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", smartOp2.destination)
			
			let entrypoint = smartOp2.parameters?["entrypoint"] as? String
			let value = smartOp2.parameters?.michelsonValueArray()?[0]
			let address = value?.michelsonArgsUnknownArray()?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let amount = value?.michelsonArgsUnknownArray()?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
			
			XCTAssert(entrypoint == "update_operators", entrypoint ?? "-")
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
			let address = value?.michelsonArgsArray()?.michelsonString(atIndex: 1)
			let amount = value?.michelsonArgsArray()?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
			let minAmount = value?.michelsonArgsArray()?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
			
			XCTAssert(entrypoint == "tokenToTezPayment", entrypoint ?? "-")
			XCTAssert(address == "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss", address ?? "-")
			XCTAssert(amount == "150000000", amount ?? "-")
			XCTAssert(minAmount == "1000000", amount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
	}
	*/
	
	/*
	func testAddLiquidity_LB() {
		let address = MockConstants.defaultHdWallet.address
		let token = DipDupToken(symbol: "TEST", address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tokenId: 0, decimals: 0, standard: .fa12)
		let dex = DipDupExchange(name: .lb, address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tezPool: "10000000000", tokenPool: "100000", sharesTotal: "1000", midPrice: "1", token: token)
		let op = OperationFactory.addLiquidity(withDex: dex, xtz: XTZAmount(fromNormalisedAmount: 1), token: TokenAmount(fromNormalisedAmount: 1.5, decimalPlaces: 8), minLiquidty: TokenAmount(fromNormalisedAmount: 1.5, decimalPlaces: 8), isInitialLiquidity: false, walletAddress: address, timeout: 30)
		
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
			XCTAssert(smartOp1.destination == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", smartOp1.destination)
			
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
			XCTAssert(smartOp2.destination == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", smartOp2.destination)
			
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
			XCTAssert(address == "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss", address ?? "-")
			XCTAssert(tokenAmount == "150000000", tokenAmount ?? "-")
			XCTAssert(minLqtAmount == "150000000", minLqtAmount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
	}
	*/
	
	/*
	func testAddLiquidity_QUIPU() {
		let address = MockConstants.defaultHdWallet.address
		let token = DipDupToken(symbol: "TEST", address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tokenId: 0, decimals: 0, standard: .fa2)
		let dex = DipDupExchange(name: .quipuswap, address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tezPool: "10000000000", tokenPool: "100000", sharesTotal: "1000", midPrice: "1", token: token)
		let op = OperationFactory.addLiquidity(withDex: dex, xtz: XTZAmount(fromNormalisedAmount: 1), token: TokenAmount(fromNormalisedAmount: 1.5, decimalPlaces: 8), minLiquidty: TokenAmount(fromNormalisedAmount: 1.5, decimalPlaces: 8), isInitialLiquidity: false, walletAddress: address, timeout: 30)
		
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
			XCTAssert(smartOp1.destination == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", smartOp1.destination)
			
			let entrypoint = smartOp1.parameters?["entrypoint"] as? String
			let value = smartOp1.parameters?.michelsonValueArray()?[0]
			let address = value?.michelsonArgsUnknownArray()?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let amount = value?.michelsonArgsUnknownArray()?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
			
			XCTAssert(entrypoint == "update_operators", entrypoint ?? "-")
			XCTAssert(address == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", address ?? "-")
			XCTAssert(amount == "0", amount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
		
		if let smartOp2 = op[1] as? OperationTransaction {
			XCTAssert(smartOp2.amount == "0", smartOp2.amount)
			XCTAssert(smartOp2.destination == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", smartOp2.destination)
			
			let entrypoint = smartOp2.parameters?["entrypoint"] as? String
			let value = smartOp2.parameters?.michelsonValueArray()?[0]
			let address = value?.michelsonArgsUnknownArray()?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let amount = value?.michelsonArgsUnknownArray()?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
			
			XCTAssert(entrypoint == "update_operators", entrypoint ?? "-")
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
			let token = value?.michelsonInt()
			
			XCTAssert(entrypoint == "investLiquidity", entrypoint ?? "-")
			XCTAssert(token == "150000000", token ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
	}
	*/
	
	func testRemoveLiquidity() {
		let address = MockConstants.defaultHdWallet.address
		let token = DipDupToken(symbol: "TEST", address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tokenId: 0, decimals: 0, standard: .fa12, thumbnailUri: nil)
		let dex = DipDupExchange(name: .lb, address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tezPool: "10000000000", tokenPool: "100000", sharesTotal: "1000", midPrice: "1", token: token)
		let op = OperationFactory.removeLiquidity(withDex: dex, minXTZ: XTZAmount(fromNormalisedAmount: 1), minToken: TokenAmount(fromNormalisedAmount: 1.5, decimalPlaces: 8), liquidityToBurn: TokenAmount(fromNormalisedAmount: 1.5, decimalPlaces: 8), walletAddress: address, timeout: 30)
		
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
			XCTAssert(address == "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss", address ?? "-")
			XCTAssert(lqtBurnAmount == "150000000", lqtBurnAmount ?? "-")
			XCTAssert(xtzAmount == "1000000", xtzAmount ?? "-")
			XCTAssert(tokenAmount == "150000000", tokenAmount ?? "-")
			
		} else {
			XCTFail("invalid op type")
		}
	}
	
	func testExtractors() {
		
		let xtzOp = OperationFactory.sendOperation(MockConstants.xtz_1, of: MockConstants.tokenXTZ, from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
		let opFA1 = OperationFactory.sendOperation(MockConstants.token3Decimals_1, of: MockConstants.token3Decimals, from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
		let opFA2 = OperationFactory.sendOperation(MockConstants.token10Decimals_1, of: MockConstants.token10Decimals, from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
		let opNFT = OperationFactory.sendOperation(1, ofNft: (MockConstants.tokenWithNFTs.nfts ?? [])[0], from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
		
		let dexToken = DipDupToken(symbol: "BLAH", address: "KT1def", tokenId: 123, decimals: 3, standard: .fa2, thumbnailUri: nil)
		let dex = DipDupExchange(name: .quipuswap, address: "KT1abc", tezPool: "100000000000", tokenPool: "1000000000", sharesTotal: "100000", midPrice: "14", token: dexToken)
		let swap = OperationFactory.swapXtzToToken(withDex: dex, xtzAmount: .init(fromNormalisedAmount: 14), minTokenAmount: .init(fromNormalisedAmount: 2, decimalPlaces: 3), walletAddress: "tz1abc", timeout: 60)
		let delegate = OperationFactory.delegateOperation(to: "KT1abc", from: MockConstants.defaultHdWallet.address)
		let stake = OperationFactory.stakeOperation(from: MockConstants.defaultHdWallet.address, amount: TokenAmount(fromNormalisedAmount: 14, decimalPlaces: 6))
		let unstake = OperationFactory.unstakeOperation(from: MockConstants.defaultHdWallet.address, amount: TokenAmount(fromNormalisedAmount: 14, decimalPlaces: 6))
		let finaliseUnstake = OperationFactory.finaliseUnstakeOperation(from: MockConstants.defaultHdWallet.address)
		
		
		// is single transctions
		XCTAssert( OperationFactory.Extractor.isSingleTransaction(operations: xtzOp) != nil )
		XCTAssert( OperationFactory.Extractor.isSingleTransaction(operations: opFA1) != nil )
		XCTAssert( OperationFactory.Extractor.isSingleTransaction(operations: opFA2) != nil )
		XCTAssert( OperationFactory.Extractor.isSingleTransaction(operations: opNFT) != nil )
		XCTAssert( OperationFactory.Extractor.isSingleTransaction(operations: MockConstants.sendOperationWithReveal) != nil )
		
		
		// Is Tez transfer
		XCTAssert( OperationFactory.Extractor.isTezTransfer(operations: xtzOp) != nil )
		XCTAssert( OperationFactory.Extractor.isTezTransfer(operations: opFA1) == nil )
		XCTAssert( OperationFactory.Extractor.isTezTransfer(operations: opFA2) == nil )
		XCTAssert( OperationFactory.Extractor.isTezTransfer(operations: opNFT) == nil )
		XCTAssert( OperationFactory.Extractor.isTezTransfer(operations: MockConstants.sendOperationWithReveal) != nil )
		
		
		// Is Delegate
		XCTAssert( OperationFactory.Extractor.isDelegate(operations: delegate) != nil )
		XCTAssert( OperationFactory.Extractor.isDelegate(operations: opFA1) == nil )
		
		
		// Is Stake
		let stakeOp = OperationFactory.Extractor.isStake(operations: stake)
		XCTAssert( stakeOp != nil )
		XCTAssert( stakeOp?.destination == MockConstants.defaultHdWallet.address)
		
		
		// Is Unstake
		let unstakeOp = OperationFactory.Extractor.isUnstake(operations: unstake)
		XCTAssert( unstakeOp != nil )
		XCTAssert( unstakeOp?.destination == MockConstants.defaultHdWallet.address)
		
		
		// Is FinaliseUnstake
		let finaliseUnstakeOp = OperationFactory.Extractor.isFinaliseUnstake(operations: finaliseUnstake)
		XCTAssert( finaliseUnstakeOp != nil )
		XCTAssert( finaliseUnstakeOp?.destination == MockConstants.defaultHdWallet.address)
		
		
		// is token transfer
		XCTAssert( OperationFactory.Extractor.isFaTokenTransfer(operations: xtzOp) == nil )
		
		let fa1Results = OperationFactory.Extractor.isFaTokenTransfer(operations: opFA1)
		XCTAssert(fa1Results?.tokenContract == "KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8", fa1Results?.tokenContract ?? "-")
		XCTAssert(fa1Results?.rpcAmount == "1000", fa1Results?.rpcAmount ?? "-")
		XCTAssert(fa1Results?.tokenId == nil, fa1Results?.tokenId?.description ?? "-")
		
		let fa2Results = OperationFactory.Extractor.isFaTokenTransfer(operations: opFA2)
		XCTAssert(fa2Results?.tokenContract == "KT1G1cCRNBgQ48mVDjopHjEmTN5Sbtar8nn9", fa2Results?.tokenContract ?? "-")
		XCTAssert(fa2Results?.rpcAmount == "10000000000", fa2Results?.rpcAmount ?? "-")
		XCTAssert(fa2Results?.tokenId == 0, fa2Results?.tokenId?.description ?? "-")
		
		let nftResults = OperationFactory.Extractor.isFaTokenTransfer(operations: opNFT)
		XCTAssert(nftResults?.tokenContract == "KT1G1cCRNBgQ48mVDjopHjEmTN5Sbtabc123", nftResults?.tokenContract ?? "-")
		XCTAssert(nftResults?.rpcAmount == "1", nftResults?.rpcAmount ?? "-")
		XCTAssert(nftResults?.tokenId == 4, nftResults?.tokenId?.description ?? "-")
		
		XCTAssert( OperationFactory.Extractor.isFaTokenTransfer(operations: MockConstants.sendOperationWithReveal) == nil )
		
		
		// contains all operationTransaction
		XCTAssert( OperationFactory.Extractor.containsAllOperationTransactions(operations: xtzOp) )
		XCTAssert( OperationFactory.Extractor.containsAllOperationTransactions(operations: opFA1) )
		XCTAssert( OperationFactory.Extractor.containsAllOperationTransactions(operations: opFA2) )
		XCTAssert( OperationFactory.Extractor.containsAllOperationTransactions(operations: opNFT) )
		XCTAssert( OperationFactory.Extractor.containsAllOperationTransactions(operations: MockConstants.sendOperationWithReveal, ignoreReveal: true) )
		XCTAssert( OperationFactory.Extractor.containsAllOperationTransactions(operations: MockConstants.sendOperationWithReveal, ignoreReveal: false) == false )
		
		
		// is contract
		XCTAssert( OperationFactory.Extractor.isContractCall(operation: xtzOp[0]) == nil )
		
		let contractDetails1 = OperationFactory.Extractor.isContractCall(operation: swap[0])
		XCTAssert(contractDetails1?.address == "KT1abc", contractDetails1?.address ?? "-")
		XCTAssert(contractDetails1?.entrypoint == "tezToTokenPayment", contractDetails1?.entrypoint ?? "-")
		
		
		// is contract not transfer
		XCTAssert( OperationFactory.Extractor.isNonTransferContractCall(operation: opFA1[0]) == nil )
		
		let contractDetails2 = OperationFactory.Extractor.isNonTransferContractCall(operation: swap[0])
		XCTAssert(contractDetails2?.address == "KT1abc", contractDetails2?.address ?? "-")
		XCTAssert(contractDetails2?.entrypoint == "tezToTokenPayment", contractDetails2?.entrypoint ?? "-")
		
		
		// is single contract
		XCTAssert( OperationFactory.Extractor.isNonTransferContractCall(operation: opFA1[0]) == nil )
		
		let contractDetails3 = OperationFactory.Extractor.isSingleContractCall(operations: swap)
		XCTAssert(contractDetails3?.address == "KT1abc", contractDetails3?.address ?? "-")
		XCTAssert(contractDetails3?.entrypoint == "tezToTokenPayment", contractDetails3?.entrypoint ?? "-")
	}
	
	func testExtractors3RouteV3() {
		let decoder = JSONDecoder()
		
		let fa1ForXTZData = MockConstants.jsonStub(fromFilename: "3route_v3_fa1-for-xtz")
		let fa1ForXTZJson = (try? decoder.decode([OperationTransaction].self, from: fa1ForXTZData)) ?? []
		XCTAssert(fa1ForXTZJson.count > 0)
		
		let details1 = OperationFactory.Extractor.firstNonZeroTokenTransferAmount(operations: fa1ForXTZJson)
		XCTAssert(details1?.tokenContract == "KT1JVjgXPMMSaa6FkzeJcgb8q9cUaLmwaJUX", details1?.tokenContract ?? "-")
		XCTAssert(details1?.rpcAmount == "6605336839045864425", details1?.rpcAmount ?? "-")
		XCTAssert(details1?.tokenId == nil, details1?.tokenId?.description ?? "-")
		XCTAssert(details1?.destination == "KT1R7WEtNNim3YgkxPt8wPMczjH3eyhbJMtz", details1?.destination ?? "-")
		
		
		let fa2ForXTZData = MockConstants.jsonStub(fromFilename: "3route_v3_fa2-for-xtz")
		let fa2ForXTZJson = (try? decoder.decode([OperationTransaction].self, from: fa2ForXTZData)) ?? []
		XCTAssert(fa2ForXTZJson.count > 0)
		
		let details2 = OperationFactory.Extractor.firstNonZeroTokenTransferAmount(operations: fa2ForXTZJson)
		XCTAssert(details2?.tokenContract == "KT1914CUZ7EegAFPbfgQMRkw8Uz5mYkEz2ui", details2?.tokenContract ?? "-")
		XCTAssert(details2?.rpcAmount == "47557742041756", details2?.rpcAmount ?? "-")
		XCTAssert(details2?.tokenId == 0, details2?.tokenId?.description ?? "-")
		XCTAssert(details2?.destination == "KT1R7WEtNNim3YgkxPt8wPMczjH3eyhbJMtz", details2?.destination ?? "-")
	}
	
	func testExtractors3RouteV4() {
		let decoder = JSONDecoder()
		
		let singleRouteJsonData = MockConstants.jsonStub(fromFilename: "3route_v4_single-route")
		let singleRouteJson = (try? decoder.decode([OperationTransaction].self, from: singleRouteJsonData)) ?? []
		XCTAssert(singleRouteJson.count > 0)
		
		let details1 = OperationFactory.Extractor.firstNonZeroTokenTransferAmount(operations: singleRouteJson)
		XCTAssert(details1?.tokenContract == "KT1ErKVqEhG9jxXgUG2KGLW3bNM7zXHX8SDF", details1?.tokenContract ?? "-")
		XCTAssert(details1?.rpcAmount == "100000000000", details1?.rpcAmount ?? "-")
		XCTAssert(details1?.tokenId == 3, details1?.tokenId?.description ?? "-")
		XCTAssert(details1?.destination == "KT1V5XKmeypanMS9pR65REpqmVejWBZURuuT", details1?.destination ?? "-")
		
		
		let multipleRouteJsonData = MockConstants.jsonStub(fromFilename: "3route_v4_multiple-routes")
		let multipleRouteJson = (try? decoder.decode([OperationTransaction].self, from: multipleRouteJsonData)) ?? []
		XCTAssert(multipleRouteJson.count > 0)
		
		let details2 = OperationFactory.Extractor.firstNonZeroTokenTransferAmount(operations: multipleRouteJson)
		XCTAssert(details2?.tokenContract == "KT1914CUZ7EegAFPbfgQMRkw8Uz5mYkEz2ui", details2?.tokenContract ?? "-")
		XCTAssert(details2?.rpcAmount == "65639920011", details2?.rpcAmount ?? "-")
		XCTAssert(details2?.tokenId == 0, details2?.tokenId?.description ?? "-")
		XCTAssert(details2?.destination == "KT1V5XKmeypanMS9pR65REpqmVejWBZURuuT", details2?.destination ?? "-")
		
		
		let fa1ForFa2Data = MockConstants.jsonStub(fromFilename: "3route_v4_fa1-for-fa2")
		let fa1ForFa2Json = (try? decoder.decode([OperationTransaction].self, from: fa1ForFa2Data)) ?? []
		XCTAssert(fa1ForFa2Json.count > 0)
		
		let details3 = OperationFactory.Extractor.firstNonZeroTokenTransferAmount(operations: fa1ForFa2Json)
		XCTAssert(details3?.tokenContract == "KT1Ha4yFVeyzw6KRAdkzq6TxDHB97KG4pZe8", details3?.tokenContract ?? "-")
		XCTAssert(details3?.rpcAmount == "400000", details3?.rpcAmount ?? "-")
		XCTAssert(details3?.tokenId == nil, details3?.tokenId?.description ?? "-")
		XCTAssert(details3?.destination == "KT1V5XKmeypanMS9pR65REpqmVejWBZURuuT", details3?.destination ?? "-")
	}
	
	func testExtractorsCrunchyStake() {
		let decoder = JSONDecoder()
		
		let jsonData = MockConstants.jsonStub(fromFilename: "crunchy-stake")
		let jsonOperations = (try? decoder.decode([OperationTransaction].self, from: jsonData)) ?? []
		XCTAssert(jsonOperations.count > 0)
		
		let details1 = OperationFactory.Extractor.firstNonZeroTokenTransferAmount(operations: jsonOperations)
		XCTAssert(details1?.tokenContract == "KT1UQVEDf4twF2eMbrCKQAxN7YYunTAiCTTm", details1?.tokenContract ?? "-")
		XCTAssert(details1?.rpcAmount == "1146068835831283", details1?.rpcAmount ?? "-")
		XCTAssert(details1?.tokenId == 0, details1?.tokenId?.description ?? "-")
		XCTAssert(details1?.destination == "KT1L1WZgdsfjEyP5T4ZCYVvN5vgzrNbu18kX", details1?.destination ?? "-")
	}
	
	func testExtractorsObjktOffer() {
		let decoder = JSONDecoder()
		
		let jsonData = MockConstants.jsonStub(fromFilename: "objkt-offer-fa1")
		let jsonOperations = (try? decoder.decode([OperationTransaction].self, from: jsonData)) ?? []
		XCTAssert(jsonOperations.count > 0)
		
		let details1 = OperationFactory.Extractor.firstNonZeroTokenTransferAmount(operations: jsonOperations)
		XCTAssert(details1?.tokenContract == "KT1LN4LPSqTMS7Sd2CJw4bbDGRkMv2t68Fy9", details1?.tokenContract ?? "-")
		XCTAssert(details1?.rpcAmount == "478000", details1?.rpcAmount ?? "-")
		XCTAssert(details1?.tokenId == nil, details1?.tokenId?.description ?? "-")
		XCTAssert(details1?.destination == "KT1Xjap1TwmDR1d8yEd8ErkraAj2mbdMrPZY", details1?.destination ?? "-")
	}
	
	func testExtractorsObjktBid() {
		let decoder = JSONDecoder()
		
		let jsonData = MockConstants.jsonStub(fromFilename: "objkt-bid")
		let jsonOperations = (try? decoder.decode([OperationTransaction].self, from: jsonData)) ?? []
		XCTAssert(jsonOperations.count > 0)
		
		let details1 = OperationFactory.Extractor.firstNonZeroTokenTransferAmount(operations: jsonOperations)
		XCTAssert(details1?.tokenContract == "KT1TjnZYs5CGLbmV6yuW169P8Pnr9BiVwwjz", details1?.tokenContract ?? "-")
		XCTAssert(details1?.rpcAmount == "201000000", details1?.rpcAmount ?? "-")
		XCTAssert(details1?.tokenId == nil, details1?.tokenId?.description ?? "-")
		XCTAssert(details1?.destination == "KT18iSHoRW1iogamADWwQSDoZa3QkN4izkqj", details1?.destination ?? "-")
	}
	
	func testExtractorsObjktBidWithWrap() {
		let decoder = JSONDecoder()
		
		let jsonData = MockConstants.jsonStub(fromFilename: "objkt-bid-with-wrap")
		let jsonOperations = (try? decoder.decode([OperationTransaction].self, from: jsonData)) ?? []
		XCTAssert(jsonOperations.count > 0)
		
		let details1 = OperationFactory.Extractor.firstNonZeroTokenTransferAmount(operations: jsonOperations)
		XCTAssert(details1?.tokenContract == "KT1TjnZYs5CGLbmV6yuW169P8Pnr9BiVwwjz", details1?.tokenContract ?? "-")
		XCTAssert(details1?.rpcAmount == "201000000", details1?.rpcAmount ?? "-")
		XCTAssert(details1?.tokenId == nil, details1?.tokenId?.description ?? "-")
		XCTAssert(details1?.destination == "KT18iSHoRW1iogamADWwQSDoZa3QkN4izkqj", details1?.destination ?? "-")
	}
	
	func testExtractorsMultiSendInListParam() {
		let decoder = JSONDecoder()
		
		let jsonData = MockConstants.jsonStub(fromFilename: "operation-factory-extractor-multiple-send-in-param")
		let jsonOperations = (try? decoder.decode([OperationTransaction].self, from: jsonData)) ?? []
		XCTAssert(jsonOperations.count > 0)
		
		let details1 = OperationFactory.Extractor.isFaTokenTransfer(operations: jsonOperations) // operation is multiple sends in a single michelson param, for now, thats not supported as a "send"
		XCTAssert(details1 == nil)
	}
}
