//
//  BetterCallDevAccount.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 12/03/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

public struct BetterCallDevAccount: Codable {
	
	public let address: String
	public let balance: XTZAmount
	public let network: TezosChainName
	
	
	enum CodingKeys: String, CodingKey {
		case address
		case balance
		case network
	}
	
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		address = try container.decode(String.self, forKey: .address)
		balance =  try container.decode(XTZAmount.self, forKey: .balance)
		
		let networkString = try container.decode(String.self, forKey: .network)
		network = TezosChainName(rawValue: networkString) ?? .unknwon
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(address, forKey: .address)
		try container.encode(balance, forKey: .balance)
		try container.encode(network.rawValue, forKey: .network)
	}
}

