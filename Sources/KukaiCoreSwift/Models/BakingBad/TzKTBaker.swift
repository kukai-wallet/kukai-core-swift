//
//  TzKTBaker.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation


/*
 
 {
         "address": "tz1PWCDnz783NNGGQjEFFsHtrcK5yBW4E2rm",
         "name": "Melange",
         "status": "active",
         "balance": 578321.906329,
         "features": [],
         "delegation": {
             "enabled": true,
             "minBalance": 5,
             "fee": 0.1499,
             "capacity": 5146004.090457,
             "freeSpace": 1970337.090154,
             "estimatedApy": 0.0720,
             "features": []
         },
         "staking": {
             "enabled": true,
             "minBalance": 0,
             "fee": 0.0099,
             "capacity": 2858891.161365,
             "freeSpace": 2858165.485216,
             "estimatedApy": 0.1678,
             "features": []
         }
     }
 
 */


/// Whether the baker is actively running or not
public enum TzKTBakerStatus: String, Codable {
	case active
	case closed
}

/// Object to denote the delegation parameters of the baker
public struct TzKTBakerDelegation: Codable {
    let enabled: Bool
    let minBalance: Decimal
    let fee: Double
    let capacity: Decimal
    let freeSpace: Decimal
    let estimatedApy: Double
}

/// Object to denote the staking parameters of the baker
public struct TzKTBakerStaking: Codable {
    let enabled: Bool
    let minBalance: Decimal
    let fee: Double
    let capacity: Decimal
    let freeSpace: Decimal
    let estimatedApy: Double
}

/// Data representing a baker from TzKT or Baking-Bad
public struct TzKTBaker: Codable, Hashable {
	
	public let address: String
	public let name: String?
    public let status: TzKTBakerStatus
    public let balance: Decimal
    public let delegation: TzKTBakerDelegation
    public let staking: TzKTBakerStaking
    public let config: TzKTBakerConfig?
    
    public var logo: URL? {
        get {
            return TzKTClient.avatarURL(forToken: address)
        }
    }
    
	/// Helper to create a TzKTBaker from the data available from the `Account` object
	public init(address: String, name: String?) {
		self.address = address
		self.name = name
        self.status = .active
		self.balance = 0
        self.delegation = TzKTBakerDelegation(enabled: true, minBalance: 0, fee: 0, capacity: 0, freeSpace: 0, estimatedApy: 0)
        self.staking = TzKTBakerStaking(enabled: true, minBalance: 0, fee: 0, capacity: 0, freeSpace: 0, estimatedApy: 0)
        self.config = nil
	}
    
    public init(address: String, name: String?, status: TzKTBakerStatus, balance: Decimal, delegation: TzKTBakerDelegation, staking: TzKTBakerStaking, config: TzKTBakerConfig?) {
		self.address = address
		self.name = name
		self.balance = balance
        self.status = status
        self.delegation = delegation
        self.staking = staking
        self.config = config
	}
	
	/// Ghostnet has a different setup for bakers, but we need to display and interact with them the same way.
	/// So this helper extract what it can from the API and creates semi-real baker objects to help users deal with Ghostnet
	public static func fromTestnetArray(_ data: [Any]) -> TzKTBaker? {
		guard data.count == 4, let address = data[0] as? String, let balance = (data[2] as? NSNumber)?.decimalValue, let stakingBalance = (data[3] as? NSNumber)?.decimalValue else {
			return nil
		}
		
		let name = data[1] as? String
		let normalisedBalance = balance/1000000
		let normalisedStakingBal = stakingBalance/1000000
        let delegation = TzKTBakerDelegation(enabled: true, minBalance: 0, fee: 0.05, capacity: normalisedStakingBal, freeSpace: normalisedStakingBal, estimatedApy: 0.05)
        let staking = TzKTBakerStaking(enabled: true, minBalance: 0, fee: 0.05, capacity: normalisedStakingBal, freeSpace: normalisedStakingBal, estimatedApy: 0.05)
        return TzKTBaker(address: address, name: name, status: .active, balance: normalisedBalance, delegation: delegation, staking: staking, config: nil)
	}
	
	/// Convert con-chain data into a meaningful, readable object
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
