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
	public let blockRewardsStakedEdge: Decimal
	public let blockRewardsStakedShared: Decimal
	
	public let endorsementRewardsDelegated: Decimal
	public let endorsementRewardsStakedEdge: Decimal
	public let endorsementRewardsStakedShared: Decimal
	
	public let vdfRevelationRewardsDelegated: Decimal
	public let vdfRevelationRewardsStakedEdge: Decimal
	public let vdfRevelationRewardsStakedShared: Decimal
	
	public let nonceRevelationRewardsDelegated: Decimal
	public let nonceRevelationRewardsStakedEdge: Decimal
	public let nonceRevelationRewardsStakedShared: Decimal
	
	public let doubleBakingRewards: Decimal
	public let doubleBakingLostExternalStaked: Decimal
	public let doubleEndorsingRewards: Decimal
	public let doubleEndorsingLostExternalStaked: Decimal
	public let doublePreendorsingRewards: Decimal
	public let doublePreendorsingLostExternalStaked: Decimal
	public let blockFees: Decimal
	
	public let doubleBakingLostUnstaked: Decimal
	public let doubleBakingLostExternalUnstaked: Decimal
	public let doubleEndorsingLostUnstaked: Decimal
	public let doubleEndorsingLostExternalUnstaked: Decimal
	public let doublePreendorsingLostUnstaked: Decimal
	public let doublePreendorsingLostExternalUnstaked: Decimal
	public let doubleBakingLostStaked: Decimal
	public let doubleEndorsingLostStaked: Decimal
	public let doublePreendorsingLostStaked: Decimal
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
	public func estimatedReward(withDelegationFee fee: Double, limitOfStakingOverBaking: Decimal, edgeOfBakingOverStaking: Decimal, minDelegation: Decimal) -> (delegate: XTZAmount, stake: XTZAmount) {
		
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
		
		let totalRewardsStakedEdge = blockRewardsStakedEdge
									+ endorsementRewardsStakedEdge
									+ vdfRevelationRewardsStakedEdge
									+ nonceRevelationRewardsStakedEdge
		
		let totalRewardsStakedShared = blockRewardsStakedShared
										+ endorsementRewardsStakedShared
										+ vdfRevelationRewardsStakedShared
										+ nonceRevelationRewardsStakedShared

		let edge = totalRewardsStakedEdge > 0
			? totalRewardsStakedEdge / (totalRewardsStakedEdge + totalRewardsStakedShared)
			: 0

		let totalLostStaked = doubleBakingLostStaked
								+ doubleEndorsingLostStaked
								+ doublePreendorsingLostStaked

		let totalLostStakedOwn = totalLostStaked * (1 - edge)
		let totalLostStakedEdge = totalLostStaked - totalLostStakedOwn
		
		let totalLostStakedShared = doubleBakingLostExternalStaked
									+ doubleEndorsingLostExternalStaked
									+ doublePreendorsingLostExternalStaked
		
		var totalFutureRewardsDelegated: Decimal = 0
		var totalFutureRewardsStakedOwn: Decimal = 0
		var totalFutureRewardsStakedEdge: Decimal = 0
		var totalFutureRewardsStakedShared: Decimal = 0
		
		
		// Delegation rewards contain estimated future rewards, and current exact rewards
		// Before continuing check if its future or not and grab different values if so
		if (totalFutureRewards > 0) {
			let stakeCap = bakerStakedBalance * limitOfStakingOverBaking
			let actualStakedPower = bakerStakedBalance + min(externalStakedBalance, stakeCap)
			let rewardsStaked = totalFutureRewards * actualStakedPower / bakingPower
			totalFutureRewardsDelegated = totalFutureRewards - rewardsStaked
			totalFutureRewardsStakedOwn = rewardsStaked * bakerStakedBalance / actualStakedPower
			totalFutureRewardsStakedEdge = (rewardsStaked - totalFutureRewardsStakedOwn) * edgeOfBakingOverStaking
			totalFutureRewardsStakedShared = rewardsStaked - totalFutureRewardsStakedOwn - totalFutureRewardsStakedEdge
		}
		
		
		// Delegate
		let delegationFee = Decimal(fee)
		let totalDelegatedRewards = max(0, (totalFutureRewardsDelegated + totalRewardsDelegated - totalLostDelegated))
		let totalDelegatedFees = totalDelegatedRewards * delegationFee
		let delegatedShare = (bakerDelegatedBalance + externalDelegatedBalance) > 0
							? delegatedBalance / (bakerDelegatedBalance + externalDelegatedBalance)
							: 0

		let isBalanceExceedMinimum = delegatedBalance / 1_000_000 >= minDelegation
		let delegatedRewards = (isBalanceExceedMinimum ? totalDelegatedRewards * delegatedShare : 0).rounded(scale: 0, roundingMode: .down)
		let delegatedFees = (isBalanceExceedMinimum ? totalDelegatedFees * delegatedShare : 0).rounded(scale: 0, roundingMode: .down)
		let delegatedIncome = (isBalanceExceedMinimum ? delegatedRewards - delegatedFees : 0).rounded(scale: 0, roundingMode: .down)
		
		
		// Stake
		let totalStakedRewards = max(0, totalFutureRewardsStakedEdge
										+ totalFutureRewardsStakedShared
										+ (totalRewardsStakedEdge - totalLostStakedEdge)
										+ (totalRewardsStakedShared - totalLostStakedShared))
		let totalStakedFees = max(0, totalFutureRewardsStakedEdge
										+ (totalRewardsStakedEdge - totalLostStakedEdge))
		let stakedShare = externalStakedBalance > 0 ? stakedBalance / externalStakedBalance : 0
		let stakedRewards = (totalStakedRewards * stakedShare).rounded(scale: 0, roundingMode: .down)
		let stakedFees = (totalStakedFees * stakedShare).rounded(scale: 0, roundingMode: .down)
		let stakedIncome = (stakedRewards - stakedFees).rounded(scale: 0, roundingMode: .down)
		
		
		// Results
		return (delegate: XTZAmount(fromRpcAmount: delegatedIncome) ?? .zero(), stake: XTZAmount(fromRpcAmount: stakedIncome) ?? .zero())
	}
}
