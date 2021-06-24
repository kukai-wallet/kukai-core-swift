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
		XCTAssert(rpcBalance.endpoint == "chains/main/blocks/head/context/contracts/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/balance", rpcBalance.endpoint)
		XCTAssert(rpcBalance.isPost == false)
		XCTAssert(rpcBalance.payload == nil)
		XCTAssert(rpcBalance.responseType == String.self)
		
		let rpcForge = RPC.forge(operationPayload: MockConstants.sendOperationPayload, withMetadata: MockConstants.operationMetadata)
		XCTAssert(rpcForge?.endpoint == "chains/main/blocks/BLEDGNuADAwZfKK7iZ6PHnu7gZFSXuRPVFXe2PhSnb6aMyKn3mK/helpers/forge/operations", rpcForge?.endpoint ?? "-")
		XCTAssert(rpcForge?.isPost == true)
		XCTAssert(rpcForge?.payload?.toHexString() == "7b22636f6e74656e7473223a5b7b22616d6f756e74223a2231303030303030222c2264657374696e6174696f6e223a22747a315433515a3577344b31315253337679345458695a6570726156395235477a737847222c22736f75726365223a22747a3162516e5542367776373741416e76766b58357258777a4b486973365278566e7946222c2273746f726167655f6c696d6974223a22323537222c226761735f6c696d6974223a223130353030222c22666565223a2231343130222c226b696e64223a227472616e73616374696f6e222c22636f756e746572223a22313433323331227d5d2c226272616e6368223a22424c4544474e75414441775a664b4b37695a3650486e7537675a46535875525056465865325068536e6236614d794b6e336d4b227d", rpcForge?.payload?.toHexString() ?? "-")
		XCTAssert(rpcForge?.responseType == String.self)
	}
}
