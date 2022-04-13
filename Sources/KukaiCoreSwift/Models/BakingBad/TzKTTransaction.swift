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
	
	public struct TransactionLocation: Codable {
		public let alias: String?
		public let address: String
		
		public init(alias: String?, address: String) {
			self.alias = alias
			self.address = address
		}
	}
	
	
	
	// MARK: - Properties
	
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
	public let parameter: [String: String]?
	public let status: TransactionStatus
	
	public let date: Date?
	
	
	
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
		case type, id, level, timestamp, hash, counter, initiater, sender, bakerFee, storageFee, allocationFee, target, prevDelegate, newDelegate, amount, parameter, status
	}
	
	public init(type: TransactionType, id: Int, level: Int, timestamp: String, hash: String, counter: Int, initiater: TransactionLocation?, sender: TransactionLocation, bakerFee: XTZAmount, storageFee: XTZAmount, allocationFee: XTZAmount, target: TransactionLocation?, prevDelegate: TransactionLocation?, newDelegate: TransactionLocation?, amount: TokenAmount, parameter: [String: String]?, status: TransactionStatus) {
		
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
	
	public init(from decoder: Decoder) throws {
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
	
	/**
	 The TzKT transaction API doesn't provide all the info needed to normalise Token amounts. It only gives address and rpc amount.
	 Burried inside the michelson, the dex contract needs to be told the token id, and the `target` will contain the address.
	 This function will try to extract address, token id and rpc amount and return them in the standard objects, so that they can be used in conjuction with other functions to fetch the decimal data.
	 e.g. DipDup client can fetch all tokens from dexes, containing all token info. Using the address and id, the rest could be found via that, assuming zero for anything else (such as NFTs)
	 */
	public func getFaTokenTransferData() -> TzKTTransactionGroup.TokenDetails? {
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
			return TzKTTransactionGroup.TokenDetails(
				token: Token(name: "", symbol: "", tokenType: .fungible, faVersion: .fa2, balance: .zero(), thumbnailURL: nil, tokenContractAddress: contractAddress, tokenId: Decimal(string: tokenId), nfts: nil),
				amount: TokenAmount(fromRpcAmount: amount, decimalPlaces: 0) ?? .zero()
			)
		}
		
		// FA1 token
		if let json = parameterValueAsDict(),
		   let amount = json["value"] as? String,
		   let contractAddress = target?.address
		{
			return TzKTTransactionGroup.TokenDetails(
				token: Token(name: "", symbol: "", tokenType: .fungible, faVersion: .fa1_2, balance: .zero(), thumbnailURL: nil, tokenContractAddress: contractAddress, tokenId: 0, nfts: nil),
				amount: TokenAmount(fromRpcAmount: amount, decimalPlaces: 0) ?? .zero()
			)
		}
		
		// Different type of dex contract
		if let json = parameterValueAsDict(),
		   let amount = json["amount"] as? String,
		   let contractAddress = target?.address
		{
			return TzKTTransactionGroup.TokenDetails(
				token: Token(name: "", symbol: "", tokenType: .fungible, faVersion: .fa1_2, balance: .zero(), thumbnailURL: nil, tokenContractAddress: contractAddress, tokenId: 0, nfts: nil),
				amount: TokenAmount(fromRpcAmount: amount, decimalPlaces: 0) ?? .zero()
			)
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
