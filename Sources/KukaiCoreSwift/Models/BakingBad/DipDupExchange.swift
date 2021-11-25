//
//  DipDupExchange.swift
//  
//
//  Created by Simon Mcloughlin on 25/11/2021.
//

import Foundation

public struct DipDupExchangesAndTokensResponse: Codable {
	
	public let token: [DipDupExchangesAndTokens]
}

public struct DipDupExchangesAndTokens: Codable {
	
	public let symbol: String
	public let exchanges: [DipDupExchange]
}

public struct DipDupExchange: Codable, Hashable, Equatable {
	
	public let name: DipDupExchangeName
	public let address: String
	public let tezPool: String
	public let tokenPool: String
	public let sharesTotal: String
	public let midPrice: String
	public let token: DipDupToken
	
	public func xtzPoolAmount() -> XTZAmount {
		return XTZAmount(fromNormalisedAmount: tezPool, decimalPlaces: 6) ?? XTZAmount.zero()
	}
	
	public func tokenPoolAmount() -> TokenAmount {
		return TokenAmount(fromNormalisedAmount: tokenPool, decimalPlaces: token.decimals) ?? TokenAmount.zero()
	}
	
	public func liquidityTokenDecimalPlaces() -> Int {
		switch name {
			case .quipuswap:
				return 6
				
			case .lb:
				return 0
				
			case .unknown:
				return 6
		}
	}
	
	public func totalLiquidity() -> TokenAmount {
		return TokenAmount(fromRpcAmount: sharesTotal, decimalPlaces: liquidityTokenDecimalPlaces()) ?? TokenAmount.zero()
	}
	
	public func arePoolsEmpty() -> Bool {
		return (xtzPoolAmount > .zero) && (tokenPoolAmount > .zero)
	}
	
	/// Conforming to `Hashable` to enable working with UITableViewDiffableDataSource
	public func hash(into hasher: inout Hasher) {
		hasher.combine(address)
		hasher.combine(token.address)
		hasher.combine(token.tokenId)
	}
	
	/// Conforming to `Equatable` to enable working with UITableViewDiffableDataSource
	public static func == (lhs: DipDupExchange, rhs: DipDupExchange) -> Bool {
		return lhs.address == rhs.address && lhs.token.address == rhs.token.address && lhs.token.tokenId == rhs.token.tokenId
	}
}

public enum DipDupExchangeName: String, Codable {
	case quipuswap
	case lb
	case unknown
	
	public init(from decoder: Decoder) throws {
		self = try DipDupExchangeName(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}
