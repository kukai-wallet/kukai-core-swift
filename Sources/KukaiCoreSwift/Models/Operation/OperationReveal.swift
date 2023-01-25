//
//  OperationReveal.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 20/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// `Operation` subclass for revealing a publickey to the network.
public class OperationReveal: Operation {
	
	public let publicKey: String
	
	enum CodingKeys: String, CodingKey {
        case publicKey = "public_key"
    }
	
	/**
	Create an OperationReveal.
	- parameter wallet: The `Wallet` object, whose publicKey needs to be revealed.
	*/
	public init(wallet: Wallet) {
		self.publicKey = wallet.publicKeyBase58encoded()
		
		super.init(operationKind: .reveal, source: wallet.address)
	}
	
	/**
	 Create an OperationReveal.
	 - parameter base58EncodedPublicKey: The `Wallet` object, whose publicKey needs to be revealed.
	 - parameter walletAddress: The `Wallet` object, whose publicKey needs to be revealed.
	 */
	public init(base58EncodedPublicKey: String, walletAddress: String) {
		self.publicKey = base58EncodedPublicKey
		
		super.init(operationKind: .reveal, source: walletAddress)
	}
	
	/**
	Create a base operation.
	- parameter from: A decoder used to convert a data fromat (such as JSON) into the model object.
	*/
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		publicKey = try container.decode(String.self, forKey: .publicKey)
		
		try super.init(from: decoder)
	}
	
	/**
	Convert the object into a data format, such as JSON.
	- parameter to: An encoder that will allow conversions to multipel data formats.
	*/
	public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(publicKey, forKey: .publicKey)
		
		try super.encode(to: encoder)
    }
	
	/**
	A function to check if two operations are equal.
	- parameter _: An `Operation` to compare against
	- returns: A `Bool` indicating the result.
	*/
	public func isEqual(_ op: OperationReveal) -> Bool {
		let superResult = super.isEqual(self as Operation)
		
		return superResult &&
			publicKey == op.publicKey
	}
}
