//
//  TzKTBalance.swift
//  
//
//  Created by Simon Mcloughlin on 12/01/2022.
//

import Foundation
import OSLog

/// Model mapping to the Balance object returned from the new TzKT API, resulting from the merge of BCD and TzKT
public struct TzKTBalance: Codable {
	
	public static let exceptionListNFT = [
		"KT1GBZmSxmnKJXGMdMLbugPfLyUPmuLSMwKS" // Tezos domains
	]
	
	/// String containing the RPC respresetnation of the balance of the given token
	public let balance: String
	
	/// Details about the Token
	public let token: TzKTBalanceToken
	
	/// The block level where the token was first seen
	public let firstLevel: Decimal
	
	/// The block level where the token was last seen
	public let lastLevel: Decimal
	
	/// Helper to convert the RPC token balance to a `TokenAmount` object
	public var tokenAmount: TokenAmount {
		return TokenAmount(fromRpcAmount: balance, decimalPlaces: token.metadata?.decimalsInt ?? 0) ?? .zero()
	}
	
	/// Basic check to see if token is an NFT or not. May not be 100% successful, needs research
	public func isNFT() -> Bool {
		// If token is an fa2 standard, and either provided onchain metadata to show it has no decimals and artifact URI   -OR- has no onchian data, but has a totalSupply of 1, it is most likley am NFT
		// Fallback to an exception list of high profile tokens that falloutside of this
		return (token.standard == .fa2 && (
											(token.metadata?.decimals == "0" && token.metadata?.artifactUri != nil) ||
											(token.totalSupply == "1")
										)
				) || isOnNFTExceptionList()
	}
	
	public func isOnNFTExceptionList() -> Bool {
		return TzKTBalance.exceptionListNFT.contains(token.contract.address)
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
	
	/// Total avaialble supply of this address + token id combo
	public let totalSupply: String?
	
	/// Metadata about the token
	//@NilOnDecodingError
	public var metadata: TzKTBalanceMetadata?
	
	public var malformedMetadata: Bool
	
	/// Helper to determine what string is used as the symbol for display purposes
	public var displaySymbol: String {
		if metadata?.shouldPreferSymbol == true, let sym = metadata?.symbol {
			return sym
			
		} else if (metadata?.shouldPreferSymbol == false || metadata?.symbol == nil), let n = metadata?.name {
			return n
			
		} else {
			return ((metadata?.symbol ?? metadata?.name) ?? "")
		}
	}
	
	public init(contract: TzKTAddress, tokenId: String, standard: FaVersion, totalSupply: String?, metadata: TzKTBalanceMetadata?) {
		self.contract = contract
		self.tokenId = tokenId
		self.standard = standard
		self.totalSupply = totalSupply
		self.metadata = metadata
		self.malformedMetadata = false
	}
	
	enum CodingKeys: CodingKey {
		case contract
		case tokenId
		case standard
		case totalSupply
		case metadata
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.contract = try container.decode(TzKTAddress.self, forKey: .contract)
		self.tokenId = try container.decode(String.self, forKey: .tokenId)
		self.standard = try container.decode(FaVersion.self, forKey: .standard)
		self.totalSupply = try container.decodeIfPresent(String.self, forKey: .totalSupply)
		
		do {
			self.metadata = try container.decodeIfPresent(TzKTBalanceMetadata.self, forKey: .metadata)
			self.malformedMetadata = false
			
		} catch {
			// If metadata is present, but can't be parsed, we record this so we can filter out these tokens later on. Likely bad experiements
			self.metadata = nil
			self.malformedMetadata = true
		}
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.contract, forKey: .contract)
		try container.encode(self.tokenId, forKey: .tokenId)
		try container.encode(self.standard, forKey: .standard)
		try container.encodeIfPresent(self.totalSupply, forKey: .totalSupply)
		try container.encodeIfPresent(self.metadata, forKey: .metadata)
	}
}

/// Metadata object for the token
public struct TzKTBalanceMetadata: Codable {
	
	// Common
	
	/// A human readbale name
	public var name: String?
	
