//
//  QuipuswapExchangeUserRewards.swift
//  
//
//  Created by Simon Mcloughlin on 19/11/2021.
//

import Foundation

/// Wrapper object around the network response
public typealias QuipuswapExchangeUserRewardsKeyResponse = [QuipuswapExchangeUserRewardsKey]

/// The gneric container object holding the raw data
public struct QuipuswapExchangeUserRewardsKey: Codable {
	
	public let value: QuipuswapExchangeUserRewards
}

/// The unique data inside the User Rewards BigMap
public struct QuipuswapExchangeUserRewards: Codable {
	
	/// Total reward the user has earned
	public let reward: String
	
	/// Total rewards that have been paid out to the user
	public let reward_paid: String
}
