//
//  TzKTCycle.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

/// The blockchain is broken down into cycles that last 2.7 days. Baker payment logic resolves around cycles instead of blocks
public struct TzKTCycle: Codable {
	
	private static let dateFormat = DateFormatter(withFormat: "yyyy-MM-dd'T'HH:mm:ssZ")
	
	public let index: Int
	public let startTime: String
	public let firstLevel: Decimal
	public let endTime: String
	public let lastLevel: Decimal
	
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
