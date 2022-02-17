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
	
	/// The Tezos address of the delegated baker, nil if none selected
	public let bakerAddress: String?
	
	/// If the baker has an alias (human friendly name) on the blockchain
	public let bakerAlias: String?
	
	/// Basic init to default properties to zero / empty, so that optionals can be avoided on a key model throughout an app
	public init(walletAddress: String) {
		self.walletAddress = walletAddress
		self.xtzBalance = .zero()
		self.tokens = []
		self.nfts = []
		self.bakerAddress = nil
		self.bakerAlias = nil
	}
	
	/// Full init
	public init(walletAddress: String, xtzBalance: XTZAmount, tokens: [Token], nfts: [Token], bakerAddress: String? = nil, bakerAlias: String? = nil) {
		self.walletAddress = walletAddress
		self.xtzBalance = xtzBalance
		self.tokens = tokens
		self.nfts = nfts
		self.bakerAddress = bakerAddress
		self.bakerAlias = bakerAlias
	}
}

extension Account: Identifiable {
	public var id: String {
		walletAddress
	}
}
