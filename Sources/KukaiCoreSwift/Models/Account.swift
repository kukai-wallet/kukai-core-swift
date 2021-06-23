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
public struct Account: Codable {
	
	/// The wallet address
	public let walletAddress: String
	
	/// The XTZ balance of the wallet
	public let xtzBalance: XTZAmount
	
	/// All the wallets FA1.2, FA2 funginble tokens
	public let tokens: [Token]
	
	/// All the wallets NFT's, grouped into parent FA2 objects so they can be displayed in groups or individaully
	public let nfts: [Token]
}
