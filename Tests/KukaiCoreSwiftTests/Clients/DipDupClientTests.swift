//
//  DipDupClientTests.swift
//  
//
//  Created by Simon Mcloughlin on 30/11/2021.
//

import XCTest
@testable import KukaiCoreSwift

class DipDupClientTests: XCTestCase {
	
	func testGetExchanges() {
		let expectation = XCTestExpectation(description: "dipdup-get-exchanges")
		
		MockConstants.shared.dipDupClient.getAllExchangesAndTokens { result in
			guard let res = try? result.get() else {
				XCTFail(result.getFailure().errorString ?? "")
				expectation.fulfill()
				return
			}
			
			XCTAssert(res.count == 340, "\(res.count)")
			
			XCTAssert(res.first?.symbol == "tzBTC", res.first?.symbol ?? "-")
			XCTAssert(res.first?.exchanges.first?.address == "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", res.first?.exchanges.first?.address ?? "-")
			XCTAssert(res.first?.exchanges.first?.token.address == "KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn", res.first?.exchanges.first?.token.address ?? "-")
			XCTAssert(res.first?.exchanges.first?.xtzPoolAmount().normalisedRepresentation == "1821302.868928", res.first?.exchanges.first?.xtzPoolAmount().normalisedRepresentation ?? "-")
			XCTAssert(res.first?.exchanges.first?.tokenPoolAmount().normalisedRepresentation == "175.53860825", res.first?.exchanges.first?.tokenPoolAmount().normalisedRepresentation ?? "-")
			XCTAssert(res.first?.exchanges.first?.totalLiquidity().normalisedRepresentation == "171068922", res.first?.exchanges.first?.totalLiquidity().normalisedRepresentation ?? "-")
			
			XCTAssert(res.last?.symbol == "T42", res.last?.symbol ?? "-")
			XCTAssert(res.last?.exchanges.first?.address == "KT1M5H8qkJEzhdC3ZxZ78bSxgmcddrcusbry", res.last?.exchanges.first?.address ?? "-")
			XCTAssert(res.last?.exchanges.first?.token.address == "KT1EpihM8tQSBwqYB6NtCT8N67pq8rKwoD93", res.last?.exchanges.first?.token.address ?? "-")
			XCTAssert(res.last?.exchanges.first?.xtzPoolAmount().normalisedRepresentation == "0", res.last?.exchanges.first?.xtzPoolAmount().normalisedRepresentation ?? "-")
			XCTAssert(res.last?.exchanges.first?.tokenPoolAmount().normalisedRepresentation == "0", res.last?.exchanges.first?.tokenPoolAmount().normalisedRepresentation ?? "-")
			XCTAssert(res.last?.exchanges.first?.totalLiquidity().normalisedRepresentation == "0", res.last?.exchanges.first?.totalLiquidity().normalisedRepresentation ?? "-")
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
	
	func testGetLiquidity() {
		let expectation = XCTestExpectation(description: "dipdup-get-liquidity")
		
		MockConstants.shared.dipDupClient.getLiquidityFor(address: "tz1QoUmcycUDaFGvuju2bmTSaCqQCMEpRcgs") { result in
			guard let res = try? result.get() else {
				XCTFail(result.getFailure().errorString ?? "")
				expectation.fulfill()
				return
			}
			
			XCTAssert(res.data?.position.count == 2, "\(res.data?.position.count ?? 0)")
			
			XCTAssert(res.data?.position.first?.sharesQty == "91", res.data?.position.first?.sharesQty ?? "-")
			XCTAssert(res.data?.position.first?.tokenAmount().normalisedRepresentation == "91", res.data?.position.first?.tokenAmount().normalisedRepresentation ?? "-")
			XCTAssert(res.data?.position.first?.exchange.name.rawValue == "lb", res.data?.position.first?.exchange.name.rawValue ?? "-")
			
			XCTAssert(res.data?.position.last?.sharesQty == "804488", res.data?.position.last?.sharesQty ?? "-")
			XCTAssert(res.data?.position.last?.tokenAmount().normalisedRepresentation == "0.804488", res.data?.position.last?.tokenAmount().normalisedRepresentation ?? "-")
			XCTAssert(res.data?.position.last?.exchange.name.rawValue == "quipuswap", res.data?.position.last?.exchange.name.rawValue ?? "-")
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
}
