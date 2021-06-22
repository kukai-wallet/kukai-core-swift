//
//  File.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 20/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// Structure representing the HEAD of the blockchain
public struct BlockchainHead: Codable {
	
	enum CodingKeys: String, CodingKey {
        case `protocol`
		case chainID = "chain_id"
		case hash
    }
	
	/// The current protocol version string
	public let `protocol`: String
	
	/// The current chainID being used
	public let chainID: String
	
	/// The current hash or branch being used
	public let hash: String
}
