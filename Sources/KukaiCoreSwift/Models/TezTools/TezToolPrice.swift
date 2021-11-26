//
//  TezToolPrice.swift
//  
//
//  Created by Simon Mcloughlin on 04/11/2021.
//

import Foundation

public struct TezToolPriceResponse: Codable {
	
	// There are some tokens that are malformed, that contain no crtical data (eg. decimals). Using SwiftBySundells property wrapper to tell swift to simply ignore these
	@LossyCodableList var contracts: [TezToolPrice]
}

public struct TezToolPrice: Codable {
	
	public let symbol: String
	public let tokenAddress: String
	public let tokenId: Int?
	public let decimals: Int
	public let address: String
	public let ratio: Decimal
	public let currentPrice: Decimal
	public let buyPrice: Decimal
	public let pairs: [TezToolPair]
	
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
	
	public static func == (lhs: TezToolPrice, rhs: TezToolPrice) -> Bool {
		return lhs.uniqueTokenAddress() == rhs.uniqueTokenAddress()
	}
}
