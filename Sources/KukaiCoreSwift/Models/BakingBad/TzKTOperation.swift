//
//  TzKTOperation.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 26/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// A model matching the response that comes back from TzKT's API: `v1/operations/<operation-hash>`
public struct TzKTOperation: Codable {
	
	/// Type of operation (e.g. transaction, delegation, reveal etc)
	public let type: String
	
	/// Unique id to denote the operation
	public let id: Int
	
	/// The block level it was injected at
	public let level: Int
	
	/// Timestamp it was injected at
	public let timestamp: String
	
	/// The hash of the injected block
	public let block: String
	
	/// The operation hash
	public let hash: String
	
	/// The users numerical counter of the operation
	public let counter: Int
	
	/// Status of the operation (e.g. applied or failed)
	public let status: String
	
	/// Optional array of errors encountered while trying to inject the operation
	public let errors: [TzKTOperationError]?
	
	/// Helper to detect a failed transation by searching for a status of "failed", "backtracked" or "skipped"
	public func isFailed() -> Bool {
		return status.lowercased() == "failed" || status.lowercased() == "backtracked" || status.lowercased() == "skipped"
	}
	
	/// Helper to detect if this operation contains an error
	public func containsError() -> Bool {
		return errors != nil && errors?.count ?? 0 > 0
	}
}

/// TzKT's more basic error object response
public struct TzKTOperationError: Codable {
	
	/// The RPC error type string
	public let type: String
}
