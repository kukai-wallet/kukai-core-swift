//
//  Date+extensions.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

public extension Date {
	
	/// Helper to return strings like "15 seconds ago", "1 minute ago" etc, from a Date
	func timeAgoDisplay() -> String {
		let formatter = RelativeDateTimeFormatter()
		formatter.unitsStyle = .full
		
		return formatter.localizedString(for: self, relativeTo: Date())
	}
}
