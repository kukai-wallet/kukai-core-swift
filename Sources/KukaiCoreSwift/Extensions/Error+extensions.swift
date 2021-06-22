//
//  Error+extensions.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 26/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

extension Error {
	var code: Int {
		return (self as NSError).code
	}
	
	var domain: String {
		return (self as NSError).domain
	}
	
	var userInfo: [String: Any] {
		return (self as NSError).userInfo
	}
	
	var underlyingError: NSError? {
		return (self as NSError).userInfo[NSUnderlyingErrorKey] as? NSError
	}
}
