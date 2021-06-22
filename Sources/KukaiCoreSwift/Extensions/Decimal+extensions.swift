//
//  Decimal+extensions.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 19/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

public extension Decimal {
	
	/// Wrapper around the Objective-c code needed to round a `Decimal`
	func rounded(scale: Int, roundingMode: NSDecimalNumber.RoundingMode) -> Decimal {
		var mutableSelf = self
		var rounded = Decimal(0)
		
		NSDecimalRound(&rounded, &mutableSelf, scale, roundingMode)
		
		return rounded
	}
}
