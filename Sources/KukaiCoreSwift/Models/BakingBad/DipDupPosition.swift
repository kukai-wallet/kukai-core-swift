//
//  DipDupPosition.swift
//  
//
//  Created by Simon Mcloughlin on 15/11/2021.
//

import Foundation

public struct DipDupPosition: Codable {
	public let position: [DipDupPositionData]
}

public struct DipDupPositionData: Codable, Hashable, Equatable {
	public let sharesQty: String
	public let token: DipDupToken
	public let exchange: DipDupExchange
	
	public func tokenAmount() -> TokenAmount {
		return TokenAmount(fromRpcAmount: sharesQty, decimalPlaces: token.decimals) ?? TokenAmount.zero()
	}
	
	/// Conforming to `Hashable` to enable working with UITableViewDiffableDataSource
	public func hash(into hasher: inout Hasher) {
		hasher.combine(exchange.name)
		hasher.combine(token.address)
	}
	
	/// Conforming to `Equatable` to enable working with UITableViewDiffableDataSource
	public static func == (lhs: DipDupPositionData, rhs: DipDupPositionData) -> Bool {
		return lhs.exchange.name == rhs.exchange.name && lhs.token.address == rhs.token.address
	}
}

public struct DipDupToken: Codable {
	public let symbol: String
	public let address: String
	public let decimals: Int
}

public enum DipDupExchangeName: String, Codable {
	case quipuswap
	case lb
	case unknown
	
	public init(from decoder: Decoder) throws {
		self = try DipDupExchangeName(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

public struct DipDupExchange: Codable {
	public let name: DipDupExchangeName
	public let tezPool: String
	public let tokenPool: String
	public let sharesTotal: String
	
	public func xtzPool() -> XTZAmount {
		return XTZAmount(fromNormalisedAmount: tezPool, decimalPlaces: 6) ?? XTZAmount.zero()
	}
	
	public func tokenPool(decimals: Int) -> TokenAmount {
		return TokenAmount(fromNormalisedAmount: tokenPool, decimalPlaces: decimals) ?? TokenAmount.zero()
	}
	
	public func totalLiquidity(decimals: Int) -> TokenAmount {
		return TokenAmount(fromNormalisedAmount: sharesTotal, decimalPlaces: decimals) ?? TokenAmount.zero()
	}
}
