//
//  Base58Tests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
import WalletCore
@testable import KukaiCoreSwift

class Base58Tests: XCTestCase {

    override func setUpWithError() throws {
		
    }

    override func tearDownWithError() throws {
		
    }
	
	func testBase58() {
		let message = "Hello, world"
		
		let encode1 = Base58.encode(message: message.bytes, ellipticalCurve: .ed25519)
		let encode2 = Base58.encode(message: message.bytes, ellipticalCurve: .secp256k1)
		
		XCTAssert(encode1 == "cXLWC7FJBFHpLE1fBnCfp8rS3ZQE", encode1)
		XCTAssert(encode2 == "pyPk1M8wj4imXzsW3ue7Er18XGZn", encode2)
		
		
		let decode1 = Base58.decode(string: encode1, prefix: Prefix.Keys.Ed25519.signature)
		let decode2 = Base58.decode(string: encode2, prefix: Prefix.Keys.Secp256k1.signature)
		
		XCTAssert(decode1 == message.bytes, "\(decode1 ?? [0])")
		XCTAssert(decode2 == message.bytes, "\(decode2 ?? [0])")
	}
}
