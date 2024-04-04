//
//  OperationTransaction.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 20/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

public enum OperationTransactionError: Error {
	case invalidMichelsonValue
}

/// `Operation` subclass for sending XTZ  to a destination
public class OperationTransaction: Operation {
	
	// MARK: - Types
	
	/// A list of standard entrypoints, frequently used by smart contracts
	enum StandardEntrypoint: String {
		case `default`
		case transfer
		case approve
		case updateOperators = "update_operators"
		case xtzToToken
		case tokenToXtz
		case addLiquidity
		case removeLiquidity
		
		case use
		case tezToTokenPayment
		case tokenToTezPayment
		case investLiquidity
		case divestLiquidity
		case withdrawProfit
		case execute 	// 3route
		case deposit 	// crunchy - stake
		case offer 		// OBJKT - make offer
		case bid 		// OBJKT - bid on auction
	}
	
	enum CodingKeys: String, CodingKey {
		case amount
		case destination
		case parameters
		case entrypoint
		case value
	}
	
	
	
	// MARK: - Properties
	
	/// The amount of XTZ to send. Use `TokenAmount().rpcRepresentation` to create this value
	public var amount: String
	
	// The destination address to recieve the funds
	public let destination: String
	
	/// Dictionary holding the `entrypoint` and `value` of the contract call
	public let parameters: [String: Any]?
	
	
	
	// MARK: - Constructors
	
	/**
	Create an OperationTransaction, to send an amount of token to a destination
	- parameter amount: The amount of XTZ to send. Use `TokenAmount().rpcRepresentation` to create this value.
	- parameter source: The address of the acocunt sending the operation.
	- parameter destination: The destination address to recieve the funds.
	*/
	public init(amount: TokenAmount, source: String, destination: String) {
		self.amount = amount.rpcRepresentation
		self.destination = destination
		self.parameters = nil
		
		super.init(operationKind: .transaction, source: source)
	}
	
	/**
	 Create an OperationTransaction, to invoke a smart contract call
	 - parameter amount: The amount of XTZ to send. Use `TokenAmount().rpcRepresentation` to create this value.
	 - parameter source: The address of the acocunt sending the operation.
	 - parameter parameters: A dictionary containing the michlelson JSON representation needed to invoke a smart contract. Should contain a key `entrypoint` with a string and `value` which can either be a dictionary of anything, or an array of dicitonaries of anything
	 - parameter destination: The destination address to recieve the funds.
	 */
	public init(amount: TokenAmount, source: String, destination: String, parameters: [String: Any]) {
		self.amount = amount.rpcRepresentation
		self.destination = destination
		self.parameters = parameters
		
		super.init(operationKind: .transaction, source: source)
	}
	
	
	
	// MARK: - Codable
	
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		amount = try container.decode(String.self, forKey: .amount)
		destination = try container.decode(String.self, forKey: .destination)
		parameters = try container.decodeIfPresent([String: Any].self, forKey: .parameters)
		
		try super.init(from: decoder)
	}
	
	public override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(amount, forKey: .amount)
		try container.encode(destination, forKey: .destination)
		
		// encodeIfPresent still printing "parameters: null". Not sure if apple bug or mistake
		if let params = parameters {
			try container.encode(params, forKey: .parameters)
		}
		
		try super.encode(to: encoder)
	}
	
	/**
	 A function to check if two operations are equal.
	 - parameter _: An `Operation` to compare against
	 - returns: A `Bool` indicating the result.
	 */
	public func isEqual(_ op: OperationTransaction) -> Bool {
		let superResult = super.isEqual(self as Operation)
		
		return superResult &&
		amount == op.amount &&
		destination == op.destination &&
		parameters?[CodingKeys.entrypoint.rawValue] as? String == op.parameters?[CodingKeys.entrypoint.rawValue] as? String &&
		parameters?[CodingKeys.value.rawValue] as? [String: String] == op.parameters?[CodingKeys.value.rawValue] as? [String: String] &&
		parameters?[CodingKeys.value.rawValue] as? [[String: String]] == op.parameters?[CodingKeys.value.rawValue] as? [[String: String]]
	}
}
