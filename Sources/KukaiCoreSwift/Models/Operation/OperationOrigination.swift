//
//  OperationOrigination.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 20/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// `Operation` subclass for originating a contract on the Tezos network
public class OperationOrigination: Operation {
	
	/// The initial balance to give to the contract
	public let balance: String
	
	/// Dictionary holding the `code` and `storage` of the contract to create.
	public let script: [String: String]
	
	enum CodingKeys: String, CodingKey {
        case balance
		case script
    }
	
	/**
	Create an OperationOrigination.
	- parameter source: The address originating the contract and paying the fees.
	- parameter balance: How much XTZ to initiate the contract with.
	- parameter code: Micheline string containing the contract code.
	- parameter storage: Micheline string containing the initial storage of the contract.
	*/
	public init(source: String, balance: XTZAmount, code: String, storage: String) {
		self.balance = balance.rpcRepresentation
		self.script = [
			"code": code,
			"storage": storage
		]
		
		super.init(operationKind: .origination, source: source)
	}
	
	/**
	Create a base operation.
	- parameter from: A decoder used to convert a data fromat (such as JSON) into the model object.
	*/
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		balance = try container.decode(String.self, forKey: .balance)
		script = try container.decode([String: String].self, forKey: .script)
		
		try super.init(from: decoder)
	}
	
	/**
	Convert the object into a data format, such as JSON.
	- parameter to: An encoder that will allow conversions to multipel data formats.
	*/
	public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(balance, forKey: .balance)
		try container.encode(script, forKey: .script)
		
		try super.encode(to: encoder)
    }
	
	/**
	A function to check if two operations are equal.
	- parameter _: An `Operation` to compare against
	- returns: A `Bool` indicating the result.
	*/
	public func isEqual(_ op: OperationOrigination) -> Bool {
		let superResult = super.isEqual(self as Operation)
		
		return superResult &&
			balance == op.balance &&
			script == op.script
	}
}
