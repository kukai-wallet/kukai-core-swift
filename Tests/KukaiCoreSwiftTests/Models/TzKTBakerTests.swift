//
//  TzKTBakerTests.swift
//  
//
//  Created by Simon Mcloughlin on 19/09/2023.
//

import XCTest
@testable import KukaiCoreSwift

final class TzKTBakerTests: XCTestCase {

    func testBalerCreation() throws {
        let baker1 = TzKTBaker(address: "tz1abc123", name: "Baking Benjamins")
		XCTAssert(baker1.name == "Baking Benjamins")
		XCTAssert(baker1.logo?.absoluteString == "https://services.tzkt.io/v1/logos/tz1abc123.png", baker1.logo?.absoluteString ?? "-")
    }
	
	func testGhostnetData() {
		let data: [[Any]] = [
			["tz1RuHDSj9P7mNNhfKxsyLGRDahTX5QD1DdP", "ECAD Labs Baker", 10060282903030, 31142132628366, 5000000, 330000000] as [Any],
			["tz1Xf8zdT3DbAX9cHw3c3CXh79rc4nK4gCe8", "Dictator Baker", 4486175812169, 23091323063658, 5000000, 330000000] as [Any],
			["tz1V16tR1LMKRernkmXzngkfznmEcTGXwDuk", NSNull(), 13183000715764, 13243746316323, NSNull(), NSNull()] as [Any]
		]
		
		
		let baker1 = TzKTBaker.fromTestnetArray(data[0])
		XCTAssert(baker1?.address == "tz1RuHDSj9P7mNNhfKxsyLGRDahTX5QD1DdP", baker1?.address ?? "-")
		XCTAssert(baker1?.name == "ECAD Labs Baker", baker1?.name ?? "-")
		XCTAssert(baker1?.balance.description == "10060282.90303", baker1?.balance.description ?? "-")
		XCTAssert(baker1?.staking.freeSpace.description == "31142132.628366", baker1?.staking.freeSpace.description ?? "-")
		
		let baker2 = TzKTBaker.fromTestnetArray(data[1])
		XCTAssert(baker2?.address == "tz1Xf8zdT3DbAX9cHw3c3CXh79rc4nK4gCe8", baker2?.address ?? "-")
		XCTAssert(baker2?.name == "Dictator Baker", baker2?.name ?? "-")
		XCTAssert(baker2?.balance.description == "4486175.812169", baker2?.balance.description ?? "-")
		XCTAssert(baker2?.staking.freeSpace.description == "23091323.063658", baker2?.staking.freeSpace.description ?? "-")
		
		let baker3 = TzKTBaker.fromTestnetArray(data[2])
		XCTAssert(baker3 == nil)
	}
}
