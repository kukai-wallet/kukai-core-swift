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
	
	public let user_rewards: Int
}
