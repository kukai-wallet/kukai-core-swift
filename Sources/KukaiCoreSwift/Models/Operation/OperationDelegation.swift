//
//  OperationDelegation.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 20/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// `Operation` subclass for delegating an account to a baker
public class OperationDelegation: Operation {
	
	/// The baker to delegate too, or nil to undelegate
	public let delegate: String?
	
	enum CodingKeys: String, CodingKey {
        case delegate
    }
	
	/**
	Create an OperationDelegation.
	- parameter source: The address of the acocunt sending the operation.
	- parameter delegate: Optional. The address of the baker to delegate to, or nil to undelegate the source address.
	*/
	public init(source: String, delegate: String?) {
		self.delegate = delegate
		
		super.init(operationKind: .delegation, source: source)
	}
	
	/**
	Create a base operation.
	- parameter from: A decoder used to convert a data fromat (such as JSON) into the model object.
	*/
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		delegate = try container.decodeIfPresent(String.self, forKey: .delegate)
		
		try super.init(from: decoder)
	}
	
	/**
	Convert the object into a data format, such as JSON.
	- parameter to: An encoder that will allow conversions to multipel data formats.
	*/
	public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
		if let del = delegate {
			try container.encodeIfPresent(del, forKey: .delegate)
		}
		
		try super.encode(to: encoder)
    }
	
	/**
	A function to check if two operations are equal.
	- parameter _: An `Operation` to compare against
	- returns: A `Bool` indicating the result.
	*/
	public func isEqual(_ op: OperationDelegation) -> Bool {
		let superResult = super.isEqual(self as Operation)
		
		return superResult &&
			delegate == op.delegate
	}
}
