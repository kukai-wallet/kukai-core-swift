//
//  BetterCallDevAccount.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 12/03/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// A model matching the response that comes back from BetterCallDev's API: `v1/account/<network>/<address>`
public struct BetterCallDevAccount: Codable {
	
	/// The wallet address
	public let address: String
	
	/// The wallet's XTZ balance
	public let balance: XTZAmount
	
	/// The network chain name the wallet is active on
	public let network: TezosChainName
	
	/// Date string denoting the last time the user interacted with the account
	public let lastAction: String
	
	
	enum CodingKeys: String, CodingKey {
		case address
		case balance
		case network
		case lastAction = "last_action"
	}
	
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		address = try container.decode(String.self, forKey: .address)
		balance =  try container.decode(XTZAmount.self, forKey: .balance)
		lastAction =  try container.decode(String.self, forKey: .lastAction)
		
		let networkString = try container.decode(String.self, forKey: .network)
		network = TezosChainName(rawValue: networkString) ?? .unknwon
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(address, forKey: .address)
		try container.encode(balance, forKey: .balance)
		try container.encode(network.rawValue, forKey: .network)
		try container.encode(lastAction, forKey: .lastAction)
	}
}

