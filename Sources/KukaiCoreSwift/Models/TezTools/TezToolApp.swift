//
//  TezToolApp.swift
//  
//
//  Created by Simon Mcloughlin on 04/11/2021.
//

import Foundation

public enum TezToolServiceType: String, Codable {
	case quipuswap = "QUIPUSWAP"
	case liquidityBaking = "LB"
	case unknown
	
	public init(from decoder: Decoder) throws {
		self = try TezToolServiceType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

public struct TezToolApp: Codable {
	
	public let name: TezToolServiceType
	public let type: String
	public let pools: [TezToolAppPool]
}

public struct TezToolAppPool: Codable {
	
	public let address: String
	public let tokenType: String
}
