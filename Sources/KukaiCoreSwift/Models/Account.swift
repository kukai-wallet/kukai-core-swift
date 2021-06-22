//
//  Account.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 10/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

public struct Account: Codable {
	
	public let walletAddress: String
	public let xtzBalance: XTZAmount
	public let tokens: [Token]
	public let nfts: [Token]
}
