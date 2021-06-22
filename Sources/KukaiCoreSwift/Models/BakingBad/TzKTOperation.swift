//
//  TzKTOperation.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 26/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

public struct TzKTOperation: Codable {
	public let type: String
	public let id: Int
	public let level: Int
	public let timestamp: String
	public let block: String
	public let hash: String
	public let counter: Int
	public let status: String
	public let errors: [TzKTOperationError]?
	
	public func isFailed() -> Bool {
		return status.lowercased() == "failed" || status.lowercased() == "backtracked" || status.lowercased() == "skipped"
	}
	
	public func containsError() -> Bool {
		return errors != nil && errors?.count ?? 0 > 0
	}
}

public struct TzKTOperationError: Codable {
	public let type: String
}
