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
	let forge1 = "43f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6c00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d00ffde080000c0843d00005134b25890279835eb946e6369a3d719bc0d617700"
	
	let ops2 = OperationFactory.sendOperation(MockConstants.token3Decimals_1, of: MockConstants.token3Decimals, from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
	var payload2: OperationPayload? = nil
	let forge2 = "43f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6c00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d00ffde08000000010afd989cd30ff193f614d7e47748f46c10889ec100ffff087472616e736665720000005907070100000024747a3162516e5542367776373741416e76766b58357258777a4b486973365278566e794607070100000024747a315433515a3577344b31315253337679345458695a6570726156395235477a73784700a80f"
	
	let ops3 = OperationFactory.delegateOperation(to: MockConstants.defaultLinearWallet.address, from: MockConstants.defaultHdWallet.address)
	var payload3: OperationPayload? = nil
	let forge3 = "43f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6e00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d00ffde080000ff005134b25890279835eb946e6369a3d719bc0d6177"
	
	
	
	override func setUpWithError() throws {
		payload1 =  OperationFactory.operationPayload(fromMetadata: MockConstants.operationMetadata, andOperations: ops1, withWallet: MockConstants.defaultLinearWallet)
		payload2 =  OperationFactory.operationPayload(fromMetadata: MockConstants.operationMetadata, andOperations: ops2, withWallet: MockConstants.defaultLinearWallet)
		payload3 =  OperationFactory.operationPayload(fromMetadata: MockConstants.operationMetadata, andOperations: ops3, withWallet: MockConstants.defaultLinearWallet)
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
		
		wait(for: [expectation], timeout: 3)
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
		
		wait(for: [expectation], timeout: 3)
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
		
		wait(for: [expectation], timeout: 3)
	}
	
	func testForgeError() {
		let errorMetaData = OperationMetadata(managerKey: nil, counter: 1, blockchainHead: BlockchainHead(protocol: "blah", chainID: "blah", hash: "blah"))
		let payload = OperationFactory.operationPayload(fromMetadata: errorMetaData, andOperations: [], withWallet: MockConstants.defaultLinearWallet)
		
		let expectation = XCTestExpectation(description: "Forge payload Error")
		TaquitoService.shared.forge(operationPayload: payload) { forgeResult in
			
			switch forgeResult {
				case .success(_):
					XCTFail()
					
				case .failure(let error):
					XCTAssert(error.description.contains("Non-base58 character"))
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
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
		
		wait(for: [expectation], timeout: 3)
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
		
		wait(for: [expectation], timeout: 3)
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
		
		wait(for: [expectation], timeout: 3)
	}
}
