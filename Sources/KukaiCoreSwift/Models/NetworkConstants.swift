//
//  NetworkConstants.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 26/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

public struct NetworkConstants: Codable {
	public let time_between_blocks: [String]
	public let hard_gas_limit_per_operation: String
	public let hard_gas_limit_per_block: String
	public let origination_size: Int
	public let cost_per_byte: String
	public let hard_storage_limit_per_operation: String
	
	public func secondsBetweenBlocks() -> Int {
		return Int(time_between_blocks[0]) ?? 60
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
