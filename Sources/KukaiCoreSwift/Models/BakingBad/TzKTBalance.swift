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
	public let contract: TzKTAddress
	
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
	
	/// A collection of attributes about the token/NFT. Although TZIP-16 intended for this to be filled with info such as license, version, possible error messages etc,
	/// It has been adopted by NFT creators as a more free-form dictionary. An example would be for gaming NFT's, this might be a list of attack/defensive moves the character is able to use
	/// It is extremely likely that the actual type will be `[[String: String]]`, however due to various issues and complexities of using a strongly typed language like Swift,
	/// the easiest solution was to use `[Any]` with a custom decoder
	public let attributes: [Any]?
	
	
	/// Need to define coding keys as many tokens have incorrectly set their metadata to have booleans inside strings, inside of just booleans
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
		case attributes
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
		
		attributes = try container.decodeIfPresent([Any].self, forKey: .attributes)
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(name, forKey: .name)
		try container.encode(symbol, forKey: .symbol)
		try container.encode(decimals, forKey: .decimals)
		try container.encode(formats, forKey: .formats)
		try container.encode(displayUri, forKey: .displayUri)
		try container.encode(artifactUri, forKey: .artifactUri)
		try container.encode(thumbnailUri, forKey: .thumbnailUri)
		try container.encode(description, forKey: .description)
		try container.encode(tags, forKey: .tags)
		try container.encode(minter, forKey: .minter)
		try container.encode(shouldPreferSymbol, forKey: .shouldPreferSymbol)
		try container.encode(attributes, forKey: .attributes)
	}
	
	/// Helper to run the URI through the `MediaProxyService` to generate a useable URL for the thumbnail (if available)
	public var thumbnailURL: URL? {
		return MediaProxyService.url(fromUriString: thumbnailUri, ofFormat: .icon)
	}
	
	/// Helper to run the URI through the `MediaProxyService` to generate a useable URL for the display image (if available)
	public var displayURL: URL? {
		return MediaProxyService.url(fromUriString: displayUri, ofFormat: .small)
	}
	
	/// Attributes is a complex free-form object. In a lot of cases when NFT's are games / collectibles,  it should be possible to convert most if not all the elements into more simple String: String key value pairs, which will be easier to manage in table / collection views
	public func getKeyValueTuplesFromAttributes() -> [(key: String, value: String)] {
		guard let attributes else {
			return []
		}
		
		var tempArray: [(key: String, value: String)] = []
		for item in attributes {
			if let stringDict = item as? [String: String] {
				
				// If it is already in the format of `{"key": "foo", "value": "bar"}`, return it in a typed tuple
				if let key = stringDict["key"], let value = stringDict["value"] {
					tempArray.append((key: key, value: value))
				}
				
				// Else if it is in the format of `{"name": "foo", "value": "bar"}`, grab the name and the value and return it as a typed tuple
				else if let key = stringDict["name"], let value = stringDict["value"] {
					tempArray.append((key: key, value: value))
				}
				
				// Else if it is in the format of `{"foo": "bar"}`, grab the key and the value and return it as a typed tuple
				else if let key = stringDict.keys.first, let value = stringDict.values.first {
					tempArray.append((key: key, value: value))
				}
			}
		}
		
		return tempArray
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
