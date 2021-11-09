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
	
	public let address: String
	public let dex: TezToolDex
	public let symbols: String
	public let sides: [TezToolSide]
}

public struct TezToolSide: Codable {
	
	public let symbol: String
	public let pool: TokenAmount
}
