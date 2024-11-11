//
//  TzKTDelegatorReward.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

/// An object containing info on the reward a delegator should receive from a baker
public struct TzKTDelegatorReward: Codable {
	
	public let cycle: Int
	public let delegatedBalance: Decimal
	public let stakedBalance: Decimal
	public let baker: TzKTAddress
	
	public let blockRewardsDelegated: Decimal
	public let endorsementRewardsDelegated: Decimal
	public let vdfRevelationRewardsDelegated: Decimal
	public let nonceRevelationRewardsDelegated: Decimal
	public let doubleBakingRewards: Decimal
	public let doubleEndorsingRewards: Decimal
	public let doublePreendorsingRewards: Decimal
	public let blockFees: Decimal
	
	public let doubleBakingLostUnstaked: Decimal
	public let doubleBakingLostExternalUnstaked: Decimal
	public let doubleEndorsingLostUnstaked: Decimal
	public let doubleEndorsingLostExternalUnstaked: Decimal
	public let doublePreendorsingLostUnstaked: Decimal
	public let doublePreendorsingLostExternalUnstaked: Decimal
	public let nonceRevelationLosses: Decimal
	
	public let bakerStakedBalance: Decimal
	public let externalStakedBalance: Decimal
	public let bakingPower: Decimal
	
	public let bakerDelegatedBalance: Decimal
	public let externalDelegatedBalance: Decimal
	
	public let futureBlocks: Decimal
	public let futureBlockRewards: Decimal
	public let futureEndorsementRewards: Decimal
	
	/// Return an estimated either for potential future or actual rewards
	public func estimatedReward(withFee fee: Double, limitOfStakingOverBaking: Decimal, edgeOfBakingOverStaking: Decimal, minDelegation: Decimal) -> XTZAmount {
		let totalRewardsDelegated = blockRewardsDelegated
									+ endorsementRewardsDelegated
									+ vdfRevelationRewardsDelegated
									+ nonceRevelationRewardsDelegated
									+ doubleBakingRewards
									+ doubleEndorsingRewards
									+ doublePreendorsingRewards
									+ blockFees
		
		let totalFutureRewards = futureBlockRewards
								+ futureEndorsementRewards

		let totalLostDelegated = doubleBakingLostUnstaked
								+ doubleBakingLostExternalUnstaked
								+ doubleEndorsingLostUnstaked
								+ doubleEndorsingLostExternalUnstaked
								+ doublePreendorsingLostUnstaked
								+ doublePreendorsingLostExternalUnstaked
								+ nonceRevelationLosses
		
		var totalFutureRewardsDelegated: Decimal = 0
		//var totalFutureRewardsStakedOwn: Decimal = 0
		//var totalFutureRewardsStakedEdge: Decimal = 0
		//var totalFutureRewardsStakedShared: Decimal = 0
		
		
		if (totalFutureRewards > 0) {
			let stakeCap = bakerStakedBalance * limitOfStakingOverBaking
			let actualStakedPower = bakerStakedBalance + min(externalStakedBalance, stakeCap)
			let rewardsStaked = totalFutureRewards * actualStakedPower / bakingPower
			totalFutureRewardsDelegated = totalFutureRewards - rewardsStaked
			//totalFutureRewardsStakedOwn = rewardsStaked * bakerStakedBalance / actualStakedPower
			//totalFutureRewardsStakedEdge = (rewardsStaked - totalFutureRewardsStakedOwn) * edgeOfBakingOverStaking
			//totalFutureRewardsStakedShared = rewardsStaked - totalFutureRewardsStakedOwn - totalFutureRewardsStakedEdge
		}
		
		
		let delegationFee = Decimal(fee) // might need: "Decimal(1 - fee)"
		let totalDelegatedRewards = max(0, (totalFutureRewardsDelegated + totalRewardsDelegated - totalLostDelegated))
		let totalDelegatedFees = totalDelegatedRewards * delegationFee
		let delegatedShare = (bakerDelegatedBalance + externalDelegatedBalance) > 0
							? delegatedBalance / (bakerDelegatedBalance + externalDelegatedBalance)
							: 0

		let isBalanceExceedMinimum = delegatedBalance / 1_000_000 >= minDelegation
		let delegatedRewards = (isBalanceExceedMinimum ? totalDelegatedRewards * delegatedShare : 0).rounded(scale: 0, roundingMode: .down)
		let delegatedFees = (isBalanceExceedMinimum ? totalDelegatedFees * delegatedShare : 0).rounded(scale: 0, roundingMode: .down)
		let delegatedIncome = (isBalanceExceedMinimum ? delegatedRewards - delegatedFees : 0).rounded(scale: 0, roundingMode: .down)
		
		return XTZAmount(fromRpcAmount: delegatedIncome) ?? .zero()
	}
}
