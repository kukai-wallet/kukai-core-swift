//
//  DipDupChartData.swift
//  
//
//  Created by Simon Mcloughlin on 04/03/2022.
//

import Foundation

/// Struct to hold 4 arrays of data, each one mapping to a different timeline of data, to allow the display of graphs
public struct DipDupChartData: Codable {
	
	/// Contains the last 24 hours of data at 15 min intervals
	public let quotes15mNogaps: [DipDupChartObject]
	
	/// Contains every hour for past 7 days
	public let quotes1hNogaps: [DipDupChartObject]
	
	/// Contains every day for 30 days
	public let quotes1dNogaps: [DipDupChartObject]
	
	/// Contains every week for 52 weeks
	public let quotes1wNogaps: [DipDupChartObject]
}

/// Structure holding a data slice
public struct DipDupChartObject: Codable {
	
	/// The average price at the given time
	public let average: Decimal
	
	/// The address of the contract
	public let exchangeId: String
	
	/// String representing the date and time the slice is for
	public let bucket: String
	
	/// The highest value reached in this slice
	public let high: String
	
	/// The lowest value reached in this slice
	public let low: String
	
	/// Convert the `bucket` string into a `Date` object
	func date() -> Date? {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		
		return dateFormatter.date(from: bucket)
	}
	
	/// Convert the `average` value into a `Double`
	public func averageDouble() -> Double {
		return (average as NSDecimalNumber).doubleValue
	}
	
	/// Convert the `high` value into a `Double`
	public func highDouble() -> Double {
		return Double(high) ?? 0
	}
	
	/// Convert the `low` value into a `Double`
	public func lowDouble() -> Double {
		return Double(low) ?? 0
	}
}
