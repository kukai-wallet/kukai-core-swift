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
	
	private var bag = Set<AnyCancellable>()
	
	override func setUpWithError() throws {
	}

	override func tearDownWithError() throws {
		
	}
	
	func testGetDomain() {
		let expectation = XCTestExpectation(description: "tezos domain")
		MockConstants.shared.tezosDomainsClient.getDomainFor(address: "tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov")
			.sink { error in
				XCTFail(error.description)
				expectation.fulfill()
				
			} onSuccess: { response in
				XCTAssert(response.data?.domain() == "crane-cost.gra", "\( response.data?.domain() ?? "-" )")
				expectation.fulfill()
			}
			.store(in: &bag)
		
		wait(for: [expectation], timeout: 3)
	}
	
	func testGetAddress() {
		let expectation = XCTestExpectation(description: "tezos domain")
		MockConstants.shared.tezosDomainsClient.getAddressFor(domain: "crane-cost.gra")
			.sink { error in
				XCTFail(error.description)
				expectation.fulfill()
				
			} onSuccess: { response in
				XCTAssert(response.data?.domain.address == "tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov", "\( response.data?.domain.address ?? "-" )")
				expectation.fulfill()
			}
			.store(in: &bag)
		
		wait(for: [expectation], timeout: 3)
	}
	
	func testGetDomains() {
		let expectation = XCTestExpectation(description: "tezos domain")
		MockConstants.shared.tezosDomainsClient.getDomainsFor(addresses: ["tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov", "tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov"])
			.sink { error in
				XCTFail(error.description)
				expectation.fulfill()
				
			} onSuccess: { response in
				XCTAssert(response["tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov"]?.data?.domain() == "crane-cost.gra", "\( response["tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov"]?.data?.domain() ?? "-" )")
				expectation.fulfill()
			}
			.store(in: &bag)
		
		wait(for: [expectation], timeout: 3)
	}
	
	func testGetAddresses() {
		let expectation = XCTestExpectation(description: "tezos domain")
		MockConstants.shared.tezosDomainsClient.getAddressesFor(domains: ["crane-cost.gra", "crane-cost.gra", "crane-cost.gra"])
			.sink { error in
				XCTFail(error.description)
				expectation.fulfill()
				
			} onSuccess: { response in
				XCTAssert(response["crane-cost.gra"] == "tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov", "\( response["crane-cost.gra"] ?? "-" )")
				expectation.fulfill()
			}
			.store(in: &bag)
		
		wait(for: [expectation], timeout: 3)
	}
}
