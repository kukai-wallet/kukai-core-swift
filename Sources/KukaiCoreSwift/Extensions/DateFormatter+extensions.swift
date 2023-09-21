//
//  DateFormatter+extensions.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

public extension DateFormatter {
	
	/// Helper to create a DateFormatter with a format in 1 call
	convenience init(withFormat: String) {
		self.init()
		self.dateFormat = withFormat
	}
}
