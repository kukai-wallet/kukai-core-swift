//
//  TzKTDelegatorReward.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

public struct TzKTDelegatorReward: Codable {
	
	let cycle: Int
	let balance: Decimal
	let baker: TzKTAddress
	let stakingBalance: Decimal
	
	let blockRewards: Decimal
	let endorsementRewards: Decimal
	
	let futureBlockRewards: Decimal
	let futureEndorsementRewards: Decimal
	
	/// Return an estimated either for potential future or actual rewards
	func estimatedReward(givenStakedBalanceOf staked: Decimal, andFee fee: Double) -> XTZAmount {
		
		// One set will always be zero and the other will have a number, can just add all rather than if checks
		let totalRewards = (blockRewards + endorsementRewards + futureBlockRewards + futureEndorsementRewards)
		let delegatorPercentage = staked / stakingBalance
		
		let paymentEstimate = totalRewards * delegatorPercentage
		let minusFee = paymentEstimate * Decimal(1 - fee)
		
		return XTZAmount(fromNormalisedAmount: minusFee.rounded(scale: 6, roundingMode: .bankers))
	}
}
