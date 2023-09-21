//
//  OperationProposals.swift
//  
//
//  Created by Simon Mcloughlin on 31/08/2021.
//

import Foundation

/// 
public class OperationProposals: Operation {
	
	/// The voting period
	public let period: Int
	
	/// List of proposal identifiers
	public let proposals: [String]
	
	enum CodingKeys: String, CodingKey {
		case period
		case proposals
	}
	
	/**
	Init with wallet, voting period and list of proposal identifiers
	*/
	public init(wallet: Wallet, period: Int, proposals: [String]) {
		self.period = period
		self.proposals = proposals
		
		super.init(operationKind: .proposals, source: wallet.address)
	}
	
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		period = try container.decode(Int.self, forKey: .period)
		proposals = try container.decode([String].self, forKey: .proposals)
		
		try super.init(from: decoder)
	}
	
	public override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(period, forKey: .period)
		try container.encode(proposals, forKey: .proposals)
		
		try super.encode(to: encoder)
	}
	
	public func isEqual(_ op: OperationProposals) -> Bool {
		let superResult = super.isEqual(self as Operation)
		
		return superResult &&
			period == op.period &&
			proposals == op.proposals
	}
}
