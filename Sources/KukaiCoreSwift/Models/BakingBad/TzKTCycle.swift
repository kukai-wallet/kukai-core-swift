//
//  TzKTCycle.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

public struct TzKTCycle: Codable {
	
	private static let dateFormat = DateFormatter(withFormat: "yyyy-MM-dd'T'HH:mm:ssZ")
	
	public let index: Int
	public let startTime: String
	public let endTime: String
	
	public var stateDate: Date? {
		get {
			return TzKTCycle.dateFormat.date(from: startTime)
		}
	}
	
	public var endDate: Date? {
		get {
			return TzKTCycle.dateFormat.date(from: endTime)
		}
	}
}
