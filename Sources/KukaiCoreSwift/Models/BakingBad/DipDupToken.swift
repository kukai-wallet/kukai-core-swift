//
//  DipDupToken.swift
//  
//
//  Created by Simon Mcloughlin on 25/11/2021.
//

import Foundation

public struct DipDupToken: Codable, Hashable, Equatable {
	
	public let symbol: String
	public let address: String
	public let tokenId: Int
	public let decimals: Int
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

public enum DipDupTokenStandard: String, Codable {
	case fa12
	case fa2
	case unknown
	
	public init(from decoder: Decoder) throws {
		self = try DipDupTokenStandard(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}
