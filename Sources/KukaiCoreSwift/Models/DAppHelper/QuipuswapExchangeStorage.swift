//
//  QuipuswapExchangeStorage.swift
//  
//
//  Created by Simon Mcloughlin on 19/11/2021.
//

import Foundation

/// Network wrapper object
public struct QuipuswapExchangeStorageResponse: Codable {
	
	public let storage: QuipuswapExchangeStorage
}

/// Unique Quipuswap contract storage object
public struct QuipuswapExchangeStorage: Codable {
	
	/// Ledger bigmap id
	public let ledger: Int
	
	/// user rewards bigmap id
	public let user_rewards: Int
	
	/// The current reward
	public let reward: String
	
	/// The amount of rewards paid out
	public let reward_paid: String
	
	/// Total reward
	public let total_reward: String
	
	/// Totoal supply of this token
	public let total_supply: String
	
	/// Date/Time the period will finish
	public let period_finish: String
	
	/// The reward per second
	public let reward_per_sec: String
	
	/// Date/Time of the last recorded update to the sotrage
	public let last_update_time: String
	
	/// The entitled reward per 1 share owned
	public let reward_per_share: String
	
	
	
	/// Convert a string to a Date object using Zulu time format
	public func date(from: String) -> Date? {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
		formatter.timeZone = TimeZone(secondsFromGMT: 0)
		
		return formatter.date(from: from)
	}
}
