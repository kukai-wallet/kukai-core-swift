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
				XCTFail(result.getFailure().description)
				expectation.fulfill()
				return
			}
			
			XCTAssert(res.count == 399, "\(res.count)")
			
			XCTAssert(res.first?.symbol == "tzBTC", res.first?.symbol ?? "-")
			XCTAssert(res.first?.exchanges.first?.address == "KT1WBLrLE2vG8SedBqiSJFm4VVAZZBytJYHc", res.first?.exchanges.first?.address ?? "-")
			XCTAssert(res.first?.exchanges.first?.token.address == "KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn", res.first?.exchanges.first?.token.address ?? "-")
			XCTAssert(res.first?.exchanges.first?.xtzPoolAmount().normalisedRepresentation == "9469.130217", res.first?.exchanges.first?.xtzPoolAmount().normalisedRepresentation ?? "-")
			XCTAssert(res.first?.exchanges.first?.tokenPoolAmount().normalisedRepresentation == "0.22247765", res.first?.exchanges.first?.tokenPoolAmount().normalisedRepresentation ?? "-")
			XCTAssert(res.first?.exchanges.first?.totalLiquidity().normalisedRepresentation == "3573.048455", res.first?.exchanges.first?.totalLiquidity().normalisedRepresentation ?? "-")
			
			XCTAssert(res.last?.symbol == "LINK.e", res.last?.symbol ?? "-")
			XCTAssert(res.last?.exchanges.first?.address == "KT193vJRsjM9qJA7PVD7LzJhyKTWPvdq5RGd", res.last?.exchanges.first?.address ?? "-")
			XCTAssert(res.last?.exchanges.first?.token.address == "KT1UsSfaXyqcjSVPeiD7U1bWgKy3taYN7NWY", res.last?.exchanges.first?.token.address ?? "-")
			XCTAssert(res.last?.exchanges.first?.xtzPoolAmount().normalisedRepresentation == "0", res.last?.exchanges.first?.xtzPoolAmount().normalisedRepresentation ?? "-")
			XCTAssert(res.last?.exchanges.first?.tokenPoolAmount().normalisedRepresentation == "0", res.last?.exchanges.first?.tokenPoolAmount().normalisedRepresentation ?? "-")
			XCTAssert(res.last?.exchanges.first?.totalLiquidity().normalisedRepresentation == "0", res.last?.exchanges.first?.totalLiquidity().normalisedRepresentation ?? "-")
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testGetLiquidity() {
		let expectation = XCTestExpectation(description: "dipdup-get-liquidity")
		
		MockConstants.shared.dipDupClient.getLiquidityFor(address: "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss") { result in
			guard let res = try? result.get() else {
				XCTFail(result.getFailure().description)
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
		
		wait(for: [expectation], timeout: 120)
	}
	
	/*
	func testChartData() {
		let expectation = XCTestExpectation(description: "dipdup-get-chart")
		
		MockConstants.shared.dipDupClient.getChartDataFor(exchangeContract: "KT1WBLrLE2vG8SedBqiSJFm4VVAZZBytJYHc", nowDate: Date(timeIntervalSince1970: 1695135)) { result in
			guard let res = try? result.get() else {
				XCTFail(result.getFailure().description)
				expectation.fulfill()
				return
			}
			
			XCTAssert(res.data?.quotes15mNogaps.count == 6, "\(res.data?.quotes15mNogaps.count ?? -1)")
			XCTAssert(res.data?.quotes15mNogaps[0].average == 12608.237, "\(res.data?.quotes15mNogaps[0].average ?? 0)")
			XCTAssert(res.data?.quotes15mNogaps[0].averageDouble() == 12608.237, "\(res.data?.quotes15mNogaps[0].average ?? 0)")
			XCTAssert(res.data?.quotes15mNogaps[0].bucket == "2022-03-04T03:30:00+00:00", "\(res.data?.quotes15mNogaps[0].bucket ?? "-")")
			XCTAssert(res.data?.quotes15mNogaps[0].high == "12608.23692735", res.data?.quotes15mNogaps[0].high ?? "-")
			XCTAssert(res.data?.quotes15mNogaps[0].low == "12608.23692735", res.data?.quotes15mNogaps[0].low ?? "-")
			XCTAssert(res.data?.quotes15mNogaps[0].date() == Date(timeIntervalSince1970: 1646364600.0), "\(res.data?.quotes15mNogaps[0].date()?.timeIntervalSince1970 ?? 0)")
			XCTAssert(res.data?.quotes15mNogaps[0].highDouble().description == "12608.23692735", res.data?.quotes15mNogaps[0].highDouble().description ?? "-")
			XCTAssert(res.data?.quotes15mNogaps[0].lowDouble().description == "12608.23692735", res.data?.quotes15mNogaps[0].lowDouble().description ?? "-")
			
			XCTAssert(res.data?.quotes1hNogaps.count == 5, "\(res.data?.quotes1hNogaps.count ?? -1)")
			XCTAssert(res.data?.quotes1dNogaps.count == 3, "\(res.data?.quotes1dNogaps.count ?? -1)")
			XCTAssert(res.data?.quotes1wNogaps.count == 2, "\(res.data?.quotes1wNogaps.count ?? -1)")
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	*/
}
