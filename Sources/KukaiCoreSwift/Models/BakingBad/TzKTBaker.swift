//
//  TzKTBaker.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

public enum TzKTBakerHealth: String, Codable {
	case active
	case closed
	case dead
}

public enum TzKTBakerAccuracy: String, Codable {
	case precise
	case inaccurate
	case suspicious
	case no_data
}

public enum TzKTBakerTiming: String, Codable {
	case stable
	case unstable
	case suspicious
	case no_data
}

public struct TzKTBaker: Codable {
	
	let address: String
	let name: String?
	let logo: String?
	let balance: Decimal
	let stakingBalance: Decimal
	let stakingCapacity: Decimal
	let maxStakingBalance: Decimal
	let freeSpace: Decimal
	let fee: Double
	let minDelegation: Decimal
	let payoutDelay: Int
	let payoutPeriod: Int
	let openForDelegation: Bool
	let estimatedRoi: Decimal
	let serviceHealth: TzKTBakerHealth
	let payoutTiming: TzKTBakerTiming
	let payoutAccuracy: TzKTBakerAccuracy
	let config: TzKTBakerConfig?
	
	public static func fromTestnetArray(_ data: [Any]) -> TzKTBaker? {
		guard data.count == 3, let address = data[0] as? String, let balance = data[1] as? Decimal, let stakingBalance = data[2] as? Decimal else {
			return nil
		}
		
		return TzKTBaker(address: address, name: nil, logo: nil, balance: balance, stakingBalance: stakingBalance, stakingCapacity: stakingBalance * 2, maxStakingBalance: stakingBalance * 2, freeSpace: stakingBalance, fee: 0.05, minDelegation: 0, payoutDelay: 6, payoutPeriod: 1, openForDelegation: true, estimatedRoi: 0.05, serviceHealth: .active, payoutTiming: .no_data, payoutAccuracy: .no_data, config: nil)
	}
}

public struct TzKTBakerConfig: Codable {

	let address: String
	let fee: [TzKTBakerConfigDoubleValue]
	let minDelegation: [TzKTBakerConfigDoubleValue]
	let payoutDelay: [TzKTBakerConfigIntValue]
	
	public func latesetFee() -> Double {
		return fee.first?.value ?? 0
	}
	
	public func feeForCycle(cycle: Int) -> Double {
		for obj in fee {
			if obj.cycle < cycle || obj.cycle == cycle {
				return obj.value
			}
		}
		
		return 0
	}
	
	public func latestPayoutDelay() -> Int {
		return payoutDelay.first?.value ?? 0
	}
	
	public func payoutDelayForCycle(cycle: Int) -> Int {
		for obj in payoutDelay {
			if obj.cycle < cycle || obj.cycle == cycle {
				return obj.value
			}
		}
		
		return 0
	}
}

public struct TzKTBakerConfigDoubleValue: Codable {
	let cycle: Int
	let value: Double
}

public struct TzKTBakerConfigIntValue: Codable {
	let cycle: Int
	let value: Int
}
