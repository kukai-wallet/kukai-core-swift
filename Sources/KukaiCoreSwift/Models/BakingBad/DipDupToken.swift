//
//  DipDupToken.swift
//  
//
//  Created by Simon Mcloughlin on 25/11/2021.
//

import Foundation

/// DipDup representation of a Token
public struct DipDupToken: Codable, Hashable, Equatable {
	
	/// The user facing symbol of the token
	public let symbol: String
	
	/// The TZ address of the token
	public let address: String
	
	/// The token ID of the token (always 0 for FA1.2 tokens)
	public let tokenId: Int
	
	/// The number of decimals for the token
	public let decimals: Int
	
	/// Which standard the token follows
	public let standard: DipDupTokenStandard
	
	/// Conforming to `Hashable` to enable working with UITableViewDiffableDataSource
	public func hash(into hasher: inout Hasher) {
		hasher.combine(address)
		hasher.combine(tokenId)
	}
	
	/// Conforming to `Equatable` to enable working with UITableViewDiffableDataSource
	public static func == (lhs: DipDupToken, rhs: DipDupToken) -> Bool {
		return lhs.address == rhs.address && lhs.tokenId == rhs.tokenId
	}
}

/// Wrapping up the FA standards into an enum
public enum DipDupTokenStandard: String, Codable {
	case fa12
	case fa2
	case unknown
	
	public init(from decoder: Decoder) throws {
		self = try DipDupTokenStandard(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}
