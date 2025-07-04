//
//  NetworkConstants.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 26/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// The contants that a given Tezos node is using for block times, blakc size etc
public struct NetworkConstants: Codable {
	public let minimal_block_delay: String
	public let hard_gas_limit_per_operation: String
	public let hard_gas_limit_per_block: String
	public let origination_size: Int
	public let cost_per_byte: String
	public let hard_storage_limit_per_operation: String
	public let blocks_per_cycle: Int
	public let unstake_finalization_delay: Int
	
	public func secondsBetweenBlocks() -> Int {
		return Int(minimal_block_delay) ?? 8
	}
	
	public func mutezPerByte() -> Int {
		return Int(cost_per_byte) ?? 250
	}
	
	public func xtzPerByte() -> XTZAmount {
		return XTZAmount(fromRpcAmount: cost_per_byte) ?? XTZAmount(fromNormalisedAmount: 0.000250)
	}
	
	public func maxGasPerOperation() -> Int {
		return Int(hard_gas_limit_per_operation) ?? 1040000
	}
	
	public func maxGasPerBlock() -> Int {
		return Int(hard_gas_limit_per_block) ?? 1386666
	}
	
	public func maxStoragePerOperation() -> Int {
		return Int(hard_storage_limit_per_operation) ?? 60000
	}
	
	public func bytesForReveal() -> Int {
		return origination_size
	}
	
	public func xtzForReveal() -> XTZAmount {
		return xtzPerByte() * bytesForReveal()
	}
}
