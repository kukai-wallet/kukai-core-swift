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
	public let floor_price: Decimal?
	public let twitter: String?
	public let website: String?
	public let owners: Decimal?
	public let editions: Decimal?
	public let creator: ObjktCreator?
	
	public func websiteURL() -> URL? {
		if let str = website {
			return URL(string: str)
			
		} else if let str = creator?.webiste {
			return URL(string: str)
		}
		
		return nil
	}
	
	public func twitterURL() -> URL? {
		if let str = twitter {
			return validTwitterURL(from: str)
			
		} else if let str = creator?.twitter {
			return validTwitterURL(from: str)
		}
		
		return nil
	}
	
	private func validTwitterURL(from: String) -> URL? {
		if from.contains("twitter.com") {
			return URL(string: from)
		} else {
			return URL(string: "https://www.twitter.com/\(from)")
		}
	}
	
	public func floorPrice() -> XTZAmount? {
		if let decimal = floor_price {
			return XTZAmount(fromRpcAmount: decimal.description)
		}
		
		return nil
	}
}

public struct ObjktCreator: Codable {
	public let address: String?
	public let alias: String?
	public let webiste: String?
	public let twitter: String?
}





/// GarpQL response for required data for a given token
public struct ObjktTokenReponse: Codable {
	public let token: [ObjktToken]
	public let event: [ObjktEvent]
	public let fa: [ObjktFa]
	
	public func isOnSale() -> Bool {
		return token.first?.listings_active.first?.seller_address != nil
	}
	
	public func onSalePrice() -> XTZAmount? {
		if let decimal = token.first?.listings_active.first?.price_xtz {
			return XTZAmount(fromRpcAmount: decimal.description)
		}
		
		return nil
	}
	
	public func lastSalePrice() -> XTZAmount? {
		if let decimal = token.first?.listing_sales.first?.price_xtz {
			return XTZAmount(fromRpcAmount: decimal.description)
		}
		
		return nil
	}
	
	public func floorPrice() -> XTZAmount? {
		if let decimal = fa.first?.floor_price {
			return XTZAmount(fromRpcAmount: decimal.description)
		}
		
		return nil
	}
}

/// Single token item
public struct ObjktToken: Codable {
	public let highest_offer: Decimal?
	public let lowest_ask: Decimal?
	public let metadata: String?
	public let name: String?
	public let attributes: [ObjktAttribute]
	public let listing_sales: [ObjktSale]
	public let listings_active: [ObjktListing]
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

public struct ObjktSale: Codable {
	public let price_xtz: Decimal?
	public let timestamp: String?
}

public struct ObjktListing: Codable {
	public let seller_address: String?
	public let price_xtz: Decimal?
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
