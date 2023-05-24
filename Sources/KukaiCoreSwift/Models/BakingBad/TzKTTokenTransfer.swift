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
	public let amount: String
	public let transactionId: Decimal
	public let mintingTool: String?
	
	public func tokenAmount() -> TokenAmount {
		return TokenAmount(fromRpcAmount: amount, decimalPlaces: token.metadata?.decimalsInt ?? 0) ?? .zero()
	}
}
