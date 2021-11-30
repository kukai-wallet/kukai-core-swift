//
//  TezToolPrice.swift
//  
//
//  Created by Simon Mcloughlin on 04/11/2021.
//

import Foundation

/// Network response wrapper
public struct TezToolPriceResponse: Codable {
	
	/// There are some tokens that are malformed, that contain no critical data (eg. decimals). Using SwiftBySundells property wrapper to tell swift to simply ignore these
	@LossyCodableList var contracts: [TezToolPrice]
}

/// All the pricing information available on TezTools for the given token
public struct TezToolPrice: Codable {
	
	/// The token symbol
	public let symbol: String
	
	/// The TZ address of the token
	public let tokenAddress: String
	
	/// Optional FA2 token id
	public let tokenId: Int?
	
	/// The number of decimals the token uses
	public let decimals: Int
	
	/// An Address of an Exchange, seems to always default to Quipuswap
	public let address: String
	
	/// Trade ratio
	public let ratio: Decimal
	
	/// The current price of the non base token
	public let currentPrice: Decimal
	
	/// The cost to purchase the non base token
	public let buyPrice: Decimal
	
	/// The available pairs in this contract
	public let pairs: [TezToolPair]
	
	/// Combine the token address and token id to create a unique id
	public func uniqueTokenAddress() -> String {
		if let id = tokenId {
			return "\(tokenAddress):\(id)"
		}
		
		return tokenAddress
	}
}

extension TezToolPrice: Hashable {
	
	/// Conforming to `Hashable` to enable working with UITableViewDiffableDataSource
	public func hash(into hasher: inout Hasher) {
		hasher.combine(uniqueTokenAddress())
	}
}

extension TezToolPrice: Equatable {
	
	/// Conforming to `Equatable`
	public static func == (lhs: TezToolPrice, rhs: TezToolPrice) -> Bool {
		return lhs.uniqueTokenAddress() == rhs.uniqueTokenAddress()
	}
}
