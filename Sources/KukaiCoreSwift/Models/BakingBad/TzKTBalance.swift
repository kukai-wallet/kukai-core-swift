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
		return TokenAmount(fromRpcAmount: balance, decimalPlaces: token.metadata?.decimalsInt ?? 0) ?? .zero()
	}
	
	public func isNFT() -> Bool {
		return token.metadata?.decimals == "0" && token.standard == .fa2 && (token.metadata?.artifactUri != nil || token.metadata?.displayUri != nil || token.metadata?.thumbnailUri != nil)
	}
}

public struct TzKTBalanceToken: Codable {
	public let contract: TzKTBalanceContract
	public let tokenId: String
	public let standard: FaVersion
	public let metadata: TzKTBalanceMetadata?
	
	public var displaySymbol: String {
		if metadata?.shouldPreferSymbol == true, let sym = metadata?.symbol {
			return sym
			
		} else if metadata?.shouldPreferSymbol == nil, let alias = contract.alias {
			return alias
			
		} else if metadata?.shouldPreferSymbol == false, let n = metadata?.name {
			return n
			
		} else {
			return ((metadata?.symbol ?? metadata?.name) ?? "")
		}
	}
}

public struct TzKTBalanceContract: Codable {
	public let alias: String?
	public let address: String
}

public struct TzKTBalanceMetadata: Codable {
	
	// Common
	public let name: String?
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
	public let shouldPreferSymbol: Bool?
	
	
	// TODO: remove when API fixed
	enum CodingKeys: String, CodingKey {
		case name
		case symbol
		case decimals
		case formats
		case displayUri
		case artifactUri
		case thumbnailUri
		case description
		case tags
		case minter
		case shouldPreferSymbol
	}
	
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		name = try container.decodeIfPresent(String.self, forKey: .name)
		symbol = try container.decodeIfPresent(String.self, forKey: .symbol)
		decimals = try container.decode(String.self, forKey: .decimals)
		
		formats = try container.decodeIfPresent([TzKTBalanceMetadataFormat].self, forKey: .formats)
		displayUri = try container.decodeIfPresent(String.self, forKey: .displayUri)
		artifactUri = try container.decodeIfPresent(String.self, forKey: .artifactUri)
		thumbnailUri = try container.decodeIfPresent(String.self, forKey: .thumbnailUri)
		description = try container.decodeIfPresent(String.self, forKey: .description)
		tags = try container.decodeIfPresent([String].self, forKey: .tags)
		minter = try container.decodeIfPresent(String.self, forKey: .minter)
		
		if let tempString = try? container.decodeIfPresent(String.self, forKey: .shouldPreferSymbol) {
			shouldPreferSymbol = (tempString == "true")
			
		} else if let tempBool = try? container.decodeIfPresent(Bool.self, forKey: .shouldPreferSymbol) {
			shouldPreferSymbol = tempBool
			
		} else {
			shouldPreferSymbol = nil
		}
	}
	
	
	
	
	
	
	public var thumbnailURL: URL? {
		return MediaProxyService.url(fromUriString: thumbnailUri, ofFormat: .icon)
	}
	
	public var displayURL: URL? {
		return MediaProxyService.url(fromUriString: displayUri, ofFormat: .small)
	}
}

public struct TzKTBalanceMetadataFormat: Codable {
	public let uri: String
	public let mimeType: String
	public let dimensions: TzKTBalanceMetadataDimensions?
	
	public init(uri: String, mimeType: String, dimensions: TzKTBalanceMetadataDimensions?) {
		self.uri = uri
		self.mimeType = mimeType
		self.dimensions = dimensions
	}
}

public struct TzKTBalanceMetadataDimensions: Codable {
	public let unit: String
	public let value: String
	
	public init(unit: String, value: String) {
		self.unit = unit
		self.value = value
	}
}
