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
	public let symbol: String?
	public let name: String?
	public let decimals: Int?
	public let `decription`: String?
	public let artifact_uri: String?
	public let display_uri: String?
	public let thumbnail_uri: String?
	public let is_transferable: Bool?
	public let is_boolean_amount: Bool?
	
	public var faVersion: FaVersion?
	
	/// Make shift attempt to determine if the balance belongs to an NFT or not, until a better solution can be found
	public func isNFT() -> Bool {
		return decimals == 0 && artifact_uri != nil
	}
}
