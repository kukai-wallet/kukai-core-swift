//
//  DefiToken.swift
//  
//
//  Created by Simon Mcloughlin on 08/11/2021.
//

import Foundation

/// Custom Object to mash together a TezTools price object and token object, to make integration easier
public struct DefiToken: Codable {
	
	/// The underlying Token object returned from the network
	public let token: TezToolToken
	
	/// The underlying Price object returned from the network
	public let price: TezToolPrice
	
	/// Create an instance from a Token and Price
	public init(withToken: TezToolToken, andPrice: TezToolPrice) {
		token = withToken
		price = andPrice
	}
	
	/// Create an instance with an empty price
	public init(withToken: TezToolToken) {
		token = withToken
		price = TezToolPrice(symbol: token.symbol ?? "", tokenAddress: token.tokenAddress, tokenId: withToken.tokenId, decimals: token.decimals, address: token.address, ratio: 0, currentPrice: 0, buyPrice: 0, pairs: [])
	}
}

extension DefiToken: Hashable {
	
	/// Conforming to `Hashable` to enable working with UITableViewDiffableDataSource
	public func hash(into hasher: inout Hasher) {
		hasher.combine(token.tokenAddress)
		hasher.combine(price.buyPrice)
	}
}

extension DefiToken: Equatable {
	
	/// Conforming to `Equatable`
	public static func == (lhs: DefiToken, rhs: DefiToken) -> Bool {
		return lhs.token.tokenAddress == rhs.token.tokenAddress
	}
}
