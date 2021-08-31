//
//  OperationDoubleBakingEvidence.swift
//  
//
//  Created by Simon Mcloughlin on 31/08/2021.
//

import Foundation

/// Operation to report a baking of baking the same block twice
public class OperationDoubleBakingEvidence: Operation {
	
	/// The block header of the first baked block
	public let bh1: OperationBlockHeader
	
	/// The block header of the second baked block
	public let bh2: OperationBlockHeader
	
	enum CodingKeys: String, CodingKey {
		case bh1
		case bh2
	}
	
	/**
	Init with wallet and two block headers
	*/
	public init(wallet: Wallet, bh1: OperationBlockHeader, bh2: OperationBlockHeader) {
		self.bh1 = bh1
		self.bh2 = bh2
		
		super.init(operationKind: .double_baking_evidence, source: wallet.address)
	}
	
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		bh1 = try container.decode(OperationBlockHeader.self, forKey: .bh1)
		bh2 = try container.decode(OperationBlockHeader.self, forKey: .bh2)
		
		try super.init(from: decoder)
	}
	
	public override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(bh1, forKey: .bh1)
		try container.encode(bh2, forKey: .bh2)
		
		try super.encode(to: encoder)
	}
	
	public func isEqual(_ op: OperationDoubleBakingEvidence) -> Bool {
		let superResult = super.isEqual(self as Operation)
		
		return superResult &&
			bh1 == op.bh1 &&
			bh2 == op.bh2
	}
}
