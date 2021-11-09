//
//  TezToolPair.swift
//  
//
//  Created by Simon Mcloughlin on 08/11/2021.
//

import Foundation

public enum TezToolDex: String, Codable {
	case quipuswap = "Quipuswap"
	case liquidityBaking = "Liquidity Baking"
	case unknown
	
	public init(from decoder: Decoder) throws {
		self = try TezToolDex(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

public struct TezToolPair: Codable {
	
	let address: String
	let dex: TezToolDex
	let symbols: String
	let sides: [TezToolSide]
}

public struct TezToolSide: Codable {
	
	let symbol: String
	let pool: TokenAmount
}
