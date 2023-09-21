//
//  DipDupPosition.swift
//  
//
//  Created by Simon Mcloughlin on 15/11/2021.
//

import Foundation

/// Wrapper object to match network response type
public struct DipDupPosition: Codable {
	public let position: [DipDupPositionData]
}

/// A position on DipDup corresponds to liquidity token ownership. Each of these objects represents an amount of Liquidity tokens in an exchange for the given address
public struct DipDupPositionData: Codable, Hashable, Equatable {
	
	/// The liquidity token balance (rpc representation)
	public let sharesQty: String
	
	/// The exchange the token belongs too
	public let exchange: DipDupExchange
	
	
	/// Convert the token data into a `TokenAmount`
	public func tokenAmount() -> TokenAmount {
		return TokenAmount(fromRpcAmount: sharesQty, decimalPlaces: exchange.liquidityTokenDecimalPlaces()) ?? TokenAmount.zero()
	}
	
	/// Conforming to `Hashable` to enable working with UITableViewDiffableDataSource
	public func hash(into hasher: inout Hasher) {
		hasher.combine(exchange.name)
		hasher.combine(exchange.token.address)
	}
	
	/// Conforming to `Equatable` to enable working with UITableViewDiffableDataSource
	public static func == (lhs: DipDupPositionData, rhs: DipDupPositionData) -> Bool {
		return lhs.exchange.name == rhs.exchange.name && lhs.exchange.token.address == rhs.exchange.token.address
	}
}
