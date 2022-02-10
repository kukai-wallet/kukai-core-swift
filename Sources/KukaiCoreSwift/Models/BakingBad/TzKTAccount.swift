//
//  TzKTAccount.swift
//  
//
//  Created by Simon Mcloughlin on 13/01/2022.
//

import Foundation

public struct TzKTAccount: Codable {
	public let balance: Decimal?
	public let delegate: TzKTAccountDelegate?
	
	public var xtzBalance: XTZAmount {
		return XTZAmount(fromRpcAmount: balance ?? 0) ?? .zero()
	}
}

public struct TzKTAccountDelegate: Codable {
	public let alias: String?
	public let address: String
	public let active: Bool
}
