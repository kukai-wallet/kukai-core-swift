//
//  AggregateRewardInformation.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

/// Object ot abstract away a significatn amount of logic involved in computing  estimated reward payments from a baker
public struct AggregateRewardInformation: Codable, Hashable, Equatable {
	
	private let id: UUID
	
	public let previousReward: RewardDetails?
	public let estimatedPreviousReward: RewardDetails?
	public let estimatedNextReward: RewardDetails?
	
	public init(previousReward: RewardDetails?, estimatedPreviousReward: RewardDetails?, estimatedNextReward: RewardDetails?) {
		self.id = UUID()
		self.previousReward = previousReward
		self.estimatedPreviousReward = estimatedPreviousReward
		self.estimatedNextReward = estimatedNextReward
	}
	
	/// Creating this object involves many expensive requests, but produces a result that is valid for up to ~3 days.
	/// This function can be used to determine if its ok to read a previous object from a cache, or if it needs to be refreshed
	public func isOutOfDate() -> Bool {
		guard let endDate = estimatedNextReward?.dateOfPayment else {
			return true
		}
		
		return endDate < Date()
	}
	
	/// When `previousReward` is present, it is possible that due to a delay in payment being received, that we may cache an object before the last payment was received
	/// In this case, if we only relied on `isOutOfDate()` we would not update again for ~3 days. Both checks will be needed
	public func moreThan1CycleBetweenPreiousAndNext() -> Bool {
		guard let previous = previousReward, let next = estimatedNextReward else {
			return false
		}
		
		return (next.cycle - previous.cycle) > 1
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	public static func == (lhs: AggregateRewardInformation, rhs: AggregateRewardInformation) -> Bool {
		return lhs.id == rhs.id
	}
}

/// An individual payment record denoting some payment in the past or future
public struct RewardDetails: Codable {
	
	public let bakerAlias: String?
	public let bakerLogo: URL?
	public let paymentAddress: String
	
	public let amount: XTZAmount
	public let cycle: Int
	public let fee: Double
	public let dateOfPayment: Date
	public let meetsMinDelegation: Bool
	
	public init(bakerAlias: String?, bakerLogo: URL?, paymentAddress: String, amount: XTZAmount, cycle: Int, fee: Double, date: Date, meetsMinDelegation: Bool) {
		self.bakerAlias = bakerAlias
		self.bakerLogo = bakerLogo
		self.paymentAddress = paymentAddress
		self.amount = amount
		self.cycle = cycle
		self.fee = fee
		self.dateOfPayment = date
		self.meetsMinDelegation = meetsMinDelegation
	}
}
