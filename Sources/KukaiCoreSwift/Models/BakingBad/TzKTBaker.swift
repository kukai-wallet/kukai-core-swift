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
	
	public let address: String
	public let name: String?
	public let logo: String?
	public let balance: Decimal
	public let stakingBalance: Decimal
	public let stakingCapacity: Decimal
	public let maxStakingBalance: Decimal
	public let freeSpace: Decimal
	public let fee: Double
	public let minDelegation: Decimal
	public let payoutDelay: Int
	public let payoutPeriod: Int
	public let openForDelegation: Bool
	public let estimatedRoi: Decimal
	public let serviceHealth: TzKTBakerHealth
	public let payoutTiming: TzKTBakerTiming
	public let payoutAccuracy: TzKTBakerAccuracy
	public let config: TzKTBakerConfig?
	
	public static func fromTestnetArray(_ data: [Any]) -> TzKTBaker? {
		guard data.count == 3, let address = data[0] as? String, let balance = data[1] as? Decimal, let stakingBalance = data[2] as? Decimal else {
			return nil
		}
		
		return TzKTBaker(address: address, name: nil, logo: nil, balance: balance, stakingBalance: stakingBalance, stakingCapacity: stakingBalance * 2, maxStakingBalance: stakingBalance * 2, freeSpace: stakingBalance, fee: 0.05, minDelegation: 0, payoutDelay: 6, payoutPeriod: 1, openForDelegation: true, estimatedRoi: 0.05, serviceHealth: .active, payoutTiming: .no_data, payoutAccuracy: .no_data, config: nil)
	}
}

public struct TzKTBakerConfig: Codable {

	public let address: String
	public let fee: [TzKTBakerConfigDoubleValue]
	public let minDelegation: [TzKTBakerConfigDoubleValue]
	public let payoutDelay: [TzKTBakerConfigIntValue]
	
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
	public let cycle: Int
	public let value: Double
}

public struct TzKTBakerConfigIntValue: Codable {
	public let cycle: Int
	public let value: Int
}
