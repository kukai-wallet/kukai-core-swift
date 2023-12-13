//
//  File.swift
//  
//
//  Created by Simon Mcloughlin on 18/10/2021.
//

import XCTest
import Combine
@testable import KukaiCoreSwift

class TezosDomainsClientTests: XCTestCase {
	
	override func setUpWithError() throws {
	}

	override func tearDownWithError() throws {
		
	}
	
	func testGetDomain() {
		let expectation = XCTestExpectation(description: "tezos domain")
		MockConstants.shared.tezosDomainsClient.getDomainFor(address: "tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov", completion: { result in
			switch result {
				case .success(let response):
					XCTAssert(response.data?.domain() == "crane-cost.gra", "\( response.data?.domain() ?? "-" )")
					expectation.fulfill()
					
				case .failure(let error):
					XCTFail(error.description)
					expectation.fulfill()
			}
		})
		
		wait(for: [expectation], timeout: 30)
	}
	
	func testGetAddress() {
		let expectation = XCTestExpectation(description: "tezos domain")
		MockConstants.shared.tezosDomainsClient.getAddressFor(domain: "crane-cost.gra", completion: { result in
			switch result {
				case .success(let response):
					XCTAssert(response.data?.domain.address == "tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov", "\( response.data?.domain.address ?? "-" )")
					expectation.fulfill()
					
				case .failure(let error):
					XCTFail(error.description)
					expectation.fulfill()
			}
		})
		
		wait(for: [expectation], timeout: 30)
	}
	
	func testGetDomains() {
		let expectation = XCTestExpectation(description: "tezos domain")
		MockConstants.shared.tezosDomainsClient.getDomainsFor(addresses: ["tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov", "tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov"], completion: { result in
			switch result {
				case .success(let response):
					XCTAssert(response.data?.reverseRecords?.items[0].domain.name == "crane-cost.gra", "\( response.data?.reverseRecords?.items[0].domain.name ?? "-" )")
					expectation.fulfill()
					
				case .failure(let error):
					XCTFail(error.description)
					expectation.fulfill()
			}
		})
		
		wait(for: [expectation], timeout: 30)
	}
	
	func testGetAddresses() {
		let expectation = XCTestExpectation(description: "tezos domain")
		MockConstants.shared.tezosDomainsClient.getAddressesFor(domains: ["crane-cost.gra", "crane-cost.gra", "crane-cost.gra"], completion: { result in
			switch result {
				case .success(let response):
					XCTAssert(response.data?.domains?.items[0].address == "tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov", "\( response.data?.domains?.items[0].address ?? "-" )")
					expectation.fulfill()
					
				case .failure(let error):
					XCTFail(error.description)
					expectation.fulfill()
			}
		})
		
		wait(for: [expectation], timeout: 30)
	}
	
	func testGetBoth() {
		let expectation = XCTestExpectation(description: "tezos domain")
		MockConstants.shared.tezosDomainsClient.getMainAndGhostDomainFor(address: "tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov") { result in
			switch result {
				case .success(let response):
					XCTAssert(response.mainnet?.domain.name == "crane-cost.tez", response.mainnet?.domain.name ?? "-")
					XCTAssert(response.ghostnet?.domain.name == "crane-cost.gra", response.ghostnet?.domain.name ?? "-")
					expectation.fulfill()
					
				case .failure(let error):
					XCTFail(error.description)
					expectation.fulfill()
			}
		}
		
		wait(for: [expectation], timeout: 30)
	}
	
	func testGetBothBulk() {
		let expectation = XCTestExpectation(description: "tezos domain")
		MockConstants.shared.tezosDomainsClient.getMainAndGhostDomainsFor(addresses: ["tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov", "tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov"]) { result in
			switch result {
				case .success(let response):
					XCTAssert(response["tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov"]?.mainnet?.domain.name == "crane-cost.tez", response["tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov"]?.mainnet?.domain.name ?? "-")
					XCTAssert(response["tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov"]?.ghostnet?.domain.name == "crane-cost.gra", response["tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov"]?.ghostnet?.domain.name ?? "-")
					expectation.fulfill()
					
				case .failure(let error):
					XCTFail(error.description)
					expectation.fulfill()
			}
		}
		
		wait(for: [expectation], timeout: 30)
	}
}
