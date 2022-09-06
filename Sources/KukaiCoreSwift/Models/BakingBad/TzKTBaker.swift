//
//  TzKTBaker.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

/// The stability of the bakers server
public enum TzKTBakerHealth: String, Codable {
	case active
	case closed
	case dead
}

/// The accuracy of the bakers payments
public enum TzKTBakerAccuracy: String, Codable {
	case precise
	case inaccurate
	case suspicious
	case no_data
}

/// The reliability of the bakers payouts
public enum TzKTBakerTiming: String, Codable {
	case stable
	case unstable
	case suspicious
	case no_data
}

/// Data representing a baker from TzKT or Baking-Bad
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
	
	public func rewardStruct() -> TzKTBakerConfigRewardStruct? {
		guard let config = config, let rewardStructInt = config.latestRewardStruct() else {
			return nil
		}
		
		return TzKTBakerConfigRewardStruct.fromConfigInt(rewardStructInt)
	}
}

/// The bakers config file for details on when fees, min delegation etc change
public struct TzKTBakerConfig: Codable {

	public let address: String
	public let fee: [TzKTBakerConfigDoubleValue]
	public let minDelegation: [TzKTBakerConfigDoubleValue]
	public let payoutDelay: [TzKTBakerConfigIntValue]
	public let rewardStruct: [TzKTBakerConfigIntValue]
	
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
	
	public func latestRewardStruct() -> Int? {
		return rewardStruct.first?.value
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

/// Baker config payout flags
public struct TzKTBakerConfigRewardStruct: Codable {
	public let blocks: Bool
	public let missedBlocks: Bool
	public let endorsements: Bool
	public let missedEndorsements: Bool
	public let fees: Bool
	public let missedFees: Bool
	public let accusationRewards: Bool
	public let accusationLosses: Bool
	public let revelationRewards: Bool
	public let revelationLosses: Bool
	
	/// Convert the 14-bit number in the baker config, to the equivalent set of flags
	public static func fromConfigInt(_ config: Int) -> TzKTBakerConfigRewardStruct {
		let blocks = (config & 1) > 0
		let missedBlocks = (config & 2) > 0
		let endorsements = (config & 4) > 0
		let missedEndorsements = (config & 8) > 0
		let fees = (config & 16) > 0
		let missedFees = (config & 32) > 0
		let accusationRewards = (config & 64) > 0
		let accusationLosses = (config & 128) > 0
		let revelationRewards = (config & 256) > 0
		let revelationLosses = (config & 512) > 0
		
		return TzKTBakerConfigRewardStruct(blocks: blocks,
										   missedBlocks: missedBlocks,
										   endorsements: endorsements,
										   missedEndorsements: missedEndorsements,
										   fees: fees,
										   missedFees: missedFees,
										   accusationRewards: accusationRewards,
										   accusationLosses: accusationLosses,
										   revelationRewards: revelationRewards,
										   revelationLosses: revelationLosses)
	}
}
