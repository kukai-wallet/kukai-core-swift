//
//  OperationEndorsement.swift
//  
//
//  Created by Simon Mcloughlin on 31/08/2021.
//

import Foundation

/// Operation for endorsing a block
public class OperationEndorsement: Operation {
	
	/// Block level
	public let level: Int
	
	enum CodingKeys: String, CodingKey {
		case level
	}
	
	/**
	Init with wallet and block level
	*/
	public init(wallet: Wallet, level: Int) {
		self.level = level
		
		super.init(operationKind: .endorsement, source: wallet.address)
	}
	
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		level = try container.decode(Int.self, forKey: .level)
		
		try super.init(from: decoder)
	}
	
	public override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(level, forKey: .level)
		
		try super.encode(to: encoder)
	}
	
	public func isEqual(_ op: OperationEndorsement) -> Bool {
		let superResult = super.isEqual(self as Operation)
		
		return superResult &&
			level == op.level
	}
}
