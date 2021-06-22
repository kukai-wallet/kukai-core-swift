//
//  BetterCallDevTokenBalances.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 25/03/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

public struct BetterCallDevTokenBalances: Codable {
	public var balances: [BetterCallDevTokenBalance]
	public let total: Int
}

public struct BetterCallDevTokenBalance: Codable {
	
	public let token_id: Int
	public let contract: String
	public let name: String?
	public let `description`: String?
	public let symbol: String?
	public let artifact_uri: String?
	public let display_uri: String?
	public let thumbnail_uri: String?
	public let is_boolean_amount: Bool?
	
	private let balance: TokenAmount
	private let decimals: Int?
	
	public func isNFT() -> Bool {
		return is_boolean_amount ?? false
	}
	
	public func amount() -> TokenAmount {
		balance.decimalPlaces = self.decimals ?? 0
		return balance
	}
}
