//
//  OperationDoubleEndorsementEvidence.swift
//  
//
//  Created by Simon Mcloughlin on 31/08/2021.
//

import Foundation

/// Operation to report a baker trying to endorse a block twice
public class OperationDoubleEndorsementEvidence: Operation {
	
	/// Internal struct used to amtch expected struct of data
	public struct InlinedEndorsement: Codable, Equatable {
		public let branch: String
		public let operations: Content
		public let signature: String?
		
		public struct Content: Codable, Equatable {
			public let kind: OperationKind
			public let level: Int
		}
	}
	
	/// The first endorsement
	public let op1: InlinedEndorsement
	
	/// The second endorsement (should be matching details of first)
	public let op2: InlinedEndorsement
	
	enum CodingKeys: String, CodingKey {
		case op1
		case op2
	}
	
	/**
	Init with wallet and 2 suspected endorsements
	*/
	public init(wallet: Wallet, op1: InlinedEndorsement, op2: InlinedEndorsement) {
		self.op1 = op1
		self.op2 = op2
		
		super.init(operationKind: .double_endorsement_evidence, source: wallet.address)
	}
	
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		op1 = try container.decode(InlinedEndorsement.self, forKey: .op1)
		op2 = try container.decode(InlinedEndorsement.self, forKey: .op2)
		
		try super.init(from: decoder)
	}
	
	public override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(op1, forKey: .op1)
		try container.encode(op2, forKey: .op2)
		
		try super.encode(to: encoder)
	}
	
	public func isEqual(_ op: OperationDoubleEndorsementEvidence) -> Bool {
		let superResult = super.isEqual(self as Operation)
		
		return superResult &&
			op1 == op.op1 &&
			op2 == op.op2
	}
}
