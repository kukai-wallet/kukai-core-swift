//
//  AggregateRewardInformation.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

public struct AggregateRewardInformation: Codable {
	
	public let previousReward: RewardDetails?
	public let estimatedPreviousReward: RewardDetails?
	public let estimatedNextReward: RewardDetails?
}

public struct RewardDetails: Codable {
	
	public let bakerAlias: String?
	public let bakerLogo: URL?
	public let paymentAddress: String
	
	public let amount: XTZAmount
	public let cycle: Int
	public let fee: Double
	public let timeString: String
	
	public init(bakerAlias: String?, bakerLogo: URL?, paymentAddress: String, amount: XTZAmount, cycle: Int, fee: Double, date: Date) {
		self.bakerAlias = bakerAlias
		self.bakerLogo = bakerLogo
		self.paymentAddress = paymentAddress
		self.amount = amount
		self.cycle = cycle
		self.fee = fee
		self.timeString = date.timeAgoDisplay()
	}
}
