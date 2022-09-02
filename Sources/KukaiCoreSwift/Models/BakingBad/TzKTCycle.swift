//
//  TzKTCycle.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

public struct TzKTCycle: Codable {
	
	private static let dateFormat = DateFormatter(withFormat: "yyyy-MM-dd'T'HH:mm:ssZ")
	
	let index: Int
	let startTime: String
	let endTime: String
	
	var stateDate: Date? {
		get {
			return TzKTCycle.dateFormat.date(from: startTime)
		}
	}
	
	var endDate: Date? {
		get {
			return TzKTCycle.dateFormat.date(from: endTime)
		}
	}
}
