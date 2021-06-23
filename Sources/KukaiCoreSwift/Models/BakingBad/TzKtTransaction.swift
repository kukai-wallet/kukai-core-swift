//
//  TzKtTransaction.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 26/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// A model matching the response that comes back from TzKT's API: `v1/accounts/<address>/operations`
public class TzKTTransaction: Decodable, CustomStringConvertible {
	
	// MARK: Types
	
	public enum TransactionStatus: String, Codable {
		case applied
		case failed
		case backtracked
		case unknown
	}
	
	public enum TransactionType: String, Codable {
		case delegation
		case origination
		case transaction
		case reveal
		case unknown
	}
	
	public enum TransactionSubType: String, Codable {
		case send
		case nativeTokenSend
		case receive
		case nativeTokenReceive
		case exchangeXTZToToken
		case exchangeTokenToXTZ
		case exchangeTokenToXTZ_Internal
		case delegation
		case reveal
		case orignation
		case approve
		case unknown
	}
	
	public struct TransactionLocation: Codable {
		public let alias: String?
		public let address: String
		
		public init(alias: String?, address: String) {
			self.alias = alias
			self.address = address
		}
	}
	
	public struct TransactionParameter: Codable {
		public let entrypoint: String
		public let value: [String: String]
		
		public init(entrypoint: String, value: [String: String]) {
			self.entrypoint = entrypoint
			self.value = value
		}
	}
	
	
	
	// MARK: - Properties
	
	// Properties from TzKT directly
	public let type: TransactionType
	public let id: Int
	public let level: Int
	public let timestamp: String
	public let hash: String
	public let counter: Int
	public let initiater: TransactionLocation?
	public let sender: TransactionLocation
	public var bakerFee: XTZAmount
	public var storageFee: XTZAmount
	public var allocationFee: XTZAmount
	public let target: TransactionLocation?
	public let prevDelegate: TransactionLocation?
	public let newDelegate: TransactionLocation?
	public var amount: TokenAmount
	public let parameter: TransactionParameter?
	public let status: TransactionStatus
	
	// Augmented properties
	public var subType: TransactionSubType = .unknown
	public var truncatedTimeInterval: TimeInterval = 0
	public var token: Token?
	public var secondaryToken: Token?
	public var secondaryAmount: TokenAmount?
	public var nativeTokenSendDestination: String?
	
	public var networkFee: XTZAmount {
		get {
			return (bakerFee + storageFee + allocationFee)
		}
	}
	
	
	
	// MARK: - Codable Protocol
	
	public enum CodingKeys: String, CodingKey {
		case type, id, level, timestamp, hash, counter, initiater, sender, bakerFee, storageFee, allocationFee, target, prevDelegate, newDelegate, amount, parameter, status, subType
	}
	
	public init(type: TransactionType, id: Int, level: Int, timestamp: String, hash: String, counter: Int, initiater: TransactionLocation?, sender: TransactionLocation, bakerFee: XTZAmount, storageFee: XTZAmount, allocationFee: XTZAmount, target: TransactionLocation?, prevDelegate: TransactionLocation?, newDelegate: TransactionLocation?, amount: TokenAmount, parameter: TransactionParameter?, status: TransactionStatus) {
		
		self.type = type
		self.id = id
		self.level = level
		self.timestamp = timestamp
		self.hash = hash
		self.counter = counter
		self.initiater = initiater
		self.sender = sender
		self.bakerFee = bakerFee
		self.storageFee = storageFee
		self.allocationFee = allocationFee
		self.target = target
		self.prevDelegate = prevDelegate
		self.newDelegate = newDelegate
		self.amount = amount
		self.parameter = parameter
		self.status = status
	}
	
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let typeString = try container.decode(String.self, forKey: .type)
		type = TransactionType(rawValue: typeString) ?? .unknown
		
		id = try container.decode(Int.self, forKey: .id)
		level = try container.decode(Int.self, forKey: .level)
		timestamp = try container.decode(String.self, forKey: .timestamp)
		hash = try container.decode(String.self, forKey: .hash)
		counter = try container.decode(Int.self, forKey: .counter)
		initiater = try? container.decode(TransactionLocation.self, forKey: .initiater)
		sender = try container.decode(TransactionLocation.self, forKey: .sender)
		target = try? container.decode(TransactionLocation.self, forKey: .target)
		prevDelegate = try? container.decode(TransactionLocation.self, forKey: .prevDelegate)
		newDelegate = try? container.decode(TransactionLocation.self, forKey: .newDelegate)
		parameter = try? container.decodeIfPresent(TransactionParameter.self, forKey: .parameter)
		
		
		// Handle numeric, XTZ amounts
		let bakerFeeDecimal = (try? container.decode(Decimal.self, forKey: .bakerFee))?.rounded(scale: 0, roundingMode: .down) ?? 0
		bakerFee = XTZAmount(fromRpcAmount: bakerFeeDecimal) ?? XTZAmount.zero()
		
