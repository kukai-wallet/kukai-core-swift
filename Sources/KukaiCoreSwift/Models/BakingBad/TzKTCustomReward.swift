//
//  TzKTCustomReward.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

public struct TzKTCustomReward: Codable {
	
	public let previousReward: TzKTRewardDetails?
	public let estimatedPreviousReward: TzKTRewardDetails
	public let estimatedNextReward: TzKTRewardDetails
}

public struct TzKTRewardDetails: Codable {
	
	public let amount: XTZAmount
	public let cycle: Int?
	public let timeString: String
	
	public init(amount: XTZAmount, cycle: Int?, date: Date) {
		self.amount = amount
		self.cycle = cycle
		self.timeString = date.timeAgoDisplay()
	}
}
