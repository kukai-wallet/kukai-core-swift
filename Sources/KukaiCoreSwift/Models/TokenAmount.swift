//
//  TokenAmount.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 20/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import BigInt
import os.log

/// Class representing a numeric amount on the Tezos network. The network uses natural numbers inside strings, which technically have an infinite length.
/// This class is used to encapsulate a `BigInt` and provide all the necessary init's and formatting functions to work with the networks requirements.
public class TokenAmount: Codable {
	
	public enum TokenAmountError: Error {
		case invalidStringFromRPC
	}
	
	/// The number of decimal places that this token supports.
	public var decimalPlaces: Int
	
	/// The balance of the token will be stored in the format expected by the RPC, and converted when needed to the display format users expect.
	/// For example: XTZ has 6 decimal places. But the decimal places are merely used for displaying to the end user. On the network 1 XTZ = 1000000, and is formatted as1.000000 in the client.
	///
	/// Intentiaonlly chose to not use unsigned BigInt. While its true that tokens on the Tezos network can't be negative (not such thing as holding -1 XTZ),
	/// there are situations such as transaction history display, or computing fees when sending the maximum balance, where it makes sense to allow the class to hold a negative value.
	/// It should be the responsibility of the `TezosNodeClient` or the `RPC` layer or the `NetworkService` to validate that it is a valid amount to send.
	internal var internalBigInt: BigInt = 0
	
	/// Format the internal value to ensure it matches the format the RPC will expect
	public var rpcRepresentation: String {
		
		// Trim leading Zero's
		let intermediateString = String(internalBigInt)
		let santizedString = intermediateString.replacingOccurrences(of: "^0+", with: "", options: .regularExpression)
		
		// When implementing the RPC parse function, returning an empty string causes mismatches.
		// The Tezos node will replace empty strings with "0", as it always expects a value to be present
		if santizedString == "" {
			return "0"
		}
		
		return santizedString
	}
	
	/// Basic formatting of a token to be human readable. For more advanced options, use the format function
	public var normalisedRepresentation: String {
		let isNegative = internalBigInt < 0
		
		// Pad the value so its at least `decimalPlaces` long
		var paddedDecimalAmount = String( (isNegative ? internalBigInt * -1 : internalBigInt) )
		while paddedDecimalAmount.count < decimalPlaces {
			paddedDecimalAmount = "0" + paddedDecimalAmount
		}

		var decimalAmount = paddedDecimalAmount.suffix(decimalPlaces)
		while decimalAmount.last == "0" {
			decimalAmount = decimalAmount.dropLast()
		}
		
		let integerAmountLength = paddedDecimalAmount.count - decimalPlaces
		var integerAmount = integerAmountLength != 0 ? paddedDecimalAmount.prefix(integerAmountLength) : "0"
		
		if isNegative {
			integerAmount = "-\(integerAmount)"
		}
		
		if decimalAmount == "" {
			return String(integerAmount)
			
		} else {
			
			return integerAmount + (Locale.current.decimalSeparator ?? ".") + decimalAmount
		}
	}
	
	
	// MARK: - Init
	
