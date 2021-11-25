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
	public let exchange: DipDupExchange
	
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
