//
//  TzKTStakingUpdate.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 22/11/2024.
//

import Foundation

/// A model matching the response that comes back from TzKT's API: `v1/staking/updates`
public struct TzKTStakingUpdate: Codable {
	
	/// Block level
	public let level: Decimal
	
	/// Cycle that the operation was submitted
	public let cycle: Int
	
	/// The baker delegated too at the time
	public let baker: TzKTAddress
	
	/// The stake that prefromed it
	public let staker: TzKTAddress
	
	/// Type of event (stake, unstake)
	public let type: String
	
	/// RPC value of the XTZ amount
	public let amount: Decimal
	
	/// Helper to return XTZAmount of the `amount` property
	public var xtzAmount: XTZAmount {
		get {
			return XTZAmount(fromRpcAmount: amount) ?? .zero()
		}
	}
}
