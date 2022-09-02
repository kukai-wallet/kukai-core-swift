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
	public let endorsementRewards: Decimal
	
	public let futureBlockRewards: Decimal
	public let futureEndorsementRewards: Decimal
	
	/// Return an estimated either for potential future or actual rewards
	public func estimatedReward(withFee fee: Double) -> XTZAmount {
		
		// One set will always be zero and the other will have a number, can just add all rather than if checks
		let totalRewards = (blockRewards + endorsementRewards + futureBlockRewards + futureEndorsementRewards)
		let delegatorPercentage = balance / stakingBalance
		
		let paymentEstimate = totalRewards * delegatorPercentage
		let minusFee = paymentEstimate * Decimal(1 - fee)
		
		return XTZAmount(fromNormalisedAmount: minusFee.rounded(scale: 6, roundingMode: .bankers))
	}
}
