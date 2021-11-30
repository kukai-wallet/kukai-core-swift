//
//  DAppHelperServiceTests.swift
//  
//
//  Created by Simon Mcloughlin on 30/11/2021.
//

import XCTest
@testable import KukaiCoreSwift

class DAppHelperServiceTests: XCTestCase {
	
	func testPendingRewards() {
		let expectation = XCTestExpectation(description: "dAppHelper-pending-rewards")
		
		DAppHelperService.Quipuswap.getPendingRewards(fromExchange: "KT1WBLrLE2vG8SedBqiSJFm4VVAZZBytJYHc", forAddress: "tz1QoUmcycUDaFGvuju2bmTSaCqQCMEpRcgs", tzKTClient: MockConstants.shared.tzktClient) { result in
			guard let res = try? result.get() else {
				XCTFail(result.getFailure().errorString ?? "")
				expectation.fulfill()
				return
			}
			
			XCTAssert(res > XTZAmount.zero(), res.normalisedRepresentation)
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
	
	func testPendingRewardsBulk() {
		let expectation = XCTestExpectation(description: "dAppHelper-pending-rewards-bulk")
		
		DAppHelperService.Quipuswap.getBulkPendingRewards(fromExchanges: ["KT1WBLrLE2vG8SedBqiSJFm4VVAZZBytJYHc", "KT1WBLrLE2vG8SedBqiSJFm4VVAZZBytJYHc"],
														  forAddress: "tz1QoUmcycUDaFGvuju2bmTSaCqQCMEpRcgs",
														  tzKTClient: MockConstants.shared.tzktClient) { result in
			guard let res = try? result.get() else {
				XCTFail(result.getFailure().errorString ?? "")
				expectation.fulfill()
				return
			}
			
			XCTAssert(res.first?.rewards ?? .zero() > XTZAmount.zero(), res.first?.rewards.normalisedRepresentation ?? "-")
			XCTAssert(res.last?.rewards ?? .zero() > XTZAmount.zero(), res.last?.rewards.normalisedRepresentation ?? "-")
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
}
