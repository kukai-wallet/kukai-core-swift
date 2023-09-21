//
//  OperationKind.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 20/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// Enum representing the various kinds of supported `Operation`'s
public enum OperationKind: String, Codable {
	case transaction
	case reveal
	case delegation
	case origination
	case activate_account
	case endorsement
	case seed_nonce_revelation
	case double_endorsement_evidence
	case double_baking_evidence
	case proposals
	case ballot
	case unknown
	
	enum CodingKeys: CodingKey {
        case rawValue
    }
	
	/**
	Create a base operation.
	- parameter from: A decoder used to convert a data fromat (such as JSON) into the model object.
	*/
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let rawValue = try container.decode(String.self, forKey: .rawValue)
		
		self = OperationKind(rawValue: rawValue) ?? .unknown
    }
    
	/**
	Convert the object into a data format, such as JSON.
	- parameter to: An encoder that will allow conversions to multipel data formats.
	*/
	public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.rawValue, forKey: .rawValue)
    }
}
