//
//  TezToolApp.swift
//  
//
//  Created by Simon Mcloughlin on 04/11/2021.
//

import Foundation

/// Enum to map to the supported dApp's / exhcnages from TezTools
public enum TezToolServiceType: String, Codable {
	case quipuswap = "QUIPUSWAP"
	case liquidityBaking = "LB"
	case unknown
	
	public init(from decoder: Decoder) throws {
		self = try TezToolServiceType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

/// Wrapper around the dApp information from TezTools
public struct TezToolApp: Codable {
	
	/// Identifying the app
	public let name: TezToolServiceType
	
	/// The type of dApp / purpose
	public let type: String
	
	/// The available token pools
	public let pools: [TezToolAppPool]
}

/// Data available for each token pool
public struct TezToolAppPool: Codable {
	
	/// The Exchange contract address
	public let address: String
	
	/// The type of token contained in the pool
	public let tokenType: String
}
