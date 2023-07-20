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
public struct TzKTBaker: Codable, Hashable {
	
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
	
	/// Helper to create a TzKTBaker from the data available from the `Account` object
	public init(address: String, name: String?, logo: String?) {
		self.address = address
		self.name = name
		self.logo = logo
		
		self.balance = 0
		self.stakingBalance = 0
		self.stakingCapacity = 0
		self.maxStakingBalance = 0
		self.freeSpace = 0
		self.fee = 0
		self.minDelegation = 0
		self.payoutDelay = 0
		self.payoutPeriod = 0
		self.openForDelegation = false
		self.estimatedRoi = 0
		self.serviceHealth = .dead
		self.payoutTiming = .no_data
		self.payoutAccuracy = .no_data
		self.config = nil
	}
	
	public init(address: String, name: String?, logo: String?, balance: Decimal, stakingBalance: Decimal, stakingCapacity: Decimal, maxStakingBalance: Decimal, freeSpace: Decimal, fee: Double, minDelegation: Decimal, payoutDelay: Int, payoutPeriod: Int, openForDelegation: Bool, estimatedRoi: Decimal, serviceHealth: TzKTBakerHealth, payoutTiming: TzKTBakerTiming, payoutAccuracy: TzKTBakerAccuracy, config: TzKTBakerConfig?) {
		
		self.address = address
		self.name = name
		self.logo = logo
		self.balance = balance
		self.stakingBalance = stakingBalance
		self.stakingCapacity = stakingCapacity
		self.maxStakingBalance = maxStakingBalance
		self.freeSpace = freeSpace
		self.fee = fee
		self.minDelegation = minDelegation
		self.payoutDelay = payoutDelay
		self.payoutPeriod = payoutPeriod
		self.openForDelegation = openForDelegation
		self.estimatedRoi = estimatedRoi
		self.serviceHealth = serviceHealth
		self.payoutTiming = payoutTiming
		self.payoutAccuracy = payoutAccuracy
		self.config = config
	}
	
	public static func fromTestnetArray(_ data: [Any]) -> TzKTBaker? {
		guard data.count == 4, let address = data[0] as? String, let balance = (data[2] as? NSNumber)?.decimalValue, let stakingBalance = (data[3] as? NSNumber)?.decimalValue else {
			return nil
		}
		
		let name = data[1] as? String
		let normalisedBalance = balance/1000000
		let normalisedStakingBal = stakingBalance/1000000
		return TzKTBaker(address: address, name: name, logo: nil, balance: normalisedBalance, stakingBalance: normalisedStakingBal, stakingCapacity: normalisedStakingBal, maxStakingBalance: normalisedStakingBal, freeSpace: normalisedStakingBal, fee: 0.05, minDelegation: 0, payoutDelay: 6, payoutPeriod: 1, openForDelegation: true, estimatedRoi: 0.05, serviceHealth: .active, payoutTiming: .no_data, payoutAccuracy: .no_data, config: nil)
	}
	
	public func rewardStruct() -> TzKTBakerConfigRewardStruct? {
		guard let config = config, let rewardStructInt = config.latestRewardStruct() else {
			return nil
		}
		
		return TzKTBakerConfigRewardStruct.fromConfigInt(rewardStructInt)
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(address)
	}
	
	public static func == (lhs: TzKTBaker, rhs: TzKTBaker) -> Bool {
		return lhs.address == rhs.address
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
