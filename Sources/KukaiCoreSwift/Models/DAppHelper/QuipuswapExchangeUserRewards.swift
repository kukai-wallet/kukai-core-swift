//
//  QuipuswapExchangeUserRewards.swift
//  
//
//  Created by Simon Mcloughlin on 19/11/2021.
//

import Foundation

public typealias QuipuswapExchangeUserRewardsKeyResponse = [QuipuswapExchangeUserRewardsKey]

public struct QuipuswapExchangeUserRewardsKey: Codable {
	
	public let value: QuipuswapExchangeUserRewards
}

public struct QuipuswapExchangeUserRewards: Codable {
	
	public let reward: String
	public let reward_paid: String
}
