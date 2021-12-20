//
//  RequestIfService.swift
//  
//
//  Created by Simon Mcloughlin on 16/12/2021.
//

import Foundation

public struct RequestIfStorage<T: Codable> {
	let lastRequestedDate: Date
	let data: T
}

public class RequestIfService {
	
	public struct Interval {
		public static let minute: TimeInterval = 60
		public static let halfhour: TimeInterval = 1800
		public static let hour: TimeInterval = 3600
		public static let day: TimeInterval = 86400
		public static let week: TimeInterval = 604800
	}
	
	/// A completion block defintion that passes in any codable type as a parameter
	public typealias RequestIfServiceCompletion<T: Codable> = ((Bool, Result<T, ErrorResponse>?) -> Void)
	
	/*
	public static func request<T: Codable>(_ request: URLRequest, ifIntervalHasPassed: TimeInterval, forKey: String, withReturnType: T.Type) {
		
	}
	*/
	
	
	/**
	 A function that takes in a block to execute, if a given time interval has passed since the last time it was executed. A unqiue key for each block must be supplied, this will be used to store a date object to compare against.
	 If sufficient time has passed since the last call, the block will be called, and a compeltion block passed into it. It is the blcoks responsiblity to then call the completion block.
	 If insufficient time has passed since the last call, the completion block will be fired with the boolean set to `false` and the value set to nil.
	 */
	public static func runBlock(_ block: @escaping (( ) -> Void), ifIntervalHasPassed: TimeInterval, forKey: String) -> Bool {
		// check for key / time
		
		// if needs to be executed
		block()
		
		return true
	}
}
