//
//  Objkt.swift
//  
//
//  Created by Simon Mcloughlin on 25/05/2023.
//

import Foundation

/// GarpQL bulk response for a group of collections
public struct ObjktCollections: Codable {
	public let fa: [ObjktCollection]
}

/// Single collection item
public struct ObjktCollection: Codable {
	public let contract: String
	public let name: String?
	public let logo: String?
}





/// GarpQL response for required data for a given token
public struct ObjktTokenReponse: Codable {
	public let token: [ObjktToken]
	public let event: [ObjktEvent]
	public let fa: [ObjktFa]
}

/// Single token item
public struct ObjktToken: Codable {
	public let highest_offer: Decimal?
	public let lowest_ask: Decimal?
	public let metadata: String?
	public let name: String?
	public let attributes: [ObjktAttribute]
}

public struct ObjktAttribute: Codable {
	public let attribute: ObjktAttributeData
}

public struct ObjktAttributeData: Codable {
	public let name: String
	public let value: String
	public let attribute_counts: [ObjktAttributeCounts]
}

public struct ObjktAttributeCounts: Codable {
	public let editions: Decimal
}

/// Single event item
public struct ObjktEvent: Codable {
	public let price_xtz: Decimal?
}

/// Single FA item
public struct ObjktFa: Codable {
	public let editions: Decimal?
	public let floor_price: Decimal?
}
