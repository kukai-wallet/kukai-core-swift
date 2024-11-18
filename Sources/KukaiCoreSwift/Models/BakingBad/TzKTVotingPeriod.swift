//
//  TzKTVotingPeriod.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 18/11/2024.
//

import Foundation

public enum TzKTVotingKind: String, Codable {
	case proposal
	case exploration
	case testing
	case promotion
	case adoption
	case unknown
	
	public init(from decoder: Decoder) throws {
		self = try .init(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

public enum TzKTVotingStatus: String, Codable {
	case active
	case noProposals = "no_proposals"
	case noQuorum = "no_quorum"
	case noSupermajority = "no_supermajority"
	case noSingleWinner = "no_single_winner"
	case success
	case unknown
	
	public init(from decoder: Decoder) throws {
		self = try .init(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

public struct TzKTVotingPeriod: Codable {
	
	let index: Int
	let epoch: Int
	let firstLevel: Decimal
	let lastLevel: Decimal
	let kind: TzKTVotingKind
	let status: TzKTVotingStatus?
}
