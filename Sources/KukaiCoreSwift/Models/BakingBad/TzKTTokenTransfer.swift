//
//  TzKTTokenTransfer.swift
//  
//
//  Created by Simon Mcloughlin on 22/03/2023.
//

import Foundation

/// FA1.2 / FA2 token transafers are treated differently from transactions. This object is used when fetching data form the API, as a temporary placeholder, ultimately to be merged into the transactions
public struct TzKTTokenTransfer: Codable {
	public let id: Decimal
	public var hash: String? // Doesn't come from API, but needed later, added during grouping / conversion phase
	public let level: Decimal
	public let timestamp: String
	public let token: TzKTBalanceToken
	public let to: TzKTAddress?
	public let from: TzKTAddress?
	public let amount: String
	public let transactionId: Decimal?
	public let originationId: Decimal?
	public let mintingTool: String?
	
	public func tokenAmount() -> TokenAmount {
		return TokenAmount(fromRpcAmount: amount, decimalPlaces: token.metadata?.decimalsInt ?? 0) ?? .zero()
	}
}
