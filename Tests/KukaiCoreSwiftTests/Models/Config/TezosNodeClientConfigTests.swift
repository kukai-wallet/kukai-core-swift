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
		let config1 = TezosNodeClientConfig(withDefaultsForNetworkType: .testnet)
		XCTAssert(config1.primaryNodeURL.absoluteString == "https://api.tez.ie/rpc/granadanet", config1.primaryNodeURL.absoluteString)
		XCTAssert(config1.parseNodeURL?.absoluteString == "https://tezos-prod.cryptonomic-infra.tech:443/", config1.parseNodeURL?.absoluteString ?? "")
		XCTAssert(config1.betterCallDevURL.absoluteString == "https://api.better-call.dev/", config1.betterCallDevURL.absoluteString)
		XCTAssert(config1.tzktURL.absoluteString == "https://api.granadanet.tzkt.io/", config1.tzktURL.absoluteString)
		XCTAssert(config1.forgingType == .local, "\(config1.forgingType)")
		
		let config2 = TezosNodeClientConfig(withDefaultsForNetworkType: .mainnet)
		XCTAssert(config2.primaryNodeURL.absoluteString == "https://mainnet-tezos.giganode.io/", config2.primaryNodeURL.absoluteString)
		XCTAssert(config2.parseNodeURL?.absoluteString == "https://tezos-prod.cryptonomic-infra.tech:443/", config2.parseNodeURL?.absoluteString ?? "")
		XCTAssert(config2.betterCallDevURL.absoluteString == "https://api.better-call.dev/", config2.betterCallDevURL.absoluteString)
		XCTAssert(config2.tzktURL.absoluteString == "https://api.tzkt.io/", config2.tzktURL.absoluteString)
		XCTAssert(config2.forgingType == .local, "\(config2.forgingType)")
	}
}
