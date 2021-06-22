//
//  BetterCallDevContract.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 10/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

public struct BetterCallDevContract: Codable {
	
	public let network: String
	public let address: String
	public let manager: String
	public let tags: [String]
	
	func faVersionFromTags() -> FaVersion {
		for tag in tags {
			if let faEnum = FaVersion(rawValue: tag) {
				return faEnum
			}
		}
		
		return .unknown
	}
}
