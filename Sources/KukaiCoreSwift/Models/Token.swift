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
	case fa1_2 = "fa1-2"
	case fa2
	case unknown
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
	
	/// The icon used to display next to a given token.
	public var icon: URL?
	
	/// The long name of a token. e.g. "Tezos".
	public let name: String
	
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
	
	/// The current local currency rate of this token. Used to show the user the net worth of their holdings.
	public var localCurrencyRate: Decimal = 0
	
	/// In the case of FA1.2 or higher, we need to know the KT1 address for the token so we can fetch balances and make trades. (should be empty for xtz).
	public let tokenContractAddress: String?
	
	/// The individual NFT's owned of this token type
	public let nfts: [NFT]?
	
	
	
	// MARK: - Init
	
	/**
	Init a `Token` object that will hold all the necessary data to interact with the Tezos network, and the Dexter exchange
	- parameter icon: An image used to denote the token.
	- parameter name: The long name of the token. e.g. "Tezos"
	- parameter symbol: The short name of the token, or the symbol. e.g. "XTZ"
	- parameter tokenType: The type of the token. e.g. xtz, fa1.2, fa2 etc.
	- parameter faVersion: The FA standard / version used to create this token.
	- parameter decimalPlaces: The number of decimal places this token contains.
	- parameter tokenContractAddress: The KT1 address of the contract (nil if xtz).
	- parameter nfts:The individual NFT's owned of this token type
	*/
	public init(icon: URL?, name: String, symbol: String, tokenType: TokenType, faVersion: FaVersion?, balance: TokenAmount, tokenContractAddress: String?, nfts: [NFT]?) {
		self.icon = icon
		self.name = name
		self.symbol = symbol
		self.tokenType = tokenType
		self.faVersion = faVersion
		self.balance = balance
		self.tokenContractAddress = tokenContractAddress
		self.nfts = nfts
	}
	
	/**
	Create a `Token` object with all the settings needed for XTZ
	- returns: `Token`
	*/
	public static func xtz() -> Token {
		return Token(icon: nil, name: "Tezos", symbol: "XTZ", tokenType: .xtz, faVersion: nil, balance: TokenAmount.zeroBalance(decimalPlaces: 6), tokenContractAddress: nil, nfts: nil)
	}
	
	/**
	Create a `Token` object with all the settings needed for XTZ, with an initial amount. Useful for setting fees.
	- parameter withAmount: The Amount of XTZ to create the `Token` with.
	- returns: `Token`.
	*/
	public static func xtz(withAmount amount: TokenAmount) -> Token {
		return Token(icon: nil, name: "Tezos", symbol: "XTZ", tokenType: .xtz, faVersion: nil, balance: amount, tokenContractAddress: nil, nfts: nil)
	}
	
	/// Conforming to `CustomStringConvertible` to print a number, giving the appearence of a numeric type
	public var description: String {
		return "{Symbol: \(symbol), Name: \(name), Type: \(tokenType), FaVersion: \(faVersion ?? .unknown), NFT count: \(nfts?.count ?? 0)}"
	}
}
