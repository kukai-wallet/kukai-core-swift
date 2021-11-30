//
//  TezToolPair.swift
//  
//
//  Created by Simon Mcloughlin on 08/11/2021.
//

import Foundation

/// Enum to denote the available types of Dex's
public enum TezToolDex: String, Codable {
	case quipuswap = "Quipuswap"
	case liquidityBaking = "Liquidity Baking"
	case unknown
	
	public init(from decoder: Decoder) throws {
		self = try TezToolDex(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}


/// Representation of an available token pair to trade against on a given exchange
public struct TezToolPair: Codable, Hashable, Equatable {
	
	/// The KT address of the contract
	public let address: String
	
	/// The type of Dex
	public let dex: TezToolDex
	
	/// The two token symbols for user display purposes
	public let symbols: String
	
	/// Total liquidity token supply
	public let lptSupply: Decimal
	
	/// The two sides of the pair
	public let sides: [TezToolSide]
	
	/// Sides contains an array of objects providing details of each token available in the swap
	/// Apps will need to extract a list of the available tokens, easiest way to do that is to extract the side, that doesn't contain the base token (frequently XTZ)
	public func nonBaseTokenSide() -> TezToolSide? {
		for side in sides {
			if side.tokenType == nil {
				return side
			}
		}
		
		return nil
	}
	
	/// Fetch the base token of the swap (usually XTZ)
	public func baseTokenSide() -> TezToolSide? {
		for side in sides {
			if side.tokenType != nil {
				return side
			}
		}
		
		return nil
	}
	
	/// Convert the Liquidity supply decimal into a `TokenAmount`
	public func liquiditySupply(decimals: Int) -> TokenAmount {
		return TokenAmount(fromNormalisedAmount: lptSupply, decimalPlaces: decimals)
	}
	
	/// Helper to determine if the pools are empty, deciding whether or not adding liquidity needs to set the exchange rate
	public func arePoolsEmpty() -> Bool {
		let base = baseTokenSide()
		let nonBase = nonBaseTokenSide()
		
		return (base?.pool ?? 0) == 0 && (nonBase?.pool ?? 0) == 0
	}
	
	/// Conforming to `Hashable` to enable working with UITableViewDiffableDataSource
	public func hash(into hasher: inout Hasher) {
		hasher.combine(address)
		hasher.combine(dex.rawValue)
	}
	
	/// Conforming to `Equatable`
	public static func == (lhs: TezToolPair, rhs: TezToolPair) -> Bool {
		return lhs.address == rhs.address
	}
}


/// Representing a Token, used as one half of a token swap
public struct TezToolSide: Codable, Hashable, Equatable {
	
	/// The symbol of the token
	public let symbol: String
	
	/// The pool of this token available
	public let pool: Decimal
	
	/// The current price of this token (of the other side)
	public let price: Decimal
	
	/// Optional token type, used to distinguish "Base side"
	public let tokenType: String?
	
	/// Conforming to `Hashable` to enable working with UITableViewDiffableDataSource
	public func hash(into hasher: inout Hasher) {
		hasher.combine(symbol)
	}
	
	/// Conforming to `Equatable`
	public static func == (lhs: TezToolSide, rhs: TezToolSide) -> Bool {
		return lhs.symbol == rhs.symbol
	}
}
