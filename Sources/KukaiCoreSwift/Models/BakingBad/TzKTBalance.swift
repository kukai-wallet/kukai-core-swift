//
//  TzKTBalance.swift
//  
//
//  Created by Simon Mcloughlin on 12/01/2022.
//

import Foundation

/// Model mapping to the Balance object returned from the new TzKT API, resulting from the merge of BCD and TzKT
public struct TzKTBalance: Codable {
	
	/// String containing the RPC respresetnation of the balance of the given token
	public let balance: String
	
	/// Details about the Token
	public let token: TzKTBalanceToken
	
	/// Helper to convert the RPC token balance to a `TokenAmount` object
	public var tokenAmount: TokenAmount {
		return TokenAmount(fromRpcAmount: balance, decimalPlaces: token.metadata?.decimalsInt ?? 0) ?? .zero()
	}
	
	/// Basic check to see if token is an NFT or not. May not be 100% successful, needs research
	public func isNFT() -> Bool {
		return token.metadata?.decimals == "0" && token.standard == .fa2 && (token.metadata?.artifactUri != nil || token.metadata?.displayUri != nil || token.metadata?.thumbnailUri != nil)
	}
}

/// Model encapsulating information about the token itself
public struct TzKTBalanceToken: Codable {
	
	/// Details of the contract (e.g. address)
	public let contract: TzKTBalanceContract
	
	/// The FA2 token ID of the token
	public let tokenId: String
	
	/// Which FA version the token conforms too
	public let standard: FaVersion
	
	/// Metadata about the token
	public let metadata: TzKTBalanceMetadata?
	
	/// Helper to determine what string is used as the symbol for display purposes
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

/// Details about a given contract
public struct TzKTBalanceContract: Codable {
	
	/// Contract addresses may have an alias (human readbale) name, to denote a person or service
	public let alias: String?
	
	/// The KT1 address of the contract
	public let address: String
}

/// Metadata object for the token
public struct TzKTBalanceMetadata: Codable {
	
	// Common
	
	/// A human readbale name
	public let name: String?
	
	/// The tokens symbol
	public let symbol: String?
	
	/// The number of decimals the token has
	public let decimals: String
	
	/// Helper to convert the decimals to an Int
	public var decimalsInt: Int {
		return Int(decimals) ?? 0
	}
	
	// Likely NFT related
	
	/// Details of the available formats that the media is available in
	public let formats: [TzKTBalanceMetadataFormat]?
	
	/// URI to an medium/large image owned by the contract
	public let displayUri: String?
	
	/// URI to the raw media artifact owned by the token
	public let artifactUri: String?
	
	/// URI to an small image for the token, ususally used as an icon when displayed in lists
	public let thumbnailUri: String?
	
	/// Description of the token or NFT
	public let description: String?
	
	/// A list of tags to categorize the token / NFT
	public let tags: [String]?
	
	/// The address responsible for creating the token / NFT
	public let minter: String?
	
	/// Whether or not the symbol or the name is prefered when displaying the token / NFT in a list
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
	
	
	
	
	
	/// Helper to run the URI through the `MediaProxyService` to generate a useable URL for the thumbnail (if available)
	public var thumbnailURL: URL? {
		return MediaProxyService.url(fromUriString: thumbnailUri, ofFormat: .icon)
	}
	
	/// Helper to run the URI through the `MediaProxyService` to generate a useable URL for the display image (if available)
	public var displayURL: URL? {
		return MediaProxyService.url(fromUriString: displayUri, ofFormat: .small)
	}
}

/// Object containing information about the various formats the media is available in
public struct TzKTBalanceMetadataFormat: Codable {
	
	/// The URI to this specific format
	public let uri: String
	
	/// The mimetype of this version
	public let mimeType: String
	
	/// The display dimensions
	public let dimensions: TzKTBalanceMetadataDimensions?
	
	/// Init to manaually create an instance, mostly for testing
	public init(uri: String, mimeType: String, dimensions: TzKTBalanceMetadataDimensions?) {
		self.uri = uri
		self.mimeType = mimeType
		self.dimensions = dimensions
	}
}

/// Object containing information about the dimensions of a given piece of media
public struct TzKTBalanceMetadataDimensions: Codable {
	
	/// The unit of measurement (e.g. px for pixels)
	public let unit: String
	
	/// String containing the resolution or size (e.g. 1024x787)
	public let value: String
	
	/// Init to manaually create an instance, mostly for testing
	public init(unit: String, value: String) {
		self.unit = unit
		self.value = value
	}
}
