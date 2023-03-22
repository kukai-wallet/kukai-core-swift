//
//  TzKTTokenTransfer.swift
//  
//
//  Created by Simon Mcloughlin on 22/03/2023.
//

import Foundation

public struct TzKTTokenTransfer: Codable {
	public let id: Decimal
	public let level: Decimal
	public let timestamp: String
	public let token: TzKTBalanceToken
	public let to: TzKTAddress?
	public let from: TzKTAddress?
	public let amount: TokenAmount
	public let transactionId: Decimal
}
