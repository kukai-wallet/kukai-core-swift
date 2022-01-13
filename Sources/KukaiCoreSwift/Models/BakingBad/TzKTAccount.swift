//
//  TzKTAccount.swift
//  
//
//  Created by Simon Mcloughlin on 13/01/2022.
//

import Foundation

public struct TzKTAccount: Codable {
	public let balance: Decimal
	
	public var xtzBalance: XTZAmount {
		return XTZAmount(fromRpcAmount: balance) ?? .zero()
	}
}
