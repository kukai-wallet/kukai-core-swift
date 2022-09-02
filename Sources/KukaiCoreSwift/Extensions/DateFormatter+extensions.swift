//
//  DateFormatter+extensions.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

public extension DateFormatter {
	
	convenience init(withFormat: String) {
		self.init()
		self.dateFormat = withFormat
	}
}
