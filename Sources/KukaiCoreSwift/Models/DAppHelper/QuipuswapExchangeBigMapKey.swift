//
//  QuipuswapExchangeBigMapKey.swift
//  
//
//  Created by Simon Mcloughlin on 19/11/2021.
//

import Foundation

public typealias QuipuswapExchangeBigMapKeyResponse = [QuipuswapExchangeBigMapKey]

public struct QuipuswapExchangeBigMapKey: Codable {
	
	public let value: QuipuswapExchangeBigMapKeyValue
}

public struct QuipuswapExchangeBigMapKeyValue: Codable {
	
	public let reward: String
	public let reward_paid: String
}
