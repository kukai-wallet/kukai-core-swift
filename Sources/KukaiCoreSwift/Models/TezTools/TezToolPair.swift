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
	
	/// Sides contains an array of objects providing details of each token available in the swap
	/// Apps will need to extract a list of the available tokens, easiest way to do that is to extract the side, that doesn't contain the base token (frequently XTZ)
	public func nonBaseTokenSide() -> TezToolSide {
		for side in sides {
			if side.tokenType == nil {
				return side
			}
		}
	}
}

extension TezToolPair: Hashable {
	
	/// Conforming to `Hashable` to enable working with UITableViewDiffableDataSource
	public func hash(into hasher: inout Hasher) {
		hasher.combine(address)
		hasher.combine(dex.rawValue)
	}
}

extension TezToolPair: Equatable {
	
	public static func == (lhs: TezToolPair, rhs: TezToolPair) -> Bool {
		return lhs.address == rhs.address
	}
}





public struct TezToolSide: Codable {
	
	public let symbol: String
	public let pool: TokenAmount
	public let price: Decimal
	public let tokenType: String?
}

extension TezToolSide: Hashable {
	
	/// Conforming to `Hashable` to enable working with UITableViewDiffableDataSource
	public func hash(into hasher: inout Hasher) {
		hasher.combine(symbol)
	}
}

extension TezToolSide: Equatable {
	
	public static func == (lhs: TezToolPair, rhs: TezToolPair) -> Bool {
		return lhs.symbol == rhs.symbol
	}
}