	/**
	Set the internal balance, using a RPC string (most likely directly from the RPC node response).  e.g. "1 XTZ"  to the user = "1000000" to the RPC, as there are no such thing as decimal places on the network
	- parameter fromRpcAmount: A string conforming to the RPC standard for the given token.
	*/
	public init?(fromRpcAmount rpcAmount: String, decimalPlaces: Int) {
		guard CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: rpcAmount)) else {
			os_log(.error, log: .kukaiCoreSwift, "Can't set balance on a Token of tokenType.empty, or pass in a string with non digit characters. Entered: %@", rpcAmount)
			return nil
		}
		
		self.decimalPlaces = decimalPlaces
		self.internalBigInt = BigInt(rpcAmount) ?? 0
	}
	
	/**
	Set the internal balance, using a decimal version of an RPC amount.  e.g. "1 XTZ"  to the user = "1000000" to the RPC, as there are no such thing as decimal places on the network
	- parameter fromRpcAmount: A decimal conforming to the RPC standard for the given token. Decimal places will be ignored.
	*/
	public convenience init?(fromRpcAmount rpcAmount: Decimal, decimalPlaces: Int) {
		self.init(fromRpcAmount: rpcAmount.description, decimalPlaces: decimalPlaces)
	}
	
	/**
	Set the internal balance, using a decimal version of a normalised amount. e.g. if the amount is 1.5 and the token is xtz, internally it will be stored as 1500000
	- parameter fromNormalisedAmount: A decimal containing an amount for the given token. Anything over the given decimal places for the token will be ignored.
	*/
	public init(fromNormalisedAmount normalisedAmount: Decimal, decimalPlaces: Int) {
		let integerValue = BigInt(normalisedAmount.description) ?? 0
		
		// Convert decimalPlaces significant digits of decimals into integers to avoid having to deal with decimals.
		let multiplierDoubleValue = (pow(10, decimalPlaces) as NSDecimalNumber).doubleValue
		let multiplierIntValue = (pow(10, decimalPlaces) as NSDecimalNumber).intValue
		let significantDecimalDigitsAsInteger = BigInt((normalisedAmount * Decimal(multiplierDoubleValue)).rounded(scale: 0, roundingMode: .down).description) ?? 0
		let significantIntegerDigitsAsInteger = BigInt(integerValue * BigInt(multiplierIntValue))
		let decimalValue = significantDecimalDigitsAsInteger - significantIntegerDigitsAsInteger
		
		self.decimalPlaces = decimalPlaces
		self.internalBigInt = (integerValue * BigInt(10).power(decimalPlaces)) + decimalValue
	}
	
	/**
	Set the internal balance, using a normalised amount string. e.g. if the amount is 1.5 and the token is xtz, internally it will be stored as 1500000
	- parameter fromNormalisedAmount: A string containing an amount for the given token. Anything over the given decimal places for the token will be ignored.
	*/
	public convenience init?(fromNormalisedAmount normalisedAmount: String, decimalPlaces: Int) {
		guard let decimal = Decimal(string: normalisedAmount.replacingOccurrences(of: (Locale.current.decimalSeparator ?? "."), with: ".")) else {
			os_log(.error, log: .kukaiCoreSwift, "Can't set balance as can't parse string")
			return nil
		}
		
		self.init(fromNormalisedAmount: decimal, decimalPlaces: decimalPlaces)
	}
	
	/**
	Private init to create an object with a `BigInt`. Used as an internal helper, should not be used by develoeprs using KukaiCoreSwift.
	*/
	private init(decimalPlaces: Int) {
		self.decimalPlaces = decimalPlaces
		self.internalBigInt = 0
	}
	
	/**
	Private init to create an object with a `BigInt`. Used as an internal helper, should not be used by develoeprs using KukaiCoreSwift.
	*/
	internal init(bigInt: BigInt, decimalPlaces: Int) {
		self.decimalPlaces = decimalPlaces
		self.internalBigInt = bigInt
	}
	
	/**
	Quickly create a `TokenAmount` with zero balance and no decimal places.
	**Warning:** the decimal places attribute could be used by other code to determine precision. This should only be used in places where it is needed as a temporary, default value.
	*/
	public class func zero() -> TokenAmount {
		return TokenAmount(decimalPlaces: 0)
	}
	
	/**
	Quickly create a `TokenAmount` with zero balance.
	*/
	public class func zeroBalance(decimalPlaces: Int) -> TokenAmount {
		return TokenAmount(decimalPlaces: decimalPlaces)
	}
	
	
	
	// MARK: Codable
	
	enum CodingKeys: String, CodingKey {
		case decimalPlaces
		case balance
	}
	
	/**
	Token Amounts need an amount and to know the number of decimal places. When downloading from an API, the balance may be presented without the decimal info, where as when we encode, we have the info.
	This coder attempts to handle both states, first checking if its possible to extract both, if not, defaulting the decimal palces to zero, expecting the calling application to provide this information later on from another proptery or even another API call (such as a metadata query)
	*/
	required public init(from decoder: Decoder) throws {
		do {
			// Attempt to decode both decimal places and balance
			let container = try decoder.container(keyedBy: CodingKeys.self)
			decimalPlaces = try container.decode(Int.self, forKey: .decimalPlaces)
			
			let balanceString = try container.decode(String.self, forKey: .balance)
			internalBigInt = BigInt(balanceString) ?? 0
			
		} catch {
			
			// Attempt to parse the "RPC value" and default decimal palces to zero
			let container = try decoder.singleValueContainer()
			
			if let balanceString = try? container.decode(String.self) {
				internalBigInt = BigInt(balanceString) ?? 0
				
			} else if let balanceDecimal = try? container.decode(Decimal.self) {
				internalBigInt = BigInt(balanceDecimal.rounded(scale: 0, roundingMode: .bankers).description) ?? 0
				
			} else {
				throw TokenAmountError.invalidStringFromRPC
			}
				
			decimalPlaces = 0
		}
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(decimalPlaces, forKey: .decimalPlaces)
		try container.encode(self.rpcRepresentation, forKey: .balance)
	}
	
	
	
	// MARK: - Display
	
	/**
	Format the current value into a human readable string, using the given locale.
	- parameter locale: The locale to use to decide whether to use decimal or comma, comma or spaces etc, when formattting the number
	*/
	public func formatNormalisedRepresentation(locale: Locale) -> String? {
		guard let decimal = self.toNormalisedDecimal() else {
			return nil
		}
		
		let numberFormatter = NumberFormatter()
		numberFormatter.locale = locale
		numberFormatter.numberStyle = .decimal
		numberFormatter.maximumFractionDigits = decimalPlaces
		
		return numberFormatter.string(from: decimal as NSNumber)
	}
	
	/**
	Function to convert the underlying rpc value into a `Decimal` which can be useful in some situations for integrating with other tools and frameworks.
	**Warning** `Decimal` has a limited, lower treshold (163 digits). Its possible it can overrun, hence the optional return value.
	*/
	public func toRpcDecimal() -> Decimal? {
		guard let decimal = Decimal(string: internalBigInt.description)?.rounded(scale: decimalPlaces, roundingMode: .down) else {
			return nil
		}
		
		return decimal
	}
	
	/**
	Function to convert the underlying normalised value into a `Decimal` which can be useful in some situations for integrating with other tools and frameworks.
	**Warning** `Decimal` has a limited, lower treshold (163 digits). Its possible it can overrun, hence the optional return value.
	*/
	public func toNormalisedDecimal() -> Decimal? {
		guard let decimal = Decimal(string: internalBigInt.description) else {
			return nil
		}
		
		return (decimal / pow(10, decimalPlaces)).rounded(scale: decimalPlaces, roundingMode: .down)
	}
	
	/**
	Currently we are unable to cast directly from `TokenAmount` to `XTZAmount`. This function will create a new XTZAmount object from the TokenAmount.
	THis is useful in situations where an amount is passed in a generic manner as a `TokenAmount`, but its required to be an `XTZAmount`
	*/
	public func toXTZAmount() -> XTZAmount {
		guard let normalisedAmount = self.toNormalisedDecimal() else {
			return XTZAmount.zero()
		}
		
		return XTZAmount(fromNormalisedAmount: normalisedAmount)
	}
	
	
	
	// MARK: - Arithmetic
	
	/// Function to check if tokens have the same decimal palces, and log an error if not. Not supporting the idea of adding unrelated tokens together
	private static func sameTokenCheck(lhs: TokenAmount, rhs: TokenAmount) -> Bool {
		let result = (lhs.decimalPlaces == rhs.decimalPlaces)
		
		if !result {
			os_log(.error, log: .kukaiCoreSwift, "Arithmetic function is not possible between tokens with different decimal places. Ignoring operation.")
		}
		
		return result
	}
	
	/**
	Overload + operator to allow users to add two `Token` amounts of the same type, together.
	*/
	public static func + (lhs: TokenAmount, rhs: TokenAmount) -> TokenAmount {
		guard sameTokenCheck(lhs: lhs, rhs: rhs) else {
			return TokenAmount.zeroBalance(decimalPlaces: lhs.decimalPlaces)
		}
		
		return TokenAmount(bigInt: (lhs.internalBigInt + rhs.internalBigInt), decimalPlaces: lhs.decimalPlaces)
	}
	
	/**
	Overload += operator to allow users to add two `Token` amounts of the same type, together in place.
	*/
	public static func += (lhs: inout TokenAmount, rhs: TokenAmount) {
		guard sameTokenCheck(lhs: lhs, rhs: rhs) else {
			return
		}
		
		let result = lhs + rhs
		lhs = result
	}
	
	/**
	Overload - operator to allow users to subtract two `Token` amounts of the same type.
	*/
	public static func - (lhs: TokenAmount, rhs: TokenAmount) -> TokenAmount {
		guard sameTokenCheck(lhs: lhs, rhs: rhs) else {
			return TokenAmount.zeroBalance(decimalPlaces: lhs.decimalPlaces)
		}
		
		return TokenAmount(bigInt: (lhs.internalBigInt - rhs.internalBigInt), decimalPlaces: lhs.decimalPlaces)
	}
	
	/**
	Overload -= operator to allow users to subtract one `Token` amount of the same type from another, together in place.
	*/
	public static func -= (lhs: inout TokenAmount, rhs: TokenAmount) {
		guard sameTokenCheck(lhs: lhs, rhs: rhs) else {
			return
		}
		
		let result = lhs - rhs
		lhs = result
	}
	
	/**
	Overload multiplcation operator to allow users to multiple a token by a dollar value, and return the localCurrency value of the token.
	*/
	public static func * (lhs: TokenAmount, rhs: Decimal) -> Decimal {
		let lhsDecimal = lhs.toNormalisedDecimal() ?? 0
		return lhsDecimal * rhs
	}
	
	/**
	Overload multiplcation operator to allow users to multiple a token by an Int. Useful for fee caluclation
	*/
	public static func * (lhs: TokenAmount, rhs: Int) -> TokenAmount {
		return TokenAmount(bigInt: (lhs.internalBigInt * BigInt(clamping: rhs)), decimalPlaces: lhs.decimalPlaces)
	}
}



// MARK: - Extensions

extension TokenAmount: Comparable {
	
	/// Conforming to `Comparable`
	public static func < (lhs: TokenAmount, rhs: TokenAmount) -> Bool {
		return lhs.internalBigInt < rhs.internalBigInt
	}
}

extension TokenAmount: Equatable {
	
	/// Conforming to `Equatable`
	public static func == (lhs: TokenAmount, rhs: TokenAmount) -> Bool {
		return lhs.internalBigInt == rhs.internalBigInt
	}
}

extension TokenAmount: CustomStringConvertible {
	
	/// Conforming to `CustomStringConvertible` to print a number, giving the appearence of a numeric type
	public var description: String {
		return normalisedRepresentation
	}
}

extension TokenAmount: Hashable {
	
	/// Conforming to `Hashable` to enable working with UITableViewDiffableDataSource
	public func hash(into hasher: inout Hasher) {
		hasher.combine(rpcRepresentation)
		hasher.combine(decimalPlaces)
	}
}
