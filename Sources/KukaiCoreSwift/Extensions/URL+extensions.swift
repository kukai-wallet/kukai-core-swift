//
//  URL+extensions.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 01/02/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// Extensions to make adding query items easier
extension URL {
	
	mutating func appendQueryItem(name: String, value: String?) {
		
		guard var urlComponents = URLComponents(string: absoluteString) else { return }
		
		// Create array of existing query items
		var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []
		
		// Create query item
		let queryItem = URLQueryItem(name: name, value: value)
		
		// Append the new query item in the existing query items array
		queryItems.append(queryItem)
		
		// Append updated query items array in the url component object
		urlComponents.queryItems = queryItems
		
		// Returns the url from new url components
		self = urlComponents.url!
	}
	
	mutating func appendQueryItem(name: String, value: Int) {
		self.appendQueryItem(name: name, value: value.description)
	}
}
