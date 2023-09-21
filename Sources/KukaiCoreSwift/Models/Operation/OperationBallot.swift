//
//  OperationBallot.swift
//  
//
//  Created by Simon Mcloughlin on 31/08/2021.
//

import Foundation

/// Operation to submit a ballot on an upcoming proposal
public class OperationBallot: Operation {
	
	/// Enum matching the available ballot options
	public enum Ballot: String, Codable {
		case nay
		case yay
		case pass
	}
	
	/// The voting period
	public let period: Int
	
	/// The identifier of the proposa;
	public let proposal: String
	
	/// The wallet holders vote
	public let ballot: Ballot
	
	enum CodingKeys: String, CodingKey {
		case period
		case proposal
		case ballot
	}
	
	/**
	Init with wallet, period, proposal and ballot
	*/
	public init(wallet: Wallet, period: Int, proposal: String, ballot: Ballot) {
		self.period = period
		self.proposal = proposal
		self.ballot = ballot
		
		super.init(operationKind: .ballot, source: wallet.address)
	}
	
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		period = try container.decode(Int.self, forKey: .period)
		proposal = try container.decode(String.self, forKey: .proposal)
		ballot = try container.decode(Ballot.self, forKey: .ballot)
		
		try super.init(from: decoder)
	}
	
	public override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(period, forKey: .period)
		try container.encode(proposal, forKey: .proposal)
		try container.encode(ballot, forKey: .ballot)
		
		try super.encode(to: encoder)
	}
	
	public func isEqual(_ op: OperationBallot) -> Bool {
		let superResult = super.isEqual(self as Operation)
		
		return superResult &&
			period == op.period &&
			proposal == op.proposal &&
			ballot == op.ballot
	}
}
