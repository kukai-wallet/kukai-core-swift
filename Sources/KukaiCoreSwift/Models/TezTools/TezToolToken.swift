//
//  TezToolToken.swift
//  
//
//  Created by Simon Mcloughlin on 04/11/2021.
//

import Foundation

/// Network response wrapper
public struct TezToolTokenResponse: Codable {
	
	/// There are some tokens that are malformed, that contain no crtical data (eg. decimals). Using SwiftBySundells property wrapper to tell swift to simply ignore these
	@LossyCodableList var contracts: [TezToolToken]
}

/// All the information available on TezTools for the given token
public struct TezToolToken: Codable {
	
	/// The tokens symbol
	public let symbol: String?
	
	/// The tokens KT address
	public let tokenAddress: String
	
	/// The user facing name of the token
	public let name: String?
	
	/// The FA2 token id of the token
	public let tokenId: Int?
	
	/// The KT address of the main exhcnage for this token
	public let address: String
	
	/// The number of decimals the token uses
	public let decimals: Int
	
	/// The available apps for this token
	public let apps: [TezToolApp]
	
	/// Project website link
	public let websiteLink: String?
	
	/// Link to telegram support channel
	public let telegramLink: String?
	
	/// Link to twitter support account
	public let twitterLink: String?
	
	/// Link to Discord support channel
	public let discordLink: String?
	
	/// Link to token icon image
	public let thumbnailUri: String?
	
	/// Combine the token address and token id to create a unique id
	public func uniqueTokenAddress() -> String {
		if let id = tokenId {
			return "\(tokenAddress):\(id)"
		}
		
		return tokenAddress
	}
}

extension TezToolToken: Hashable {
	
	/// Conforming to `Hashable` to enable working with UITableViewDiffableDataSource
	public func hash(into hasher: inout Hasher) {
		hasher.combine(uniqueTokenAddress())
	}
}

extension TezToolToken: Equatable {
	
	/// Conforming to `Equatable`
	public static func == (lhs: TezToolToken, rhs: TezToolToken) -> Bool {
		return lhs.uniqueTokenAddress() == rhs.uniqueTokenAddress()
	}
}
