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
	
	mutating func remove(elementsAtIndices indicesToRemove: Set<Int>) -> [Element] {
		return self.remove(elementsAtIndices: Array<Int>(indicesToRemove))
	}
	
	mutating func remove(elementsAtIndices indicesToRemove: [Int]) -> [Element] {
		guard !indicesToRemove.isEmpty else {
			return []
		}
		
		// Copy the removed elements in the specified order.
		let removedElements = indicesToRemove.map { self[$0] }
		
		// Sort the indices to remove.
		let indicesToRemove = indicesToRemove.sorted()
		
		// Shift the elements we want to keep to the left.
		var destIndex = indicesToRemove.first!
		var srcIndex = destIndex + 1
		func shiftLeft(untilIndex index: Int) {
			while srcIndex < index {
				self[destIndex] = self[srcIndex]
				destIndex += 1
				srcIndex += 1
			}
			srcIndex += 1
		}
		for removeIndex in indicesToRemove[1...] {
			shiftLeft(untilIndex: removeIndex)
		}
		shiftLeft(untilIndex: self.endIndex)
		
		// Remove the extra elements from the end of the array.
		self.removeLast(indicesToRemove.count)
		
		return removedElements
	}
}
