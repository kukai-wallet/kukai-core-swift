//
//  Date+extensions.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

public extension Date {
	
	func timeAgoDisplay() -> String {
		let formatter = RelativeDateTimeFormatter()
		formatter.unitsStyle = .full
		
		return formatter.localizedString(for: self, relativeTo: Date())
	}
}
