//
//  OperationSeedNonceRevelation.swift
//  
//
//  Created by Simon Mcloughlin on 31/08/2021.
//

import Foundation

/// Operation to reveal seed nonce to blockchain
public class OperationSeedNonceRevelation: Operation {
	
	/// Block level
	public let level: Int
	
	// String representation of nonce
	public let nonce: String
	
	enum CodingKeys: String, CodingKey {
		case level
		case nonce
	}
	
	/**
	Init with wallet object, block level, and nonce
	*/
	public init(wallet: Wallet, level: Int, nonce: String) {
		self.level = level
		self.nonce = nonce
		
		super.init(operationKind: .seed_nonce_revelation, source: wallet.address)
	}
	
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		level = try container.decode(Int.self, forKey: .level)
		nonce = try container.decode(String.self, forKey: .nonce)
		
		try super.init(from: decoder)
	}
	
	public override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(level, forKey: .level)
		try container.encode(nonce, forKey: .nonce)
		
		try super.encode(to: encoder)
	}
	
	public func isEqual(_ op: OperationSeedNonceRevelation) -> Bool {
		let superResult = super.isEqual(self as Operation)
		
		return superResult &&
			level == op.level &&
			nonce == op.nonce
	}
}
