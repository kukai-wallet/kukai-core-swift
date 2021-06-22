//
//  Data+extensions.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 21/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// Data extension to handle storage and manipulation of `[UInt8]`
public extension Data {
	
	var bytes: Array<UInt8> {
		Array(self)
	}
	
	func toHexString() -> String {
		self.bytes.toHexString()
	}
}
