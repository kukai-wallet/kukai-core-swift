//
//  TzKTDelegatorReward.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

public struct TzKTDelegatorReward: Codable {
	
	public let cycle: Int
	public let balance: Decimal
	public let baker: TzKTAddress
	public let stakingBalance: Decimal
	
	public let blockRewards: Decimal
	public let missedBlockRewards: Decimal
	
	public let endorsementRewards: Decimal
	public let missedEndorsementRewards: Decimal
	
	public let blockFees: Decimal
	public let missedBlockFees: Decimal
	
	public let extraBlockRewards: Decimal
	public let missedExtraBlockRewards: Decimal
	
	public let futureBlockRewards: Decimal
	public let futureEndorsementRewards: Decimal
	
	/// Return an estimated either for potential future or actual rewards
	public func estimatedReward(withFee fee: Double, andRewardStruct: TzKTBakerConfigRewardStruct?) -> XTZAmount {
		var totalRewards = (blockRewards + endorsementRewards + futureBlockRewards + futureEndorsementRewards + extraBlockRewards)
		let delegatorPercentage = balance / stakingBalance
		
		if let rewardStruct = andRewardStruct {
			if rewardStruct.fees {
				totalRewards += blockFees
			}
			
			if rewardStruct.missedBlocks {
				totalRewards += (missedBlockRewards + missedExtraBlockRewards)
			}
			
			if rewardStruct.fees && rewardStruct.missedBlocks {
				totalRewards += missedBlockFees
			}
			
			if rewardStruct.missedEndorsements {
				totalRewards += missedEndorsementRewards
			}
		}
		
		let paymentEstimate = totalRewards * delegatorPercentage
		let minusFee = paymentEstimate * Decimal(1 - fee)
			
		return XTZAmount(fromNormalisedAmount: minusFee.rounded(scale: 6, roundingMode: .bankers))
	}
}