		let storageFeeDecimal = (try? container.decode(Decimal.self, forKey: .storageFee))?.rounded(scale: 0, roundingMode: .down) ?? 0
		storageFee = XTZAmount(fromRpcAmount: storageFeeDecimal) ?? XTZAmount.zero()
		
		let allocationFeeDecimal = (try? container.decode(Decimal.self, forKey: .allocationFee))?.rounded(scale: 0, roundingMode: .down) ?? 0
		allocationFee = XTZAmount(fromRpcAmount: allocationFeeDecimal) ?? XTZAmount.zero()
		
		let amountDecimal = (try? container.decode(Decimal.self, forKey: .amount))?.rounded(scale: 0, roundingMode: .down) ?? 0
		amount = XTZAmount(fromRpcAmount: amountDecimal) ?? XTZAmount.zero()
		
		
		// Convert status to enum
		let statusString = try container.decode(String.self, forKey: .status)
		status = TransactionStatus(rawValue: statusString) ?? .unknown
	}
	
	
	
	// MARK: - CustomStringConvertible
	
	public var description: String {
		return "\(type.rawValue) - \(subType.rawValue): \nCounter: \(counter), level: \(level), Hash: \(hash), \nInitiater: \(initiater?.address ?? "-"), Sender: \(sender.address), Target: \(target?.address ?? "-"), Amount: \(amount.description) \(token?.symbol ?? "?"), SecondaryAmount: \(secondaryAmount?.description ?? "-") \(secondaryToken?.symbol ?? "?") \nParameter: \(String(describing: parameter)) \nTotal Fee: \(networkFee) XTZ\n"
	}
	
	
	// MARK: - Extra data
	
	/**
	Take in some details outside the scope of this model (the current wallet address and list of tokens), and do all the necessary processing to determine:
	- Is this `type: transaction` belonging to a send, receive, dexter exchange etc. event?
	- Extracting values from Michelson via the `parameters` such as the amount of an FA1.2 token sent
	- Exchange's become much more complex, as each piece is spread over multple seperate transactions. We will grab each piece belonging to each transaction,
	then later outside the scope of this model, the transactions will be merged together (they will all have the same `counter` as it is 1 operation, with multiple internal operations).
	e.g. in the case of XtzToToken, we will see two transactions, 1 of subtype `.exchangeXtzToToken` and another with the same `counter` of type `.nativeTokenReceive`.
	We will delete the `.nativeTokenReceive`, and copy the value into the exchange so as we only display 1 transaction item of "Exchange ... XTZ for ... Token", for easier handling of the data
	*/
	public func augmentTransaction(withUsersAddress usersAddress: String, andTokens tokens: [Token]) {
		let dateFormatterFrom = DateFormatter()
		dateFormatterFrom.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		let date = dateFormatterFrom.date(from: timestamp)
		truncatedTimeInterval = truncate(timeInterval: date?.timeIntervalSince1970 ?? 0)
		
		switch self.type {
			case TransactionType.delegation:
				subType = .delegation
				
			case TransactionType.origination:
				subType = .orignation
				
			case TransactionType.reveal:
				subType = .reveal
				
			case TransactionType.unknown:
				subType = .unknown
				
			case TransactionType.transaction:
				if let params = parameter {
					if params.entrypoint == "approve" {
						subType = .approve
						
					} else if (params.entrypoint == "transfer" || params.entrypoint == "default") && sender.address == usersAddress {
						subType = .nativeTokenSend
						token = tokenForTarget(address: target?.address, tokens: tokens)
						amount = tokenTransferAmount(ofToken: token) ?? TokenAmount.zeroBalance(decimalPlaces: token?.decimalPlaces ?? 0)
						nativeTokenSendDestination = faTokenSendDestination()
						
					} else if (params.entrypoint == "transfer" || params.entrypoint == "default") && initiater?.address != nil && sender.address != usersAddress && target?.address != usersAddress {
						subType = .exchangeTokenToXTZ_Internal // Internal operations used by Dexter to manage the sending / receiving of FA1.2 Tokens
						token = tokenForTarget(address: target?.address, tokens: tokens)
						amount = tokenTransferAmount(ofToken: token) ?? TokenAmount.zeroBalance(decimalPlaces: token?.decimalPlaces ?? 0)
						
					} else if (params.entrypoint == "transfer" || params.entrypoint == "default") && sender.address != usersAddress {
						subType = .nativeTokenReceive
						token = tokenForTarget(address: target?.address, tokens: tokens)
						amount = tokenTransferAmount(ofToken: token) ?? TokenAmount.zeroBalance(decimalPlaces: token?.decimalPlaces ?? 0)
						
					} else if params.entrypoint == "xtzToToken" {
						subType = .exchangeXTZToToken
						token = tokens[0]
						secondaryToken = tokenForTarget(address: target?.address, tokens: tokens)
						secondaryAmount = secondaryAmountForXTZToToken(ofToken: token) ?? TokenAmount.zeroBalance(decimalPlaces: token?.decimalPlaces ?? 0)
						
					} else if params.entrypoint == "tokenToXtz" {
						subType = .exchangeTokenToXTZ
						token = tokenForTarget(address: target?.address, tokens: tokens)
						amount = primaryAmountForTokenToXTZ()
						secondaryToken = tokens[0]
						secondaryAmount = secondaryAmountForTokenToXTZ(usersAddress: usersAddress)
						
					} else {
						subType = .unknown
					}
				} else {
					if sender.address == usersAddress {
						subType = .send
						token = tokens[0]
						
					} else if sender.address != usersAddress {
						subType = .receive
						token = tokens[0]
						
					} else {
						subType = .unknown
					}
				}
		}
	}
	
	public func tokenForTarget(address: String?, tokens: [Token]) -> Token? {
		guard let address = address else {
			return nil
		}
		
		for token in tokens {
			if token.tokenContractAddress == address /*|| token.dexterExchangeAddress == address*/ {
				return token
			}
		}
		
		return nil
	}
	
	private func truncate(timeInterval: TimeInterval) -> TimeInterval {
		let tempDate = Date(timeIntervalSince1970: timeInterval)
		let componenets = Calendar.current.dateComponents([.year, .month, .day], from: tempDate)
		let truncated = Calendar.current.date(from: componenets)
		
		return truncated?.timeIntervalSince1970 ?? 0
	}
	
	
	
	// MARK: - Amount Extractors
	
	public func tokenTransferAmount(ofToken: Token?) -> TokenAmount? {
		/*
		{\"prim\":\"Pair\",\"args\":[
			{\"bytes\":\"xxxxxxxxxx\"},
			{\"prim\":\"Pair\",\"args\":[
				{\"bytes\":\"xxxxxxxxxx\"},
				{\"int\":\"123456\"}		   <-- Target
			]}
		]}
		*/
		
		guard let param = parameter, let tokenString = param.value["value"] else {
			return nil
		}
		
		return TokenAmount(fromRpcAmount: tokenString, decimalPlaces: token?.decimalPlaces ?? 0)
	}
	
	/**
	There will be 2 transactions for XtzToToken and 3 for TokenToXTZ
	When doing XtzToToken, the returned token amount is in the Michelson of the second, internal transaction
	When doing tokenToXTZ, the XTZ is the `amount` of the third transaction, with the token amount being in the Michelson of the second (and the first, but easier to extract from second)
	*/
	
	public func secondaryAmountForXTZToToken(ofToken: Token?) -> TokenAmount? {
		guard let secondToken = secondaryToken, target?.address == secondToken.tokenContractAddress else {
			return nil
		}
		
		return tokenTransferAmount(ofToken: token)
	}
	
	public func primaryAmountForTokenToXTZ() -> TokenAmount {
		guard let primaryToken = token, target?.address == primaryToken.tokenContractAddress else {
			return TokenAmount.zeroBalance(decimalPlaces: token?.decimalPlaces ?? 0)
		}
		
		return tokenTransferAmount(ofToken: primaryToken) ?? TokenAmount.zeroBalance(decimalPlaces: primaryToken.decimalPlaces)
	}
	
	public func secondaryAmountForTokenToXTZ(usersAddress: String) -> TokenAmount? {
		if target?.address == usersAddress {
			return amount
		}
		
		return nil
	}
	
	public func faTokenSendDestination() -> String? {
		/*
		{\"prim\":\"Pair\",\"args\":[
			{\"string\":\"tz1......\"},
			{\"prim\":\"Pair\",\"args\":[
				{\"string\":\"tz1.....\"},   <-- Target
				{\"int\":\"123456\"}
			]}
		]}
		*/
		
		guard let param = parameter, let tz1Address = param.value["to"] else {
			return nil
		}
		
		return tz1Address
	}
}
