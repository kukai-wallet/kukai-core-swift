//
//  TzKTBalance.swift
//  
//
//  Created by Simon Mcloughlin on 12/01/2022.
//

import Foundation

public struct TzKTBalance: Codable {
	
	public let balance: String
	public let token: TzKTBalanceToken
	
	public var tokenAmount: TokenAmount {
		return TokenAmount(fromRpcAmount: balance, decimalPlaces: token.metadata.decimalsInt) ?? .zero()
	}
	
	public func isNFT() -> Bool {
		return token.metadata.decimals == "0" && token.standard == .fa2 && (token.metadata.artifactUri != nil || token.metadata.displayUri != nil || token.metadata.thumbnailUri != nil)
	}
}

public struct TzKTBalanceToken: Codable {
	public let contract: TzKTBalanceContract
	public let tokenId: String
	public let standard: FaVersion
	public let metadata: TzKTBalanceMetadata
}

public struct TzKTBalanceContract: Codable {
	public let alias: String?
	public let address: String
}

public struct TzKTBalanceMetadata: Codable {
	
	// Common
	public let name: String
	public let symbol: String?
	public let decimals: String
	
	public var decimalsInt: Int {
		return Int(decimals) ?? 0
	}
	
	// Likely NFT related
	public let formats: [TzKTBalanceMetadataFormat]?
	public let displayUri: String?
	public let artifactUri: String?
	public let thumbnailUri: String?
	public let description: String?
	public let tags: [String]?
	public let minter: String?
}

public struct TzKTBalanceMetadataFormat: Codable {
	public let uri: String
	public let mimetype: String
	public let dimensions: TzKTBalanceMetadataDimensions
}

public struct TzKTBalanceMetadataDimensions: Codable {
	public let unit: String
	public let value: String
}