	/// The tokens symbol
	public var symbol: String?
	
	/// The number of decimals the token has
	public var decimals: String
	
	/// Helper to convert the decimals to an Int
	public var decimalsInt: Int {
		return Int(decimals) ?? 0
	}
	
	// Likely NFT related
	
	/// Details of the available formats that the media is available in
	public var formats: [TzKTBalanceMetadataFormat]?
	
	/// URI to an medium/large image owned by the contract
	public var displayUri: String?
	
	/// URI to the raw media artifact owned by the token
	public var artifactUri: String?
	
	/// URI to an small image for the token, ususally used as an icon when displayed in lists
	public var thumbnailUri: String?
	
	/// Description of the token or NFT
	public var description: String?
	
	/// URL to the tool that was used to mint the item
	public var mintingTool: String?
	
	/// A list of tags to categorize the token / NFT
	public var tags: [String]?
	
	/// The address responsible for creating the token / NFT
	public var minter: String?
	
	/// Whether or not the symbol or the name is prefered when displaying the token / NFT in a list
	public var shouldPreferSymbol: Bool?
	
	/// A collection of attributes about the token/NFT. Although TZIP-16 intended for this to be filled with info such as license, version, possible error messages etc,
	/// It has been adopted by NFT creators as a more free-form dictionary. An example would be for gaming NFT's, this might be a list of attack/defensive moves the character is able to use
	/// It is extremely likely that the actual type will be `[[String: String]]`, however due to various issues and complexities of using a strongly typed language like Swift,
	/// the easiest solution was to use `[Any]` with a custom decoder
	public var attributes: [Any]?
	
	/// Flag, in seconds, indicating how long to wait before refreshing the token to update its metadata. E.g. fxHash will inject a token with a name "[Waiting to be Signed]". and then, all things going well, 30 seconds later its updated to the correct attributes
	public let ttl: Int?
	
	
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
		case mintingTool
		case tags
		case minter
		case shouldPreferSymbol
		case attributes
		case ttl
		
