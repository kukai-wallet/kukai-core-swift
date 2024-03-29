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
	
	func testAllowance() {
		let address = MockConstants.defaultHdWallet.address
		let op = OperationFactory.allowanceOperation(standard: .fa12, tokenAddress: MockConstants.token3Decimals.tokenContractAddress ?? "", spenderAddress: address, allowance: MockConstants.token3Decimals_1, walletAddress: address)
		XCTAssert(op.source == MockConstants.defaultHdWallet.address)
		XCTAssert(op.counter == "0")
		XCTAssert(op.operationKind == .transaction)
		XCTAssert(op is OperationTransaction)
		
		let op2 = OperationFactory.allowanceOperation(standard: .fa2, tokenAddress: MockConstants.token3Decimals.tokenContractAddress ?? "", spenderAddress: address, allowance: MockConstants.token3Decimals_1, walletAddress: address)
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
		let token = DipDupToken(symbol: "TEST", address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tokenId: 0, decimals: 0, standard: .fa12)
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
	
	func testRemoveLiquidity() {
		let address = MockConstants.defaultHdWallet.address
		let token = DipDupToken(symbol: "TEST", address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", tokenId: 0, decimals: 0, standard: .fa12)
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
		let results1 = OperationFactory.Extractor.faTokenDetailsFrom(operations: xtzOp)
		XCTAssert(results1 == nil)
		
		let isTezTransfer1 = OperationFactory.Extractor.isTezTransfer(operations: xtzOp)
		XCTAssert(isTezTransfer1)
		
		
		
		let opFA1 = OperationFactory.sendOperation(MockConstants.token3Decimals_1, of: MockConstants.token3Decimals, from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
		let results2 = OperationFactory.Extractor.faTokenDetailsFrom(operations: opFA1)
		XCTAssert(results2 != nil)
		XCTAssert(results2?.tokenContract == "KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8", results2?.tokenContract ?? "-")
		XCTAssert(results2?.rpcAmount == "1000", results2?.rpcAmount ?? "-")
		XCTAssert(results2?.tokenId == nil, results2?.tokenId?.description ?? "-")
		
		let isTezTransfer2 = OperationFactory.Extractor.isTezTransfer(operations: opFA1)
		XCTAssert(!isTezTransfer2)
		
		let firstTrasnfer1 = OperationFactory.Extractor.firstTransferEntrypointOperation(operations: opFA1)
		XCTAssert(firstTrasnfer1?.destination == "KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8", firstTrasnfer1?.destination ?? "-")
		
		
		
		let opFA2 = OperationFactory.sendOperation(MockConstants.token10Decimals_1, of: MockConstants.token10Decimals, from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
		let results3 = OperationFactory.Extractor.faTokenDetailsFrom(operations: opFA2)
		XCTAssert(results3 != nil)
		XCTAssert(results3?.tokenContract == "KT1G1cCRNBgQ48mVDjopHjEmTN5Sbtar8nn9", results3?.tokenContract ?? "-")
		XCTAssert(results3?.rpcAmount == "10000000000", results3?.rpcAmount ?? "-")
		XCTAssert(results3?.tokenId == 0, results3?.tokenId?.description ?? "-")
		
		let isTezTransfer3 = OperationFactory.Extractor.isTezTransfer(operations: opFA2)
		XCTAssert(!isTezTransfer3)
		
		let firstTrasnfer2 = OperationFactory.Extractor.firstTransferEntrypointOperation(operations: opFA2)
		XCTAssert(firstTrasnfer2?.destination == "KT1G1cCRNBgQ48mVDjopHjEmTN5Sbtar8nn9", firstTrasnfer2?.destination ?? "-")
		
		
		
		let opNFT = OperationFactory.sendOperation(1, ofNft: (MockConstants.tokenWithNFTs.nfts ?? [])[0], from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
		let results4 = OperationFactory.Extractor.faTokenDetailsFrom(operations: opNFT)
		XCTAssert(results4 != nil)
		XCTAssert(results4?.tokenContract == "KT1G1cCRNBgQ48mVDjopHjEmTN5Sbtabc123", results4?.tokenContract ?? "-")
		XCTAssert(results4?.rpcAmount == "1", results4?.rpcAmount ?? "-")
		XCTAssert(results4?.tokenId == 4, results4?.tokenId?.description ?? "-")
		
		
		
		let dexToken = DipDupToken(symbol: "BLAH", address: "KT1def", tokenId: 123, decimals: 3, standard: .fa2)
		let dex = DipDupExchange(name: .quipuswap, address: "KT1abc", tezPool: "100000000000", tokenPool: "1000000000", sharesTotal: "100000", midPrice: "14", token: dexToken)
		let swap = OperationFactory.swapXtzToToken(withDex: dex, xtzAmount: .init(fromNormalisedAmount: 14), minTokenAmount: .init(fromNormalisedAmount: 2, decimalPlaces: 3), walletAddress: "tz1abc", timeout: 60)
		
		let isContract = OperationFactory.Extractor.isContractCall(operations: swap)
		XCTAssert(isContract?.entrypoint == "tezToTokenPayment", isContract?.entrypoint ?? "-")
		XCTAssert(isContract?.address == "KT1abc", isContract?.address ?? "-")
		
		let firstContractOp = OperationFactory.Extractor.firstContractCallOperation(operations: swap)
		XCTAssert(firstContractOp?.destination == "KT1abc", firstContractOp?.destination ?? "-")
		
		
		var xtzOpsCopy = xtzOp
		xtzOpsCopy.append(contentsOf: xtzOp)
		
		let totalXTZ = OperationFactory.Extractor.totalXTZAmountForContractCall(operations: xtzOpsCopy)
		XCTAssert(totalXTZ.description == "2", totalXTZ.description)
		
	}
}
