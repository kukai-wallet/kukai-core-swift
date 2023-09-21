//
//  Array+extensions.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 21/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// Array extension to handle storage and manipulation of `[UInt8]`
extension Array {
	
	init(reserveCapacity: Int) {
		self = Array<Element>()
		self.reserveCapacity(reserveCapacity)
	}
	
	var slice: ArraySlice<Element> {
		self[self.startIndex ..< self.endIndex]
	}
}
