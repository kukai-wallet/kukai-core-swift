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
	
	/// The staked (locked) XTZ balance of the wallet
	public let xtzStakedBalance: XTZAmount
	
	/// The unstaked (pending unlock) XTZ balance of the wallet
	public let xtzUnstakedBalance: XTZAmount
	
	/// The finalised XTZ balance of the wallet. Needs to be feteched seperately, will default to empty
	public let xtzFinalisedBalance: XTZAmount?
	
	/// All the wallets FA1.2, FA2 funginble tokens
	public let tokens: [Token]
	
	/// All the wallets NFT's, grouped into parent FA2 objects so they can be displayed in groups or individaully
	public let nfts: [Token]
	
	/// 10 most recent NFTs to hit the wallet
	public var recentNFTs: [NFT]
	
	/// All the wallets Defi, Liquidity Tokens
	public let liquidityTokens: [DipDupPositionData]
	
	/// TzKT object containing baker details + status
	public let delegate: TzKTAccountDelegate?
	
	/// The block level that the delegate was set
	public let delegationLevel: Decimal?
	
	/// The total available (or spendable) balance of the account
	public var availableBalance: XTZAmount {
		get {
			return (xtzBalance - xtzStakedBalance) - xtzUnstakedBalance
		}
	}
	
	/// Basic init to default properties to zero / empty, so that optionals can be avoided on a key model throughout an app
	public init(walletAddress: String) {
		self.walletAddress = walletAddress
		self.xtzBalance = .zero()
		self.xtzStakedBalance = .zero()
		self.xtzUnstakedBalance = .zero()
		self.xtzFinalisedBalance = .zero()
		self.tokens = []
		self.nfts = []
		self.recentNFTs = []
		self.liquidityTokens = []
		self.delegate = nil
		self.delegationLevel = 0
	}
	
	/// Full init
	public init(walletAddress: String, xtzBalance: XTZAmount, xtzStakedBalance: XTZAmount, xtzUnstakedBalance: XTZAmount, xtzFinalisedBalance: XTZAmount?, tokens: [Token], nfts: [Token], recentNFTs: [NFT], liquidityTokens: [DipDupPositionData], delegate: TzKTAccountDelegate?, delegationLevel: Decimal?) {
		self.walletAddress = walletAddress
		self.xtzBalance = xtzBalance
		self.xtzStakedBalance = xtzStakedBalance
		self.xtzUnstakedBalance = xtzUnstakedBalance
		self.xtzFinalisedBalance = xtzFinalisedBalance
		self.tokens = tokens
		self.nfts = nfts
		self.recentNFTs = recentNFTs
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
