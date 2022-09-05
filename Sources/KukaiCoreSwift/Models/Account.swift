//
//  Account.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 10/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// Fetching all the account balances is a lengthy task, involving many requests and parsing different structures.
/// This struct abstract the developer away from knowing all these details, and instead allows developers to access wallets balances in a more normal approach
public struct Account: Codable, Hashable {
	
	/// The wallet address
	public let walletAddress: String
	
	/// The XTZ balance of the wallet
	public let xtzBalance: XTZAmount
	
	/// All the wallets FA1.2, FA2 funginble tokens
	public let tokens: [Token]
	
	/// All the wallets NFT's, grouped into parent FA2 objects so they can be displayed in groups or individaully
	public let nfts: [Token]
	
	/// All the wallets Defi, Liquidity Tokens
	public let liquidityTokens: [DipDupPositionData]
	
	/// TzKT object containing baker details + status
	public let delegate: TzKTAccountDelegate?
	
	/// The block level that the delegate was set
	public let delegationLevel: Decimal?
	
	
	/// Basic init to default properties to zero / empty, so that optionals can be avoided on a key model throughout an app
	public init(walletAddress: String) {
		self.walletAddress = walletAddress
		self.xtzBalance = .zero()
		self.tokens = []
		self.nfts = []
		self.liquidityTokens = []
		self.delegate = nil
		self.delegationLevel = 0
	}
	
	/// Full init
	public init(walletAddress: String, xtzBalance: XTZAmount, tokens: [Token], nfts: [Token], liquidityTokens: [DipDupPositionData], delegate: TzKTAccountDelegate?, delegationLevel: Decimal?) {
		self.walletAddress = walletAddress
		self.xtzBalance = xtzBalance
		self.tokens = tokens
		self.nfts = nfts
		self.liquidityTokens = liquidityTokens
		self.delegate = delegate
		self.delegationLevel = delegationLevel
	}
	
	/// Conforming to `Hashable` to enable working with UITableViewDiffableDataSource
	public func hash(into hasher: inout Hasher) {
		hasher.combine(walletAddress)
	}
}

extension Account: Identifiable {
	public var id: String {
		walletAddress
	}
}
