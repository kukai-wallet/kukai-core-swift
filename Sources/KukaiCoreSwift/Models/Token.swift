//
//  Token.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 18/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import BigInt
import os.log

/// Enum representing the version of tezos "FA" token contracts
public enum FaVersion: String, Codable {
	case fa1_2 = "fa1.2"
	case fa2
	case unknown
	
	public init(from decoder: Decoder) throws {
		self = try FaVersion(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}


/// A class to represent a Token on the Tezos network. This class will do all the heavy lifting of converting values from the RPC to more human readbale values.
/// This class will also handle arithmetic functions, allowing developers to add and subtract tokens (useful when caluclating fees and total values).
public class Token: Codable, CustomStringConvertible {
	
	/// An Enum to express the type of a token. Different processes are needed to fetch a balance for a users XTZ wallet,
	/// versus fetching a FA1.2 token balance. This allows the library to abstract this logic away from the user and handle it all behind the scenes.
	public enum TokenType: String, Codable {
		case xtz
		case fungible
		case nonfungible
	}
	
	/// The long name of a token. e.g. "Tezos".
	public let name: String?
	
	/// The short name or the symbol of a token. e.g. "XTZ".
	public let symbol: String
	
	/// The type of this token. e.g. xtz, fungible, nonfungible
	public let tokenType: TokenType
	
	/// The FaVersion of the token contract, nil for XTZ
	public let faVersion: FaVersion?
	
	/// Object that holds and formats the balance of the token
	public var balance: TokenAmount
	
	/// Get the underlying number of decimal places that this token represents
	public var decimalPlaces: Int {
		get {
			return balance.decimalPlaces
		}
	}
	
	/// The URL to a cached version of the asset (data that we add later on through other service calls)
	public var thumbnailURL: URL? = nil
	
	/// The current local currency rate of this token. Used to show the user the net worth of their holdings.
	public var localCurrencyRate: Decimal = 0
	
	/// In the case of FA1.2 or higher, we need to know the KT1 address for the token so we can fetch balances and make trades. (should be empty for xtz).
	public let tokenContractAddress: String?
	
	/// Each token type on a contract will have a unique token_id
	public var tokenId: Decimal?
	
	/// Recording if the user has marked the token as hidden
	public var isHidden: Bool = false
	
	/// Recording if the user has marked the token as a favourite
	public var isFavourite: Bool = false
	
	/// Recording if the position the index the user chose for the favourite token to appear
	public var favouriteSortIndex: Int = 0
	
	/// The individual NFT's owned of this token type
	public var nfts: [NFT]?
	
	
	
	// MARK: - Init
	
	/**
	Init a `Token` object that will hold all the necessary data to interact with the Tezos network, and the Dexter exchange
	- parameter name: The long name of the token. e.g. "Tezos"
	- parameter symbol: The short name of the token, or the symbol. e.g. "XTZ"
	- parameter tokenType: The type of the token. e.g. xtz, fa1.2, fa2 etc.
	- parameter faVersion: The FA standard / version used to create this token.
	- parameter decimalPlaces: The number of decimal places this token contains.
	- parameter thumbnailURI: URI to network asset to use to display an icon for the token
	- parameter tokenContractAddress: The KT1 address of the contract (nil if xtz).
	- parameter tokenId: The token id if the token is an FA2 token, nil otherwise.
	- parameter nfts:The individual NFT's owned of this token type
	*/
	public init(name: String?, symbol: String, tokenType: TokenType, faVersion: FaVersion?, balance: TokenAmount, thumbnailURL: URL?, tokenContractAddress: String?, tokenId: Decimal?, nfts: [NFT]?) {
		self.name = name
		self.symbol = symbol
		self.tokenType = tokenType
		self.faVersion = faVersion
		self.balance = balance
		self.thumbnailURL = thumbnailURL
		self.tokenContractAddress = tokenContractAddress
		self.tokenId = tokenId
		self.nfts = nfts
		
		// TODO: make failable init
		if let faVersion = faVersion, faVersion == .fa2 && tokenId == nil {
			os_log("Error: FA2 tokens require having a tokenId set, %@", log: .kukaiCoreSwift, type: .error, name ?? tokenContractAddress ?? "")
		}
	}
	
	/**
	 Init a `Token` from an object returned by the TzKT API
	 */
	public init(from: TzKTBalanceToken, andTokenAmount: TokenAmount) {
		let decimalsString = from.metadata?.decimals ?? "0"
		let decimalsInt = Int(decimalsString) ?? 0
		let isNFT = (from.metadata?.artifactUri != nil && decimalsInt == 0 && from.standard == .fa2)
		
		self.name = from.metadata?.name ?? ""
		self.symbol = isNFT ? from.contract.alias ?? "" : from.displaySymbol
		self.tokenType = isNFT ? .nonfungible : .fungible
		self.faVersion = from.standard
		self.balance = andTokenAmount
		self.thumbnailURL = from.metadata?.thumbnailURL ?? TzKTClient.avatarURL(forToken: from.contract.address)
		self.tokenContractAddress = from.contract.address
		self.tokenId = Decimal(string: from.tokenId) ?? 0
		self.nfts = []
		
		// TODO: make failable init
		if let faVersion = faVersion, faVersion == .fa2 && tokenId == nil {
			os_log("Error: FA2 tokens require having a tokenId set, %@", log: .kukaiCoreSwift, type: .error, name ?? tokenContractAddress ?? "")
		}
	}
	
	/**
	 Init a `Token` from an object returned by the TzKT API
	 */
	public init(from: TzKTTokenTransfer) {
		let decimalsString = from.token.metadata?.decimals ?? "0"
		let decimalsInt = Int(decimalsString) ?? 0
		let isNFT = (from.token.metadata?.artifactUri != nil && decimalsInt == 0 && from.token.standard == .fa2)
		
		self.name = from.token.metadata?.name ?? ""
		self.symbol = isNFT ? from.token.contract.alias ?? "" : from.token.displaySymbol
		self.tokenType = isNFT ? .nonfungible : .fungible
		self.faVersion = from.token.standard
		self.balance = from.tokenAmount()
		self.thumbnailURL = from.token.metadata?.thumbnailURL ?? TzKTClient.avatarURL(forToken: from.token.contract.address)
		self.tokenContractAddress = from.token.contract.address
		self.tokenId = Decimal(string: from.token.tokenId) ?? 0
		self.nfts = []
		
		// TODO: make failable init
		if let faVersion = faVersion, faVersion == .fa2 && tokenId == nil {
			os_log("Error: FA2 tokens require having a tokenId set, %@", log: .kukaiCoreSwift, type: .error, name ?? tokenContractAddress ?? "")
		}
	}
	
	/**
	Create a `Token` object with all the settings needed for XTZ
	- returns: `Token`
	*/
	public static func xtz() -> Token {
		return Token(name: "Tezos", symbol: "XTZ", tokenType: .xtz, faVersion: nil, balance: TokenAmount.zeroBalance(decimalPlaces: 6), thumbnailURL: nil, tokenContractAddress: nil, tokenId: nil, nfts: nil)
	}
	
	/**
	Create a `Token` object with all the settings needed for XTZ, with an initial amount. Useful for setting fees.
	- parameter withAmount: The Amount of XTZ to create the `Token` with.
	- returns: `Token`.
	*/
	public static func xtz(withAmount amount: TokenAmount) -> Token {
		return Token(name: "Tezos", symbol: "XTZ", tokenType: .xtz, faVersion: nil, balance: amount, thumbnailURL: nil, tokenContractAddress: nil, tokenId: nil, nfts: nil)
	}
	
	/// Useful for creating placeholders for pending activity items
	public static func placeholder(fromNFT nft: NFT, amount: TokenAmount, thumbnailURL: URL) -> Token {
		return Token(name: nft.name, symbol: nft.parentAlias ?? "", tokenType: .nonfungible, faVersion: .fa2, balance: amount, thumbnailURL: thumbnailURL, tokenContractAddress: nft.parentContract, tokenId: nft.tokenId, nfts: nil)
	}
	
	/// Conforming to `CustomStringConvertible` to print a number, giving the appearence of a numeric type
	public var description: String {
		return "{Symbol: \(symbol), Name: \(name ?? ""), Type: \(tokenType), FaVersion: \(faVersion ?? .unknown), NFT count: \(nfts?.count ?? 0)}"
	}
	
	/// Helper function to check if the `Token` instance being passed aroun is pointing to XTZ. As many functions will require different functionality for fa token versus XTZ
	public func isXTZ() -> Bool {
		return (self.tokenContractAddress == nil && self.symbol.lowercased() == "xtz")
	}
}

extension Token: Equatable {
	
	/// Conforming to `Equatable` to enable working with UITableViewDiffableDataSource
	public static func == (lhs: Token, rhs: Token) -> Bool {
		return lhs.name == rhs.name &&
			lhs.symbol == rhs.symbol &&
			lhs.description == rhs.description &&
			lhs.tokenContractAddress == rhs.tokenContractAddress &&
			lhs.tokenId == rhs.tokenId &&
			lhs.balance == rhs.balance &&
			lhs.nfts == rhs.nfts
	}
}

extension Token: Hashable {
	
	/// Conforming to `Hashable` to enable working with UITableViewDiffableDataSource
	public func hash(into hasher: inout Hasher) {
		hasher.combine(tokenType.rawValue)
		hasher.combine(name)
		hasher.combine(symbol)
		hasher.combine(tokenContractAddress)
		hasher.combine(tokenId)
	}
}

extension Token: Identifiable {

	/// Conforming to `Identifiable` to enable working with ForEach and similiar looping functions
    /// if faVersion present, use that to follow the standard of either tokenAddress or combination of tokenAddress + token id, fallback to using symbol if type is unknown
    public var id: String {
		guard let faVersion = faVersion else {
			if let tokenAddress = tokenContractAddress {
				return tokenAddress
			} else {
				return symbol
			}
		}
		
		switch faVersion {
			case .fa1_2:
				return tokenContractAddress ?? symbol
				
			case .fa2:
				return "\(tokenContractAddress ?? symbol):\(tokenId ?? 0)"
				
			case .unknown:
				if let tokenAddress = tokenContractAddress {
					return tokenAddress
				} else {
					return symbol
				}
		}
    }
}
