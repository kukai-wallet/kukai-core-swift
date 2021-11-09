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
		case xtzToToken
		case tokenToXtz
		case addLiquidity
		case removeLiquidity
		case use
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
	public let parameters: [String: Encodable]?
	
	
	
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
	- parameter entrypoint: The name of the entrypoint to invoke on a smart contract
	- parameter value: The MichelsonPair / MichlesonValue to send to the give entrypoint
	- parameter destination: The destination address to recieve the funds.
	*/
	public init(amount: TokenAmount, source: String, destination: String, entrypoint: String, value: AbstractMichelson) {
		self.amount = amount.rpcRepresentation
		self.destination = destination
		
		var tempDictionary: [String: Encodable] = [CodingKeys.entrypoint.rawValue: entrypoint]
		tempDictionary[CodingKeys.value.rawValue] = value
		self.parameters = tempDictionary
		
		super.init(operationKind: .transaction, source: source)
	}
	
	
	
	// MARK: - Codable
	
	/**
	Create a base operation.
	- parameter from: A decoder used to convert a data fromat (such as JSON) into the model object.
	*/
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		amount = try container.decode(String.self, forKey: .amount)
		destination = try container.decode(String.self, forKey: .destination)
		
		// Check if an entrypoint / parameters for smart contract calls are present
		if let parametersContainer = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .parameters),
		   let entrypoint = try? parametersContainer.decode(String.self, forKey: .entrypoint) {
			
			// Try to parse Michelson
			var michelsonValue: AbstractMichelson? = nil
			if let value = try? parametersContainer.decodeIfPresent(MichelsonPair.self, forKey: .value) {
				michelsonValue = value
				
			} else if let value = try? parametersContainer.decodeIfPresent(MichelsonValue.self, forKey: .value) {
				michelsonValue = value
				
			} else {
				throw OperationTransactionError.invalidMichelsonValue
			}
			
			
			var tempDictionary: [String: Encodable] = [CodingKeys.entrypoint.rawValue: entrypoint]
			if let val = michelsonValue {
				tempDictionary[CodingKeys.value.rawValue] = val
			}
			parameters = tempDictionary
		} else {
			parameters = nil
		}
		
		try super.init(from: decoder)
	}
	
	/**
	Convert the object into a data format, such as JSON.
	- parameter to: An encoder that will allow conversions to multipel data formats.
	*/
	public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(amount, forKey: .amount)
		try container.encode(destination, forKey: .destination)
		
		if let params = parameters {
			var parametersContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .parameters)
			try parametersContainer.encode(params[CodingKeys.entrypoint.rawValue] as? String, forKey: .entrypoint)
			
			if let pair = params[CodingKeys.value.rawValue] as? MichelsonPair {
				try parametersContainer.encode(pair, forKey: .value)
				
			} else if let value = params[CodingKeys.value.rawValue] as? MichelsonValue {
				try parametersContainer.encode(value, forKey: .value)
			}
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
			parameters?[CodingKeys.value.rawValue] as? MichelsonPair == op.parameters?[CodingKeys.value.rawValue] as? MichelsonPair &&
			parameters?[CodingKeys.value.rawValue] as? MichelsonValue == op.parameters?[CodingKeys.value.rawValue] as? MichelsonValue
	}
}
