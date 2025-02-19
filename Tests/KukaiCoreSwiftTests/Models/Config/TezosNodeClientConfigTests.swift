//
//  TezosNodeClientConfigTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class TezosNodeClientConfigTests: XCTestCase {

    override func setUpWithError() throws {
		
    }

    override func tearDownWithError() throws {
		
    }
	
	func testDefaults() {
		let config1 = TezosNodeClientConfig(withDefaultsForNetworkType: .ghostnet)
		XCTAssert(config1.nodeURLs[0].absoluteString == "https://ghostnet.smartpy.io", config1.nodeURLs[0].absoluteString)
		XCTAssert(config1.nodeURLs[1].absoluteString == "https://rpc.ghostnet.tzboot.net", config1.nodeURLs[1].absoluteString)
		XCTAssert(config1.tzktURL.absoluteString == "https://api.ghostnet.tzkt.io/", config1.tzktURL.absoluteString)
		XCTAssert(config1.forgingType == .local, "\(config1.forgingType)")
		
		let config2 = TezosNodeClientConfig(withDefaultsForNetworkType: .mainnet)
		XCTAssert(config2.nodeURLs[0].absoluteString == "https://mainnet.smartpy.io", config2.nodeURLs[0].absoluteString)
		XCTAssert(config2.nodeURLs[1].absoluteString == "https://rpc.tzbeta.net", config2.nodeURLs[1].absoluteString)
		XCTAssert(config2.tzktURL.absoluteString == "https://api.tzkt.io/", config2.tzktURL.absoluteString)
		XCTAssert(config2.forgingType == .local, "\(config2.forgingType)")
	}
}
