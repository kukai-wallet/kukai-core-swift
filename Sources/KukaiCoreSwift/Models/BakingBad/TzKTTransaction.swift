//
//  TzKtTransaction.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 26/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// A model matching the response that comes back from TzKT's API: `v1/accounts/<address>/operations`
public struct TzKTTransaction: Codable, CustomStringConvertible, Hashable, Identifiable {
	
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
		case receive
		case delegate
		case reveal
		case exchange
		case contractCall
		case unknown
	}
	
	
	
	// MARK: - Properties
	
	public let type: TransactionType
	public let id: Decimal
	public let level: Decimal
	public let timestamp: String
	public let hash: String
	public let counter: Decimal
	public let initiater: TzKTAddress?
	public let sender: TzKTAddress
	public var bakerFee: XTZAmount
	public var storageFee: XTZAmount
	public var allocationFee: XTZAmount
	public let target: TzKTAddress?
	public let prevDelegate: TzKTAddress?
	public let newDelegate: TzKTAddress?
	public var amount: TokenAmount
	public let parameter: [String: String]?
	public let status: TransactionStatus
	
	public let date: Date?
	public var tzktBalanceToken: TzKTBalanceToken? = nil
	public var subType: TransactionSubType? = nil
	public var entrypointCalled: String? = nil
	public var primaryToken: Token? = nil
	
	
	
	// MARK: - CustomStringConvertible
	
	public var description: String {
		return "\(type.rawValue): \nCounter: \(counter), level: \(level), Hash: \(hash), \nInitiater: \(initiater?.address ?? "-"), Sender: \(sender.address), Target: \(target?.address ?? "-"), Amount: \(amount.description)\n"
	}
	
	
	
	// MARK: - Hashable
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	public static func == (lhs: TzKTTransaction, rhs: TzKTTransaction) -> Bool {
		return lhs.id == rhs.id
	}
	
	
	
	// MARK: - Codable Protocol
	
	public enum CodingKeys: String, CodingKey {
		case type, id, level, timestamp, hash, counter, initiater, sender, bakerFee, storageFee, allocationFee, target, prevDelegate, newDelegate, amount, parameter, status, subType, entrypointCalled, primaryToken
	}
	
	public init(type: TransactionType, id: Decimal, level: Decimal, timestamp: String, hash: String, counter: Decimal, initiater: TzKTAddress?, sender: TzKTAddress, bakerFee: XTZAmount, storageFee: XTZAmount, allocationFee: XTZAmount, target: TzKTAddress?, prevDelegate: TzKTAddress?, newDelegate: TzKTAddress?, amount: TokenAmount, parameter: [String: String]?, status: TransactionStatus) {
		
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
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		date = dateFormatter.date(from: timestamp)
	}
	
	public init(from: TzKTTokenTransfer) {
		let sourceAddress = from.from == nil ? from.token.contract : from.from
		
		self.type = .transaction
		self.id = from.id
		self.level = from.level
		self.timestamp = from.timestamp
		
		// Hash is essential to be able to group batch transactions together, the only item shared between TzKTTokenTransfer and TzKTTransaction that matches this usecase, is level + timestamp
		// But need to be careful to not rely on it for anything else, like viewing in explorer
		self.hash = from.level.description + "_" + from.timestamp
		self.counter = 0
		self.initiater = sourceAddress
		self.sender = sourceAddress ?? from.token.contract
		self.bakerFee = .zero()
		self.storageFee = .zero()
		self.allocationFee = .zero()
		self.target = from.to ?? from.token.contract
		self.prevDelegate = nil
		self.newDelegate = nil
		self.amount = from.amount
		self.parameter = nil
		self.status = .applied
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		date = dateFormatter.date(from: timestamp)
		
		self.tzktBalanceToken = from.token
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let typeString = try container.decode(String.self, forKey: .type)
		type = TransactionType(rawValue: typeString) ?? .unknown
		
		id = try container.decode(Decimal.self, forKey: .id)
		level = try container.decode(Decimal.self, forKey: .level)
		timestamp = try container.decode(String.self, forKey: .timestamp)
		hash = try container.decode(String.self, forKey: .hash)
		counter = try container.decode(Decimal.self, forKey: .counter)
		initiater = try? container.decode(TzKTAddress.self, forKey: .initiater)
		sender = try container.decode(TzKTAddress.self, forKey: .sender)
		target = try? container.decode(TzKTAddress.self, forKey: .target)
		prevDelegate = try? container.decode(TzKTAddress.self, forKey: .prevDelegate)
		newDelegate = try? container.decode(TzKTAddress.self, forKey: .newDelegate)
		parameter = try? container.decodeIfPresent([String: String].self, forKey: .parameter)
		
		
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
		
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
		date = dateFormatter.date(from: timestamp)
		
		
		// Check for additional data
		if let subtypeString = try container.decodeIfPresent(String.self, forKey: .subType) {
			subType = TransactionSubType(rawValue: subtypeString) ?? .unknown
			entrypointCalled = try container.decodeIfPresent(String.self, forKey: .entrypointCalled)
			primaryToken = try container.decodeIfPresent(Token.self, forKey: .primaryToken)
		}
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(type.rawValue, forKey: .type)
		try container.encode(id, forKey: .id)
		try container.encode(level, forKey: .level)
		try container.encode(timestamp, forKey: .timestamp)
		try container.encode(hash, forKey: .hash)
		try container.encode(counter, forKey: .counter)
		try container.encode(initiater, forKey: .initiater)
		try container.encode(sender, forKey: .sender)
		try container.encode(target, forKey: .target)
		try container.encode(prevDelegate, forKey: .prevDelegate)
		try container.encode(newDelegate, forKey: .newDelegate)
		try container.encode(parameter, forKey: .parameter)
		try container.encode(bakerFee.rpcRepresentation, forKey: .bakerFee)
		try container.encode(storageFee.rpcRepresentation, forKey: .storageFee)
		try container.encode(allocationFee.rpcRepresentation, forKey: .allocationFee)
		try container.encode(amount.rpcRepresentation, forKey: .amount)
		try container.encode(status.rawValue, forKey: .status)
		
		// Check for additional data
		try container.encodeIfPresent(subType, forKey: .subType)
		try container.encodeIfPresent(entrypointCalled, forKey: .entrypointCalled)
		try container.encodeIfPresent(primaryToken, forKey: .primaryToken)
	}
	
	
	
	// MARK: - Helpers
	
	public func parameterValueAsArray() -> [Any]? {
		return parameterValueAsType(type: [Any].self)
	}
	
	public func parameterValueAsDict() -> [String: Any]? {
		return parameterValueAsType(type: [String: Any].self)
	}
	
	public func parameterValueAsArrayOfDictionary() -> [[String: Any]]? {
		return parameterValueAsType(type: [[String: Any]].self)
	}
	
	public func parameterValueAsType<T>(type: T.Type) -> T? {
		guard let params = self.parameter, let val = params["value"], let json = try? JSONSerialization.jsonObject(with: val.data(using: .utf8) ?? Data(), options: .fragmentsAllowed) as? T else {
			return nil
		}
		
		return json
	}
	
	public func getEntrypoint() -> String? {
		guard let params = self.parameter, let entrypoint = params["entrypoint"] else {
			return nil
		}
		
		return entrypoint
	}
	
	public mutating func processAdditionalData(withCurrentWalletAddress currentWalletAddress: String) {
		if let entrypoint = self.getEntrypoint(), entrypoint == "transfer" {
			self.entrypointCalled = entrypoint
			self.primaryToken = createPrimaryToken()
			
			if self.sender.address != currentWalletAddress && self.initiater?.address != currentWalletAddress {
				self.subType = .receive
			} else {
				self.subType = .send
			}
			
		} else if let entrypoint = getEntrypoint() {
			self.subType = .contractCall
			self.entrypointCalled = entrypoint
			
		} else {
			if self.target?.address == currentWalletAddress {
				self.subType = .receive
				self.primaryToken = createPrimaryToken()
				
			} else if self.target?.address != currentWalletAddress {
				self.subType = .send
				self.primaryToken = createPrimaryToken()
				
			} else if self.type == .delegation {
				self.subType = .delegate
				
			} else if self.type == .reveal {
				self.subType = .reveal
				
			} else {
				self.subType = .unknown
			}
		}
	}
	
	public func createPrimaryToken() -> Token? {
		if let balanceToken = self.tzktBalanceToken {
			return Token(from: balanceToken, andRpcAmount: self.amount.rpcRepresentation)
			
		} else if self.amount != .zero() {
			return Token.xtz(withAmount: amount)
			
		} else if let token = self.getFaTokenTransferData() {
			return token
		}
		
		return nil
	}
	
	/**
	 The TzKT transaction API doesn't provide all the info needed to normalise Token amounts. It only gives address and rpc amount.
	 Burried inside the michelson, the dex contract needs to be told the token id, and the `target` will contain the address.
	 This function will try to extract address, token id and rpc amount and return them in the standard objects, so that they can be used in conjuction with other functions to fetch the decimal data.
	 e.g. DipDup client can fetch all tokens from dexes, containing all token info. Using the address and id, the rest could be found via that, assuming zero for anything else (such as NFTs)
	 */
	public func getFaTokenTransferData() -> Token? {
		guard getEntrypoint() == "transfer" else {
			return nil
		}
		
		// FA2 token
		if let json = parameterValueAsArrayOfDictionary(),
		   let txs = json.first?["txs"] as? [[String: Any]],
		   let obj = txs.first as? [String: String],
		   let amount = obj["amount"],
		   let tokenId = obj["token_id"],
		   let contractAddress = target?.address
		{
			let amount = TokenAmount(fromRpcAmount: amount, decimalPlaces: 0) ?? .zero()
			let token = Token(name: "", symbol: "", tokenType: .fungible, faVersion: .fa2, balance: amount, thumbnailURL: nil, tokenContractAddress: contractAddress, tokenId: Decimal(string: tokenId), nfts: nil)
			return token
		}
		
		// FA1 token
		if let json = parameterValueAsDict(),
		   let amount = json["value"] as? String,
		   let contractAddress = target?.address
		{
			let amount = TokenAmount(fromRpcAmount: amount, decimalPlaces: 0) ?? .zero()
			let token = Token(name: "", symbol: "", tokenType: .fungible, faVersion: .fa1_2, balance: amount, thumbnailURL: nil, tokenContractAddress: contractAddress, tokenId: nil, nfts: nil)
			return token
		}
		
		// Different type of dex contract
		if let json = parameterValueAsDict(),
		   let amount = json["amount"] as? String,
		   let contractAddress = target?.address
		{
			let amount = TokenAmount(fromRpcAmount: amount, decimalPlaces: 0) ?? .zero()
			let token = Token(name: "", symbol: "", tokenType: .fungible, faVersion: .fa1_2, balance: amount, thumbnailURL: nil, tokenContractAddress: contractAddress, tokenId: nil, nfts: nil)
			return token
		}
		
		return nil
	}
	
	public func getTokenTransferDestination() -> String? {
		guard getEntrypoint() == "transfer" else {
			return nil
		}
		
		// FA2 token
		if let json = parameterValueAsArrayOfDictionary(),
		   let txs = json.first?["txs"] as? [[String: Any]],
		   let obj = txs.first as? [String: String],
		   let amount = obj["to_"]
		{
			return amount
		}
		
		// FA1 token
		if let json = parameterValueAsDict(),
		   let amount = json["to"] as? String
		{
			return amount
		}
		
		return nil
	}
}
