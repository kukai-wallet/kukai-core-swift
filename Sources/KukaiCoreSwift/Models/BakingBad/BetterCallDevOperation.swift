//
//  BetterCallDevOperation.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 26/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

public struct BetterCallDevOperation: Codable {
	public let id: String
	public let hash: String
	public let counter: Int
	public let status: String
	public let errors: [BetterCallDevOperationError]?
	
	public func isFailed() -> Bool {
		return status.lowercased() == "failed" || status.lowercased() == "backtracked"
	}
	
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

public struct BetterCallDevOperationError: Codable {
	public let id: String
	public let title: String
	public let descr: String
	public let kind: String
	
	public let location: Int?
	public let with: String?
}
