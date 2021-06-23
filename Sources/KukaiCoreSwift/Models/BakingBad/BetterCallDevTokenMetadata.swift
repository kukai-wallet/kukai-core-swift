//
//  BetterCallDevTokenMetadata.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 10/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// A model matching the response that comes back from BetterCallDev's API: `v1/tokens/<network>/metadata?contract=<address>`
public class BetterCallDevTokenMetadata: Codable {
	
	public let contract: String
	public let network: String
	public let token_id: Int
	public let symbol: String
	public let name: String
	public let decimals: Int
	
	public var faVersion: FaVersion?
	public var imageURL: URL?
}
