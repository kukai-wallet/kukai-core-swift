//
//  RunOperationPayload.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 25/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// Payload object needed when sending operations to .../run_operation
public struct RunOperationPayload: Codable {
	
	enum CodingKeys: String, CodingKey {
        case chainID = "chain_id"
		case operation
    }
	
	let chainID: String
	let operation: OperationPayload
}
