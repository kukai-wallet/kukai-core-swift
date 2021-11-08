//
//  TezToolApp.swift
//  
//
//  Created by Simon Mcloughlin on 04/11/2021.
//

import Foundation

public enum TezToolServiceType: String, Codable {
	case quipuswap = "QUIPUSWAP"
	case plenty = "PLENTY"
	case liquidityBaking = "LB"
	case unknown
	
	public init(from decoder: Decoder) throws {
		self = try TezToolServiceType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

public struct TezToolApp: Codable {
	
	let name: TezToolServiceType
	let type: String
	let pools: [TezToolAppPool]
}

public struct TezToolAppPool: Codable {
	
	let address: String
	let tokenType: String
}
