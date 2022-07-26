//
//  Michelson.swift
//  
//
//  Created by Simon Mcloughlin on 26/07/2022.
//

import Foundation

/// Helper methods for extracting data from Michelson JSON, to reduce the amount of `as? [String: Any]` extracting, and instead use some of the standarad naming
public extension Dictionary where Key == String {
	
	func michelsonValue() -> [String: Any]? {
		return self["value"] as? [String: Any]
	}
	
	func michelsonValueArray() -> [[String: Any]]? {
		return self["value"] as? [[String: Any]]
	}
	
	func michelsonArgsArray() -> [[String: Any]]? {
		return self["args"] as? [[String: Any]]
	}
	
	func michelsonArgsUnknownArray() -> [Any]? {
		return self["args"] as? [Any]
	}
}

/// Helper methods for extracting data from Michelson JSON, to reduce the amount of `as? [String: Any]` extracting, and instead use some of the standarad naming
public extension Array where Element == [String: Any] {
	
	func michelsonInt(atIndex index: Int) -> String? {
		guard index < self.count else { return nil }
		return self[index]["int"] as? String
	}
	
	func michelsonString(atIndex index: Int) -> String? {
		guard index < self.count else { return nil }
		return self[index]["string"] as? String
	}
	
	func michelsonPair(atIndex index: Int) -> [String: Any]? {
		guard index < self.count else { return nil }
		return self[index]
	}
}

/// Helper methods for extracting data from Michelson JSON, to reduce the amount of `as? [String: Any]` extracting, and instead use some of the standarad naming
public extension Array where Element == Any {
	
	func michelsonInt(atIndex index: Int) -> String? {
		guard index < self.count else { return nil }
		return (self[index] as? [String: Any])?["int"] as? String
	}
	
	func michelsonString(atIndex index: Int) -> String? {
		guard index < self.count else { return nil }
		return (self[index] as? [String: Any])?["string"] as? String
	}
	
	func michelsonPair(atIndex index: Int) -> [String: Any]? {
		guard index < self.count else { return nil }
		return self[index] as? [String: Any]
	}
	
	func michelsonArray(atIndex index: Int) -> [Any]? {
		guard index < self.count else { return nil }
		return self[index] as? [Any]
	}
}
