//
//  NFT.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 10/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

public struct NFT: Codable {
	
	public let tokenId: Int
	public let parentContract: String
	public let name: String
	public let symbol: String
	public let `description`: String
	public let artifactURI: String?
	public let displayURI: String?
	public let thumbnailURI: String?
	
	public init(fromBcdBalance bcd: BetterCallDevTokenBalance) {
		tokenId = bcd.token_id
		parentContract = bcd.contract
		name = bcd.name ?? ""
		symbol = bcd.symbol ?? ""
		description = bcd.description ?? ""
		artifactURI = bcd.artifact_uri
		displayURI = bcd.display_uri
		thumbnailURI = bcd.thumbnail_uri
	}
}
