//
//  TaquitoServiceTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 16/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class TaquitoServiceTests: XCTestCase {
	
	let ops1 = OperationFactory.sendOperation(MockConstants.xtz_1, of: MockConstants.tokenXTZ, from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
	var payload1: OperationPayload? = nil
	let forge1 = "43f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6c0062bccf15da24b56e97df655ff36a5ec62664da1600ffde080000c0843d0000f9cb7bd478ea1792ff0ae15e921d698c2c270e8200"
	
	let ops2 = OperationFactory.sendOperation(MockConstants.token3Decimals_1, of: MockConstants.token3Decimals, from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
	var payload2: OperationPayload? = nil
	let forge2 = "43f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6c0062bccf15da24b56e97df655ff36a5ec62664da1600ffde08000000010afd989cd30ff193f614d7e47748f46c10889ec100ffff087472616e736665720000005907070100000024747a3155653736624c5737626f41634a455a66326b534763616d64424b5669344b70737307070100000024747a316951706942544b747a666256676f676a7968506947727256357a414b554b4e767900a80f"
	
	let ops3 = OperationFactory.delegateOperation(to: MockConstants.defaultLinearWallet.address, from: MockConstants.defaultHdWallet.address)
	var payload3: OperationPayload? = nil
	let forge3 = "43f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6e0062bccf15da24b56e97df655ff36a5ec62664da1600ffde080000ff00f9cb7bd478ea1792ff0ae15e921d698c2c270e82"
	
	
	
	override func setUpWithError() throws {
		payload1 = OperationFactory.operationPayload(fromMetadata: MockConstants.operationMetadata, andOperations: ops1, walletAddress: MockConstants.defaultLinearWallet.address, base58EncodedPublicKey: MockConstants.defaultLinearWallet.publicKeyBase58encoded())
		payload2 = OperationFactory.operationPayload(fromMetadata: MockConstants.operationMetadata, andOperations: ops2, walletAddress: MockConstants.defaultLinearWallet.address, base58EncodedPublicKey: MockConstants.defaultLinearWallet.publicKeyBase58encoded())
		payload3 = OperationFactory.operationPayload(fromMetadata: MockConstants.operationMetadata, andOperations: ops3, walletAddress: MockConstants.defaultLinearWallet.address, base58EncodedPublicKey: MockConstants.defaultLinearWallet.publicKeyBase58encoded())
	}

	override func tearDownWithError() throws {
	}
	
	
	func testForge1() {
		guard let payload = payload1 else {
			XCTFail()
			return
		}
		
		let expectation = XCTestExpectation(description: "Forge payload 1")
		TaquitoService.shared.forge(operationPayload: payload) { [weak self] forgeResult in
			
			switch forgeResult {
				case .success(let forgedString):
					XCTAssert(forgedString == self?.forge1, forgedString)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 30)
	}
	
	func testForge2() {
		guard let payload = payload2 else {
			XCTFail()
			return
		}
		
		let expectation = XCTestExpectation(description: "Forge payload 2")
		TaquitoService.shared.forge(operationPayload: payload) { [weak self] forgeResult in
			
			switch forgeResult {
				case .success(let forgedString):
					XCTAssert(forgedString == self?.forge2, forgedString)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 30)
	}
	
	func testForge3() {
		guard let payload = payload3 else {
			XCTFail()
			return
		}
		
		let expectation = XCTestExpectation(description: "Forge payload 3")
		TaquitoService.shared.forge(operationPayload: payload) { [weak self] forgeResult in
			
			switch forgeResult {
				case .success(let forgedString):
					XCTAssert(forgedString == self?.forge3, forgedString)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 30)
	}
	
	func testForgeError() {
		let errorMetaData = OperationMetadata(managerKey: nil, counter: 1, blockchainHead: BlockchainHead(protocol: "blah", chainID: "blah", hash: "blah"))
		let address = MockConstants.defaultLinearWallet.address
		let key = MockConstants.defaultLinearWallet.publicKeyBase58encoded()
		let payload = OperationFactory.operationPayload(fromMetadata: errorMetaData, andOperations: [], walletAddress: address, base58EncodedPublicKey: key)
		
		let expectation = XCTestExpectation(description: "Forge payload Error")
		TaquitoService.shared.forge(operationPayload: payload) { forgeResult in
			
			switch forgeResult {
				case .success(_):
					XCTFail()
					
				case .failure(let error):
					XCTAssert(error.description == "Unknown: InvalidBlockHashError: Invalid block hash \"blah\" with unsupported prefix.", error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 30)
	}
	
	func testParse1() {
		let expectation = XCTestExpectation(description: "Parse payload 1")
		TaquitoService.shared.parse(hex: forge1) { [weak self] parseResult in
			switch parseResult {
				case .success(let operationPayload):
					XCTAssert(operationPayload == self?.payload1)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 30)
	}
	
	func testParse2() {
		let expectation = XCTestExpectation(description: "Parse payload 2")
		TaquitoService.shared.parse(hex: forge2) { [weak self] parseResult in
			switch parseResult {
				case .success(let operationPayload):
					XCTAssert(operationPayload == self?.payload2)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 30)
	}
	
	func testParse3() {
		let expectation = XCTestExpectation(description: "Parse payload 3")
		TaquitoService.shared.parse(hex: forge3) { [weak self] parseResult in
			switch parseResult {
				case .success(let operationPayload):
					XCTAssert(operationPayload == self?.payload3)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 30)
	}
}
