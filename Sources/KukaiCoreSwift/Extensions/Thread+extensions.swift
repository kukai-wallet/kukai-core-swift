//
//  File.swift
//  
//
//  Created by Simon Mcloughlin on 12/07/2021.
//

import Foundation

public extension Thread {
	
	var isRunningXCTest: Bool {
		for key in self.threadDictionary.allKeys {
			guard let keyAsString = key as? String else {
				continue
			}
			
			if keyAsString.split(separator: ".").contains("xctest") {
				return true
			}
		}
		return false
	}
}
