//
//  DipDupExchange.swift
//  
//
//  Created by Simon Mcloughlin on 25/11/2021.
//

import Foundation

/// Wrapper object to map to network response type
public struct DipDupExchangesAndTokensResponse: Codable {
	
	public let token: [DipDupExchangesAndTokens]
}

/// Wrapper object to map to network response type
public struct DipDupExchangesAndTokens: Codable {
	
	public let symbol: String
	public let address: String
	public let tokenId: Decimal
	public let decimals: Int
	public let thumbnailUri: String?
	public let exchanges: [DipDupExchange]
	
	/// Get the total XTZ pool amount from all the exchanges, useful for sorting
	public func totalExchangeXtzPool() -> XTZAmount {
		return exchanges.map({ $0.xtzPoolAmount() }).reduce(.zero(), +)
	}
}

/// A DipDup Exchange object with all the necessary pieces for checking liquidity and performing Swaps
public struct DipDupExchange: Codable, Hashable, Equatable {
	
	/// Enum to denote the type of Exchange (e.g. Liquidity Baking, Quipuswap)
	public let name: DipDupExchangeName
	
	/// The KT address of the exchange contract
	public let address: String
	
	/// String representation of the Exchanges TezPool
	public let tezPool: String
	
	/// String representation of the Exchanges TokenPool
	public let tokenPool: String
	
	/// The total liquidity available (RPC representation, no decimals)
	public let sharesTotal: String
	
	/// The daily middle price
	public let midPrice: String
	
	/// The token object containing all the token info (decimals, contract address, symbol etc,)
	public let token: DipDupToken
	
	
	
	// MARK: - Helper functions
	
	/// Return the XTZ pool as an `XTZAmount` object
	public func xtzPoolAmount() -> XTZAmount {
		return XTZAmount(fromNormalisedAmount: tezPool, decimalPlaces: 6) ?? XTZAmount.zero()
	}
	
	/// Return the Token pool as an `TokenAmount` object
	public func tokenPoolAmount() -> TokenAmount {
		return TokenAmount(fromNormalisedAmount: tokenPool, decimalPlaces: token.decimals) ?? TokenAmount.zero()
	}
	
	/// Retrieving the liquidity token decimals is currently not supported. Hardcode the numbers for now
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
	
	/// Return the total liquidity as an `TokenAmount` object
	public func totalLiquidity() -> TokenAmount {
		return TokenAmount(fromRpcAmount: sharesTotal, decimalPlaces: liquidityTokenDecimalPlaces()) ?? TokenAmount.zero()
	}
	
	/// Helper to detect if the pools are empty (determiens if the next addLiquidity will be setting the exchange rate)
	public func arePoolsEmpty() -> Bool {
		return (xtzPoolAmount() == XTZAmount.zero()) && (tokenPoolAmount() == TokenAmount.zero())
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

/// Enum to wrap up the available types of Exchange on DipDup
public enum DipDupExchangeName: String, Codable {
	case quipuswap
	case lb
	case unknown
	
	public init(from decoder: Decoder) throws {
		self = try DipDupExchangeName(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}
