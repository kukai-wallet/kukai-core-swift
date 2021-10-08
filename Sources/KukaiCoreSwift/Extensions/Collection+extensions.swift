//
//  Collection+extensions.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 26/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import Combine

extension Collection {
	
	/// Returns the element at the specified index if it is within bounds, otherwise nil.
	subscript (safe index: Index) -> Element? {
		return indices.contains(index) ? self[index] : nil
	}
}

extension Collection where Element: Publisher {
	
	/// Convert an array of publishers into a concatenation, so that they will all run sequentually. Code from: https://www.apeth.com/UnderstandingCombine/operators/operatorsJoiners/operatorsappend.html
	func serialize() -> AnyPublisher<Element.Output, Element.Failure>? {
		guard let start = self.first else { return nil }
		return self.dropFirst().reduce(start.eraseToAnyPublisher()) {
			$0.append($1)
			.eraseToAnyPublisher()
		}
	}
}
