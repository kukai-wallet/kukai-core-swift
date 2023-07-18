//
//  RPCTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class RPCTests: XCTestCase {

    override func setUpWithError() throws {
		
    }

    override func tearDownWithError() throws {
		
    }
	
	func testRPC() {
		let rpcBalance = RPC.xtzBalance(forAddress: MockConstants.defaultHdWallet.address)
		XCTAssert(rpcBalance.endpoint == "chains/main/blocks/head/context/contracts/tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss/balance", rpcBalance.endpoint)
		XCTAssert(rpcBalance.isPost == false)
		XCTAssert(rpcBalance.payload == nil)
		XCTAssert(rpcBalance.responseType == String.self)
		
		let rpcForge = RPC.forge(operationPayload: MockConstants.sendOperationPayload)
		XCTAssert(rpcForge?.endpoint == "chains/main/blocks/head/helpers/forge/operations", rpcForge?.endpoint ?? "-")
		XCTAssert(rpcForge?.isPost == true)
		XCTAssert(rpcForge?.responseType == String.self)
		
		if let subStr = rpcForge?.payload?.toHexString().prefix(50) {
			XCTAssert(String(subStr) == "7b22636f6e74656e7473223a5b7b22616d6f756e74223a2231", String(subStr))
		} else {
			XCTFail("Can't get substring")
		}
	}
}
