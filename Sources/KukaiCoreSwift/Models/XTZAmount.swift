//
//  XTZAmount.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 25/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import BigInt
import os.log

/// A subclass of `TokenAmount` to make it more explict when functions require XTZ (such as network fees).
/// It also serves as a means to more quickly create `TokenAmount`'s conforming to XTZ.
public class XTZAmount: TokenAmount {
	
	private static let xtzDecimalPlaces = 6
	
	/**
	Set the internal balance, using a RPC string (most likely directly from the RPC node response).  e.g. "1 XTZ"  to the user = "1000000" to the RPC, as there are no such thing as decimal places on the network
	- parameter fromRpcAmount: A string conforming to the RPC standard for XTZ.
	*/
	public init?(fromRpcAmount rpcAmount: String) {
		super.init(fromRpcAmount: rpcAmount, decimalPlaces: XTZAmount.xtzDecimalPlaces)
	}
	
	/**
	Set the internal balance, using a decimal version of an RPC amount.  e.g. "1 XTZ"  to the user = "1000000" to the RPC, as there are no such thing as decimal places on the network
	- parameter fromRpcAmount: A decimal conforming to the RPC standard for XTZ. Decimal places will be ignored.
	*/
	public convenience init?(fromRpcAmount rpcAmount: Decimal) {
		self.init(fromRpcAmount: rpcAmount.description)
	}
	
	/**
	Set the internal balance, using a decimal version of a normalised amount. e.g. if the amount is 1.5 and the token is xtz, internally it will be stored as 1500000
	- parameter fromNormalisedAmount: A decimal containing an amount for XTZ. Anything over the given decimal places for the token will be ignored.
	*/
	public init(fromNormalisedAmount normalisedAmount: Decimal) {
		super.init(fromNormalisedAmount: normalisedAmount, decimalPlaces: XTZAmount.xtzDecimalPlaces)
	}
	
	/**
	Set the internal balance, using a normalised amount string. e.g. if the amount is 1.5 and the token is xtz, internally it will be stored as 1500000
	- parameter fromNormalisedAmount: A string containing an amount for XTZ. Anything over the given decimal places for the token will be ignored.
	*/
	public convenience init?(fromNormalisedAmount normalisedAmount: String, decimalPlaces: Int) {
		guard let decimal = Decimal(string: normalisedAmount.replacingOccurrences(of: (Locale.current.decimalSeparator ?? "."), with: ".")) else {
			Logger.kukaiCoreSwift.error("Can't set balance as can't parse string")
			return nil
		}
		
		self.init(fromNormalisedAmount: decimal)
	}
	
	/**
	Quickly create a `XTZAmount` with zero balance.
	*/
	public override class func zero() -> XTZAmount {
		return XTZAmount(fromNormalisedAmount: 0)
	}
	
	
	// MARK: Codable
	
	enum CodingKeys: String, CodingKey {
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
			
			let balanceString = try container.decode(String.self, forKey: .balance)
			super.init(bigInt: BigInt(balanceString) ?? 0, decimalPlaces: XTZAmount.xtzDecimalPlaces)
			
		} catch {
			let container = try decoder.singleValueContainer()
			
			// Else, attempt to parse the "RPC value" and default decimal palces to zero
			if let balanceString = try? container.decode(String.self) {
				super.init(bigInt: BigInt(balanceString) ?? 0, decimalPlaces: XTZAmount.xtzDecimalPlaces)
				
			} else if let balanceDecimal = try? container.decode(Decimal.self) {
				super.init(bigInt: BigInt(balanceDecimal.rounded(scale: 0, roundingMode: .bankers).description) ?? 0, decimalPlaces: XTZAmount.xtzDecimalPlaces)
				
			} else {
				throw TokenAmountError.invalidStringFromRPC
			}
		}
	}
	
	
	
	
	// MARK: - Arithmetic
	
	/**
	Overload + operator to allow users to add two `Token` amounts of the same type, together.
	*/
	public static func + (lhs: XTZAmount, rhs: XTZAmount) -> XTZAmount {
		let tokenAmount = (lhs as TokenAmount) + (rhs as TokenAmount)
		return XTZAmount(fromNormalisedAmount: tokenAmount.toNormalisedDecimal() ?? 0)
	}
	
	/**
	Overload += operator to allow users to add two `Token` amounts of the same type, together in place.
	*/
	public static func += (lhs: inout XTZAmount, rhs: XTZAmount) {
		let result = lhs + rhs
		lhs = result
	}
	
	/**
	Overload - operator to allow users to subtract two `Token` amounts of the same type.
	*/
	public static func - (lhs: XTZAmount, rhs: XTZAmount) -> XTZAmount {
		let tokenAmount = (lhs as TokenAmount) - (rhs as TokenAmount)
		return XTZAmount(fromNormalisedAmount: tokenAmount.toNormalisedDecimal() ?? 0)
	}
	
	/**
	Overload -= operator to allow users to subtract one `Token` amount of the same type from another, together in place.
	*/
	public static func -= (lhs: inout XTZAmount, rhs: XTZAmount) {
		let result = lhs - rhs
		lhs = result
	}
	
	/**
	Overload multiplcation operator to allow users to multiple a token by a dollar value, and return the localCurrency value of the token.
	*/
	public static func * (lhs: XTZAmount, rhs: Decimal) -> Decimal {
		let lhsDecimal = lhs.toNormalisedDecimal() ?? 0
		return lhsDecimal * rhs
	}
	
	/**
	Overload multiplcation operator to allow users to multiple a token by an Int. Useful for fee caluclation
	*/
	public static func * (lhs: XTZAmount, rhs: Int) -> XTZAmount {
		let tokenAmount = (lhs as TokenAmount) * rhs
		return XTZAmount(fromNormalisedAmount: tokenAmount.toNormalisedDecimal() ?? 0)
	}
}
