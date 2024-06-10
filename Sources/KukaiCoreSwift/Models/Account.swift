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
		self.tokens = []
		self.nfts = []
		self.recentNFTs = []
		self.liquidityTokens = []
		self.delegate = nil
		self.delegationLevel = 0
	}
	
	/// Full init
	public init(walletAddress: String, xtzBalance: XTZAmount, xtzStakedBalance: XTZAmount, xtzUnstakedBalance: XTZAmount, tokens: [Token], nfts: [Token], recentNFTs: [NFT], liquidityTokens: [DipDupPositionData], delegate: TzKTAccountDelegate?, delegationLevel: Decimal?) {
		self.walletAddress = walletAddress
		self.xtzBalance = xtzBalance
		self.xtzStakedBalance = xtzStakedBalance
		self.xtzUnstakedBalance = xtzUnstakedBalance
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
	
	public init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.walletAddress = try container.decode(String.self, forKey: .walletAddress)
		self.xtzBalance = try container.decode(XTZAmount.self, forKey: .xtzBalance)
		self.xtzStakedBalance = (try? container.decode(XTZAmount.self, forKey: .xtzStakedBalance)) ?? .zero() // TODO: optionality can be removed before app store release
		self.xtzUnstakedBalance = (try? container.decode(XTZAmount.self, forKey: .xtzUnstakedBalance)) ?? .zero()
		self.tokens = try container.decode([Token].self, forKey: .tokens)
		self.nfts = try container.decode([Token].self, forKey: .nfts)
		self.recentNFTs = try container.decode([NFT].self, forKey: .recentNFTs)
		self.liquidityTokens = try container.decode([DipDupPositionData].self, forKey: .liquidityTokens)
		self.delegate = try container.decodeIfPresent(TzKTAccountDelegate.self, forKey: .delegate)
		self.delegationLevel = try container.decodeIfPresent(Decimal.self, forKey: .delegationLevel)
	}
	
	enum CodingKeys: CodingKey {
		case walletAddress
		case xtzBalance
		case xtzStakedBalance
		case xtzUnstakedBalance
		case tokens
		case nfts
		case recentNFTs
		case liquidityTokens
		case delegate
		case delegationLevel
	}
	
	public func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.walletAddress, forKey: .walletAddress)
		try container.encode(self.xtzBalance, forKey: .xtzBalance)
		try container.encode(self.xtzStakedBalance, forKey: .xtzStakedBalance)
		try container.encode(self.xtzUnstakedBalance, forKey: .xtzUnstakedBalance)
		try container.encode(self.tokens, forKey: .tokens)
		try container.encode(self.nfts, forKey: .nfts)
		try container.encode(self.recentNFTs, forKey: .recentNFTs)
		try container.encode(self.liquidityTokens, forKey: .liquidityTokens)
		try container.encodeIfPresent(self.delegate, forKey: .delegate)
		try container.encodeIfPresent(self.delegationLevel, forKey: .delegationLevel)
	}
}

extension Account: Identifiable {
	public var id: String {
		walletAddress
	}
}
