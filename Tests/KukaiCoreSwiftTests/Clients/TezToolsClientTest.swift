//
//  TezToolsClientTests.swift
//  
//
//  Created by Simon Mcloughlin on 30/11/2021.
//

import XCTest
@testable import KukaiCoreSwift

class TezToolsClientTests: XCTestCase {
	
	func testFetchTokens() {
		let expectation = XCTestExpectation(description: "teztools-fetch-tokens")
		
		MockConstants.shared.tezToolsClient.fetchTokens { result in
			guard let res = try? result.get() else {
				XCTFail(result.getFailure().errorString ?? "")
				expectation.fulfill()
				return
			}
			
			XCTAssert(res.count == 314, "\(res.count)")
			
			XCTAssert(res.first?.token.address == "KT1W3VGRUjvS869r4ror8kdaxqJAZUbPyjMT", res.first?.token.address ?? "-")
			XCTAssert(res.first?.token.symbol == "wXTZ", res.first?.token.symbol ?? "-")
			XCTAssert(res.first?.token.apps.first?.name.rawValue == "QUIPUSWAP", res.first?.token.apps.first?.name.rawValue ?? "-")
			XCTAssert(res.first?.price.address == "KT1W3VGRUjvS869r4ror8kdaxqJAZUbPyjMT", res.first?.price.address ?? "-")
			XCTAssert(res.first?.price.symbol == "wXTZ", res.first?.price.symbol ?? "-")
			XCTAssert(res.first?.price.pairs.first?.nonBaseTokenSide()?.symbol == "wXTZ", res.first?.price.pairs.first?.nonBaseTokenSide()?.symbol ?? "-")
			XCTAssert(res.first?.price.pairs.first?.nonBaseTokenSide()?.price.rounded(scale: 5, roundingMode: .down).description == "0.77335", res.first?.price.pairs.first?.nonBaseTokenSide()?.price.description ?? "-")
			
			XCTAssert(res.last?.token.address == "KT1JitjBtBsjjQrMGyA57ScjHSP6JF5zE7eS", res.last?.token.address ?? "-")
			XCTAssert(res.last?.token.symbol == "tzMeta", res.last?.token.symbol ?? "-")
			XCTAssert(res.last?.token.apps.first?.name.rawValue == "QUIPUSWAP", res.last?.token.apps.first?.name.rawValue ?? "-")
			XCTAssert(res.last?.price.address == "KT1JitjBtBsjjQrMGyA57ScjHSP6JF5zE7eS", res.last?.price.address ?? "-")
			XCTAssert(res.last?.price.symbol == "tzMeta", res.last?.price.symbol ?? "-")
			XCTAssert(res.last?.price.pairs.first?.nonBaseTokenSide()?.symbol == "tzMeta", res.last?.price.pairs.first?.nonBaseTokenSide()?.symbol ?? "-")
			XCTAssert(res.last?.price.pairs.first?.nonBaseTokenSide()?.price.rounded(scale: 10, roundingMode: .down).description == "0.0000000024", res.last?.price.pairs.first?.nonBaseTokenSide()?.price.description ?? "-")
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
}
