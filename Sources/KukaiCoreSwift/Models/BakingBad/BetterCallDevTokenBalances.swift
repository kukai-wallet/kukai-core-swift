//
//  BetterCallDevTokenBalances.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 25/03/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// A model matching the response that comes back from BetterCallDev's API: `v1/account/<network>/<address>/token_balances`
public struct BetterCallDevTokenBalances: Codable {
	public var balances: [BetterCallDevTokenBalance]
	public let total: Int
	
	public init(balances: [BetterCallDevTokenBalance], total: Int) {
		self.balances = balances
		self.total = total
	}
	
	/// Retrieve a specific balance object based on a contract address
	func balance(forAddress address: String) -> BetterCallDevTokenBalance? {
		for balance in balances {
			if balance.contract == address {
				return balance
			}
		}
		
		return nil
	}
}

/// A model matching the internal array type that comes back from BetterCallDev's API: `v1/account/<network>/<address>/token_balances`
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
	
	public init(token_id: Int, contract: String, name: String?, description: String?, symbol: String?, artifact_uri: String?, display_uri: String?, thumbnail_uri: String?, is_boolean_amount: Bool?, balance: TokenAmount, decimals: Int?) {
		self.token_id = token_id
		self.contract = contract
		self.name = name
		self.description = description
		self.symbol = symbol
		self.artifact_uri = artifact_uri
		self.display_uri = display_uri
		self.thumbnail_uri = thumbnail_uri
		self.is_boolean_amount = is_boolean_amount
		self.balance = balance
		self.decimals = decimals
	}
	
	/// Make shift attempt to determine if the balance belongs to an NFT or not, until a better solution can be found
	public func isNFT() -> Bool {
		return decimals == 0 && artifact_uri != nil
	}
	
	/// Process the returned amount as a `TokenAmount`
	public func amount() -> TokenAmount {
		balance.decimalPlaces = self.decimals ?? 0
		return balance
	}
}
