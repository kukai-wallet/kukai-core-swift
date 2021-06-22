//
//  OperationActivateAccount.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 24/02/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// `Operation` subclass for revealing a publickey to the network.
public class OperationActivateAccount: Operation {
	
	public let publicKey: String
	public let secret: String
	
	enum CodingKeys: String, CodingKey {
		case publicKey = "pkh"
		case secret
	}
	
	/**
	Create an OperationActivateAccount.
	- parameter wallet: The `Wallet` object, whose publicKey will be used to activate on the network
	- parameter andSecret: The secret supplied in JSON file
	*/
	public init(wallet: Wallet, andSecret: String) {
		self.publicKey = wallet.address
		self.secret = andSecret
		
		super.init(operationKind: .activate_account, source: wallet.address)
	}
	
	/**
	Create a base operation.
	- parameter from: A decoder used to convert a data fromat (such as JSON) into the model object.
	*/
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		publicKey = try container.decode(String.self, forKey: .publicKey)
		secret = try container.decode(String.self, forKey: .secret)
		
		try super.init(from: decoder)
	}
	
	/**
	Convert the object into a data format, such as JSON.
	- parameter to: An encoder that will allow conversions to multipel data formats.
	*/
	public override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(publicKey, forKey: .publicKey)
		try container.encode(secret, forKey: .secret)
		
		try super.encode(to: encoder)
	}
	
	/**
	A function to check if two operations are equal.
	- parameter _: An `Operation` to compare against
	- returns: A `Bool` indicating the result.
	*/
	public func isEqual(_ op: OperationActivateAccount) -> Bool {
		let superResult = super.isEqual(self as Operation)
		
		return superResult &&
			publicKey == op.publicKey &&
			secret == op.secret
	}
}
