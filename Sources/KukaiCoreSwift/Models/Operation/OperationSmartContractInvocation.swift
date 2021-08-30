//
//  OperationSmartContractInvocation.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 24/11/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import os.log

public enum OperationSmartContractInvocationError: Error {
	case invalidMichelsonValue
}

/// `Operation` subclass for calling an entrypoint of a smart contract on the Tezos network
public class OperationSmartContractInvocation: Operation {
	
	/// A list of standard entrypoints, frequently used by smart contracts
	enum StandardEntrypoint: String {
		case `default`
		case transfer
		case approve
		case xtzToToken
		case tokenToXtz
		case addLiquidity
		case removeLiquidity
	}
	
	
	/// The amount sent to the contract, usually zero, requirement of the network. Usually the amount is specified in the michelson
	public var amount: String = "0"
	
	/// The address of the contract that will be called
	public let destination: String
	
	/// Dictionary holding the `entrypoint` and `value` of the contract call
	public let parameters: [String: Encodable]
	
	
	
	enum CodingKeys: String, CodingKey {
		case amount
		case destination
		case parameters
		case entrypoint
		case value
	}
	
	
	/**
	Create an OperationOrigination.
	- parameter entrypoint: A String containing the name of the entrypoint to call.
	- parameter value: A String containing the JSON Michelson/Micheline needed by the given entrypoint.
	*/
	public init(source: String, amount: TokenAmount = TokenAmount.zeroBalance(decimalPlaces: 0), destinationContract: String, entrypoint: String, value: MichelsonPair?) {
		self.amount = amount.rpcRepresentation
		self.destination = destinationContract
		
		var tempDictionary: [String: Encodable] = [CodingKeys.entrypoint.rawValue: entrypoint]
		if let val = value {
			tempDictionary[CodingKeys.value.rawValue] = val
		}
		self.parameters = tempDictionary
		
		super.init(operationKind: .transaction, source: source)
	}
	
	/**
	Create a base operation.
	- parameter from: A decoder used to convert a data fromat (such as JSON) into the model object.
	*/
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		amount = try container.decode(String.self, forKey: .amount)
		destination = try container.decode(String.self, forKey: .destination)
		
		let parametersContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .parameters)
		let entrypoint = try parametersContainer.decode(String.self, forKey: .entrypoint)
		
		// Try to parse Michelson
		var michelsonValue: AbstractMichelson? = nil
		if let value = try? parametersContainer.decodeIfPresent(MichelsonPair.self, forKey: .value) {
			michelsonValue = value
			
		} else if let value = try? parametersContainer.decodeIfPresent(MichelsonValue.self, forKey: .value) {
			michelsonValue = value
			
		} else {
			throw OperationSmartContractInvocationError.invalidMichelsonValue
		}
		
		
		var tempDictionary: [String: Encodable] = [CodingKeys.entrypoint.rawValue: entrypoint]
		if let val = michelsonValue {
			tempDictionary[CodingKeys.value.rawValue] = val
		}
		parameters = tempDictionary
		
		
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
		
		var parametersContainer = container.nestedContainer(keyedBy: CodingKeys.self, forKey: .parameters)
		try parametersContainer.encode(parameters[CodingKeys.entrypoint.rawValue] as? String, forKey: .entrypoint)
		
		if let pair = parameters[CodingKeys.value.rawValue] as? MichelsonPair {
			try parametersContainer.encode(pair, forKey: .value)
			
		} else if let value = parameters[CodingKeys.value.rawValue] as? MichelsonValue {
			try parametersContainer.encode(value, forKey: .value)
		}
		
		try super.encode(to: encoder)
	}
	
	/**
	A function to check if two operations are equal.
	- parameter _: An `Operation` to compare against
	- returns: A `Bool` indicating the result.
	*/
	public func isEqual(_ op: OperationSmartContractInvocation) -> Bool {
		let superResult = super.isEqual(self as Operation)
		
		return superResult
			&& destination == op.destination
			&& parameters[CodingKeys.entrypoint.rawValue] as? String == op.parameters[CodingKeys.entrypoint.rawValue] as? String
			&& parameters[CodingKeys.value.rawValue] as? MichelsonPair == op.parameters[CodingKeys.value.rawValue] as? MichelsonPair
			&& parameters[CodingKeys.value.rawValue] as? MichelsonValue == op.parameters[CodingKeys.value.rawValue] as? MichelsonValue
	}
}
