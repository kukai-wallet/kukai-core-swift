//
//  TezToolToken.swift
//  
//
//  Created by Simon Mcloughlin on 04/11/2021.
//

import Foundation

public struct TezToolTokenResponse: Codable {
	
	// There are some tokens that are malformed, that contain no crtical data (eg. decimals). Using SwiftBySundells property wrapper to tell swift to simply ignore these
	@LossyCodableList var contracts: [TezToolToken]
}

public struct TezToolToken: Codable {
	
	let symbol: String?
	let tokenAddress: String
	let name: String?
	let tokenId: Int?
	let address: String
	var decimals: Int
	let apps: [TezToolApp]
	let websiteLink: String?
	let telegramLink: String?
	let twitterLink: String?
	let discordLink: String?
	let thumbnailUri: String?
}
