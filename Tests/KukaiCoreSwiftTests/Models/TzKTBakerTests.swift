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
        let baker1 = TzKTBaker(address: "tz1abc123", name: "Baking Benjamins", logo: nil)
		XCTAssert(baker1.name == "Baking Benjamins")
		XCTAssert(baker1.config == nil)
		XCTAssert(baker1.rewardStruct() == nil)
		
		let config = TzKTBakerConfig(address: "tz1abc123",
									 fee: [
										TzKTBakerConfigDoubleValue(cycle: 500, value: 14),
										TzKTBakerConfigDoubleValue(cycle: 400, value: 12)
									 ],
									 minDelegation: [
										TzKTBakerConfigDoubleValue(cycle: 500, value: 14),
										TzKTBakerConfigDoubleValue(cycle: 400, value: 12)
									 ],
									 payoutDelay: [
										TzKTBakerConfigIntValue(cycle: 500, value: 1),
										TzKTBakerConfigIntValue(cycle: 400, value: 6)
									 ],
									 rewardStruct: [
										TzKTBakerConfigIntValue(cycle: 500, value: 981)
									 ])
		let baker2 = TzKTBaker(address: "tz1abc123", name: "Baking Benjamins", logo: nil, balance: 123, stakingBalance: 123, stakingCapacity: 123, maxStakingBalance: 123, freeSpace: 123, fee: 0.5, minDelegation: 123, payoutDelay: 1, payoutPeriod: 1, openForDelegation: true, estimatedRoi: 5.5, serviceHealth: .active, payoutTiming: .stable, payoutAccuracy: .precise, config: config)
		XCTAssert(baker2.name == "Baking Benjamins")
		XCTAssert(baker2.config != nil)
		XCTAssert(baker2.config?.latesetFee() == 14)
		XCTAssert(baker2.config?.latestPayoutDelay() == 1)
		XCTAssert(baker2.rewardStruct()?.blocks == true)
		XCTAssert(baker2.rewardStruct()?.missedBlocks == false)
		XCTAssert(baker2.rewardStruct()?.endorsements == true)
		XCTAssert(baker2.rewardStruct()?.missedEndorsements == false)
		XCTAssert(baker2.rewardStruct()?.fees == true)
		XCTAssert(baker2.rewardStruct()?.missedFees == false)
		XCTAssert(baker2.rewardStruct()?.accusationRewards == true)
		XCTAssert(baker2.rewardStruct()?.accusationLosses == true)
		XCTAssert(baker2.rewardStruct()?.revelationRewards == true)
		XCTAssert(baker2.rewardStruct()?.revelationLosses == true)
    }
	
	func testGhostnetData() {
		let data: [[Any]] = [
			["tz1RuHDSj9P7mNNhfKxsyLGRDahTX5QD1DdP", "ECAD Labs Baker", 10060282903030, 31142132628366] as [Any],
			["tz1Xf8zdT3DbAX9cHw3c3CXh79rc4nK4gCe8", "Dictator Baker", 4486175812169, 23091323063658] as [Any],
			["tz1V16tR1LMKRernkmXzngkfznmEcTGXwDuk", NSNull(), 13183000715764, 13243746316323] as [Any]
		]
		
		
		let baker1 = TzKTBaker.fromTestnetArray(data[0])
		XCTAssert(baker1?.address == "tz1RuHDSj9P7mNNhfKxsyLGRDahTX5QD1DdP")
		XCTAssert(baker1?.name == "ECAD Labs Baker")
		XCTAssert(baker1?.balance.description == "10060282.90303", baker1?.balance.description ?? "-")
		XCTAssert(baker1?.stakingBalance.description == "31142132.628366", baker1?.stakingBalance.description ?? "-")
		
		let baker2 = TzKTBaker.fromTestnetArray(data[1])
		XCTAssert(baker2?.address == "tz1Xf8zdT3DbAX9cHw3c3CXh79rc4nK4gCe8")
		XCTAssert(baker2?.name == "Dictator Baker")
		XCTAssert(baker2?.balance.description == "4486175.812169", baker2?.balance.description ?? "-")
		XCTAssert(baker2?.stakingBalance.description == "23091323.063658", baker2?.stakingBalance.description ?? "-")
		
		let baker3 = TzKTBaker.fromTestnetArray(data[2])
		XCTAssert(baker3?.address == "tz1V16tR1LMKRernkmXzngkfznmEcTGXwDuk")
		XCTAssert(baker3?.name == nil)
		XCTAssert(baker3?.balance.description == "13183000.715764", baker3?.balance.description ?? "-")
		XCTAssert(baker3?.stakingBalance.description == "13243746.316323", baker3?.stakingBalance.description ?? "-")
	}
}
