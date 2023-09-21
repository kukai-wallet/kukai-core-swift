//
//  Error+extensions.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 26/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// Exposing underlying NSError properties not accessible to Swift Error without casting
public extension Error {
	
	/// Access NSError.code
	var code: Int {
		return (self as NSError).code
	}
	
	/// Access NSError.domain
	var domain: String {
		return (self as NSError).domain
	}
	
	/// Access NSError.userInfo
	var userInfo: [String: Any] {
		return (self as NSError).userInfo
	}
	
	/// Access NSError.userInfo[NSUnderlyingErrorKey] and cast to swift Error
	var underlyingError: NSError? {
		return (self as NSError).userInfo[NSUnderlyingErrorKey] as? NSError
	}
}
