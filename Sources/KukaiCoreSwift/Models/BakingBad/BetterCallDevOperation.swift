//
//  BetterCallDevOperation.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 26/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// A model matching the response that comes back from BetterCallDev's API: `v1/opg/<operation-hash>`
public struct BetterCallDevOperation: Codable {
	
	/// An ID used by BCD
	public let id: Int
	
	/// The operation hash
	public let hash: String
	
	/// The operations numeric counter
	public let counter: Int
	
	/// Indicating if the operation was successful, failed, backtracked etc.
	public let status: String
	
	/// Detailed error objects, also including unique smart contract errors
	public let errors: [BetterCallDevOperationError]?
	
	
	/// Helper to determine if the operation failed or not
	public func isFailed() -> Bool {
		return status.lowercased() == "failed" || status.lowercased() == "backtracked"
	}
	
	
	/// Helper to check for existance of errors
	public func containsError() -> Bool {
		return errors != nil && errors?.count ?? 0 > 0
	}
	
	/**
	When looking for more detailed errors through Better-Call.dev, effectively we are looking for an error containing a `location` and/or a `with`.
	We already have the other bits, but only location and with can identify the specific Dexter error
	*/
	public func moreDetailedError() -> BetterCallDevOperationError? {
		guard let errs = errors else {
			return nil
		}
		
		for error in errs {
			if error.location != nil || error.with != nil {
				return error
			}
		}
		
		return nil
	}
}

/// BetterCallDev structure for errors
public struct BetterCallDevOperationError: Codable {
	public let id: String
	public let title: String
	public let descr: String
	public let kind: String
	
	public let location: Int?
	public let with: String?
}
