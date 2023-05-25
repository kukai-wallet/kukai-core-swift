//
//  Objkt.swift
//  
//
//  Created by Simon Mcloughlin on 25/05/2023.
//

import Foundation

/// GarpQL bulk response for a group of collections
public struct ObjktCollections: Codable {
	let fa: [ObjktCollection]
}

/// Single collection item
public struct ObjktCollection: Codable {
	let contract: String
	let name: String?
	let logo: String?
}





/// GarpQL response for required data for a given token
public struct ObjktTokenReponse: Codable {
	let token: [ObjktToken]
	let event: [ObjktEvent]
	let fa: [ObjktFa]
}

/// Single token item
public struct ObjktToken: Codable {
	let highest_offer: Decimal?
	let lowest_ask: Decimal?
	let metadata: String?
	let name: String?
	let attributes: [ObjktAttribute]
}

public struct ObjktAttribute: Codable {
	let attribute: ObjktAttributeData
}

public struct ObjktAttributeData: Codable {
	let name: String
	let value: String
	let attribute_counts: [ObjktAttributeCounts]
}

public struct ObjktAttributeCounts: Codable {
	let editions: Decimal
}

/// Single event item
public struct ObjktEvent: Codable {
	let price_xtz: Decimal?
}

/// Single FA item
public struct ObjktFa: Codable {
	let editions: Decimal?
	let floor_price: Decimal?
}
