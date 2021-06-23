//
//  BetterCallDevContract.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 10/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// A model matching the response that comes back from BetterCallDev's API: `v1/contract/<network>/<address>`
public struct BetterCallDevContract: Codable {
	
	/// The network the contract is active on
	public let network: String
	
	/// The KT1 address of the contract
	public let address: String
	
	/// The manager address of the contract
	public let manager: String
	
	/// string tags to denote useful infomration about the contract. Currently used to denote which FA version the contract supports
	public let tags: [String]
	
	
	
	
	/// Extract the FA version of the contract, from its `tags` property
	func faVersionFromTags() -> FaVersion {
		for tag in tags {
			if let faEnum = FaVersion(rawValue: tag) {
				return faEnum
			}
		}
		
		return .unknown
	}
}