		// Handle miss named attribtues
		case should_prefer_symbol
		case display_uri
		case artifact_uri
		case thumbnail_uri
	}
	
	public init(name: String?, symbol: String?, decimals: String, formats: [TzKTBalanceMetadataFormat]?, displayUri: String?, artifactUri: String?, thumbnailUri: String?, description: String?, mintingTool: String?, tags: [String]?, minter: String?, shouldPreferSymbol: Bool?, attributes: [Any]?, ttl: Int?) {
		self.name = name
		self.symbol = symbol
		self.decimals = decimals
		self.formats = formats
		self.displayUri = displayUri
		self.artifactUri = artifactUri
		self.thumbnailUri = thumbnailUri
		self.description = description
		self.mintingTool = mintingTool
		self.tags = tags
		self.minter = minter
		self.shouldPreferSymbol = shouldPreferSymbol
		self.attributes = attributes
		self.ttl = ttl
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		decimals = try container.decode(String.self, forKey: .decimals)
		
		// if decimals is invalid data, throw an error. Token is unusable if we don't know its decimals
		guard let _ = Decimal(string: decimals) else {
			throw DecodingError.typeMismatch(String.self, DecodingError.Context(codingPath: [], debugDescription: "Decimals is not a valid number"))
		}
		
		
		name = try container.decodeIfPresent(String.self, forKey: .name)
		symbol = try container.decodeIfPresent(String.self, forKey: .symbol)
		
		displayUri = try container.decodeIfPresent(String.self, forKey: .displayUri, orBackupKey: .display_uri)
		artifactUri = try container.decodeIfPresent(String.self, forKey: .artifactUri, orBackupKey: .artifact_uri)
		thumbnailUri = try container.decodeIfPresent(String.self, forKey: .thumbnailUri, orBackupKey: .thumbnail_uri)
		description = try container.decodeIfPresent(String.self, forKey: .description)
		mintingTool = try container.decodeIfPresent(String.self, forKey: .mintingTool)
		tags = try container.decodeIfPresent([String].self, forKey: .tags)
		minter = try container.decodeIfPresent(String.self, forKey: .minter)
		
		
		// Special handling for tokens like dogami that uploaded their formats as a string containing a JSON encoded array, instead of actually being an array
		do {
			formats = try container.decodeIfPresent([TzKTBalanceMetadataFormat].self, forKey: .formats)
		} catch {
			formats = nil
		}
		
		
		if let tempString = try? container.decodeIfPresent(String.self, forKey: .shouldPreferSymbol) {
			shouldPreferSymbol = (tempString.lowercased() == "true")
			
		} else if let tempBool = try? container.decodeIfPresent(Bool.self, forKey: .shouldPreferSymbol) {
			shouldPreferSymbol = tempBool
			
		} else {
			shouldPreferSymbol = nil
		}
		
		if let attributes = try? container.decodeIfPresent([Any].self, forKey: .attributes) {
			self.attributes = attributes
		} else {
			attributes = nil
		}
		
		if let tempString = try? container.decodeIfPresent(String.self, forKey: .ttl) {
			ttl = Int(tempString)
		} else {
			ttl = nil
		}
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
		try container.encode(mintingTool, forKey: .mintingTool)
		try container.encode(tags, forKey: .tags)
		try container.encode(minter, forKey: .minter)
		try container.encode(shouldPreferSymbol, forKey: .shouldPreferSymbol)
		try container.encode(attributes, forKey: .attributes)
		try container.encodeIfPresent(ttl?.description, forKey: .ttl)
	}
	
	/// Helper to run the URI through the `MediaProxyService` to generate a useable URL for the thumbnail (if available)
	public var thumbnailURL: URL? {
		return MediaProxyService.url(fromUriString: thumbnailUri, ofFormat: MediaProxyService.Format.small.rawFormat(), keepGif: true)
	}
	
	/// Helper to run the URI through the `MediaProxyService` to generate a useable URL for the display image (if available)
	public var displayURL: URL? {
		return MediaProxyService.url(fromUriString: displayUri, ofFormat: MediaProxyService.Format.medium.rawFormat(), keepGif: true)
	}
	
	/// Attributes is a complex free-form object. In a lot of cases when NFT's are games / collectibles,  it should be possible to convert most if not all the elements into more simple String: String key value pairs, which will be easier to manage in table / collection views
	public func getKeyValuesFromAttributes() -> [TzKTBalanceMetadataAttributeKeyValue] {
		guard let attributes else {
			return []
		}
		
		var tempArray: [TzKTBalanceMetadataAttributeKeyValue] = []
		for item in attributes {
			if let stringDict = item as? [String: String] {
				
				// If it is already in the format of `{"key": "foo", "value": "bar"}`, return it in a typed tuple
				if let key = stringDict["key"], let value = stringDict["value"] {
					tempArray.append(TzKTBalanceMetadataAttributeKeyValue(key: key, value: value))
				}
				
				// Else if it is in the format of `{"name": "foo", "value": "bar"}`, grab the name and the value and return it as a typed tuple
				else if let key = stringDict["name"], let value = stringDict["value"] {
					tempArray.append(TzKTBalanceMetadataAttributeKeyValue(key: key, value: value))
				}
				
				// Else if it is in the format of `{"foo": "bar"}`, grab the key and the value and return it as a typed tuple
				else if let key = stringDict.keys.first, let value = stringDict.values.first {
					tempArray.append(TzKTBalanceMetadataAttributeKeyValue(key: key, value: value))
				}
			}
		}
		
		return tempArray
	}
}

/// Wrapper / Helper to extract metadata attribute content
public struct TzKTBalanceMetadataAttributeKeyValue: Codable, Hashable {
	public let key: String
	public let value: String
	
	public init(key: String, value: String) {
		self.key = key
		self.value = value
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
	public let unit: String?
	
	/// String containing the resolution or size (e.g. 1024x787)
	public let value: String?
	
	/// Init to manaually create an instance, mostly for testing
	public init(unit: String, value: String) {
		self.unit = unit
		self.value = value
	}
}
