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
	
	public let symbol: String?
	public let tokenAddress: String
	public let name: String?
	public let tokenId: Int?
	public let address: String
	public let decimals: Int
	public let apps: [TezToolApp]
	public let websiteLink: String?
	public let telegramLink: String?
	public let twitterLink: String?
	public let discordLink: String?
	public let thumbnailUri: String?
}
