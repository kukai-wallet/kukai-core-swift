//
//  QuipuswapExchangeStorage.swift
//  
//
//  Created by Simon Mcloughlin on 19/11/2021.
//

import Foundation

public struct QuipuswapExchangeStorageResponse: Codable {
	
	public let storage: QuipuswapExchangeStorage
}

public struct QuipuswapExchangeStorage: Codable {
	
	public let ledger: Int
	public let user_rewards: Int
	
	public let reward: String
	public let reward_paid: String
	public let total_reward: String
	public let total_supply: String
	public let period_finish: String
	public let reward_per_sec: String
	public let last_update_time: String
	public let reward_per_share: String
	
	public func date(from: String) -> Date? {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
		formatter.timeZone = TimeZone(secondsFromGMT: 0)
		
		return formatter.date(from: from)
	}
}
