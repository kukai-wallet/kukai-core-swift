//
//  OperationTransaction.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 20/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// `Operation` subclass for sending XTZ  to a destination
public class OperationTransaction: Operation {
	
	/// The amount of XTZ to send. Use `TokenAmount().rpcRepresentation` to create this value
	public var amount: String
	
	// The destination address to recieve the funds
	public let destination: String
	
	enum CodingKeys: String, CodingKey {
        case amount
		case destination
    }
	
	/**
	Create an OperationTransaction.
	- parameter amount: The amount of XTZ to send. Use `TokenAmount().rpcRepresentation` to create this value.
	- parameter source: The address of the acocunt sending the operation.
	- parameter destination: The destination address to recieve the funds.
	*/
	public init(amount: TokenAmount, source: String, destination: String) {
		self.amount = amount.rpcRepresentation
		self.destination = destination
		
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
			destination == op.destination
	}
}
