//
//  TezToolPrice.swift
//  
//
//  Created by Simon Mcloughlin on 04/11/2021.
//

import Foundation

public struct TezToolPriceResponse: Codable {
	
	// There are some tokens that are malformed, that contain no crtical data (eg. decimals). Using SwiftBySundells property wrapper to tell swift to simply ignore these
	@LossyCodableList var contracts: [TezToolPrice]
}

public struct TezToolPrice: Codable {
	
	let symbol: String
	let tokenAddress: String
	let decimals: Int
	let address: String
	let ratio: Decimal
	let currentPrice: Decimal
	let buyPrice: XTZAmount
	let pairs: [TezToolPair]
}
