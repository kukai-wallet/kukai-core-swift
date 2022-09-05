//
//  TzKTAccount.swift
//  
//
//  Created by Simon Mcloughlin on 13/01/2022.
//

import Foundation

/// Model mapping to TzKT.io's Account object
public struct TzKTAccount: Codable, Equatable {
	
	/// The address XTZ balance in RPC format
	public let balance: Decimal?
	
	/// The addresses delegation status
	public let delegate: TzKTAccountDelegate?
	
	/// The block level the delegate address was set
	public let delegationLevel: Decimal?
	
	/// Helper method to convert the RPC balance into an XTZAmount
	public var xtzBalance: XTZAmount {
		return XTZAmount(fromRpcAmount: balance ?? 0) ?? .zero()
	}
}

/// Model mapping to TzKT.io's Account.Delegate Object
public struct TzKTAccountDelegate: Codable, Equatable {
	
	/// Bakers may have an alias (human readbale) name for their service
	public let alias: String?
	
	/// Bakers must have a valid address
	public let address: String
	
	/// Bool indicating whether or not the baker is currently active
	public let active: Bool
	
	public init(alias: String?, address: String, active: Bool) {
		self.alias = alias
		self.address = address
		self.active = active
	}
}
