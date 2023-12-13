//
//  ObjktClientTests.swift
//  
//
//  Created by Simon Mcloughlin on 25/05/2023.
//

import XCTest
@testable import KukaiCoreSwift

class ObjktClientTests: XCTestCase {
	
	func testResolveCollections() {
		let expectation = XCTestExpectation(description: "objkt-resolve-collections")
		
		var addresses: [String] = ["KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBNK"]
		for index in 0..<504 {
			addresses.append("KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBN\(index)")
		}
		
		MockConstants.shared.objktClient.resolveCollectionsAll(addresses: addresses) { result in
			guard let res = try? result.get() else {
				XCTFail(result.getFailure().description)
				expectation.fulfill()
				return
			}
			
			XCTAssert(res)
			
			let collections = MockConstants.shared.objktClient.collections
			XCTAssert(collections.keys.count == 4, collections.keys.count.description) // stub data contains duplicates, 3 keys means it successfully executed a second request to get the additional batch of 5 items
			XCTAssert(collections["KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBNK"]?.name == "Crystal Moon Crew", collections["KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBNK"]?.name ?? "-")
			XCTAssert(collections["KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBNK"]?.logo == "ipfs://QmSN7P1MrC1uk9rbinqqtNBw3eoKH2rXWUu9bJjDDCLURL", collections["KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBNK"]?.logo ?? "-")
			XCTAssert(collections["KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBNK"]?.contract == "KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBNK", collections["KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBNK"]?.contract ?? "-")
			
			XCTAssert(collections["KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBNK"]?.floorPrice()?.description == "0.16", collections["KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBNK"]?.floorPrice()?.description ?? "-")
			XCTAssert(collections["KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBNK"]?.twitterURL()?.absoluteString == "https://www.twitter.com/PixelPotus", collections["KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBNK"]?.twitterURL()?.absoluteString ?? "-")
			XCTAssert(collections["KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBNK"]?.websiteURL()?.absoluteString == "https://www.pixelpotus.com", collections["KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBNK"]?.websiteURL()?.absoluteString ?? "-")
			
			XCTAssert(collections["blah9"]?.floorPrice()?.description == "0.13", collections["blah9"]?.floorPrice()?.description ?? "-")
			XCTAssert(collections["blah9"]?.twitterURL() == nil, collections["blah9"]?.twitterURL()?.absoluteString ?? "-")
			XCTAssert(collections["blah9"]?.websiteURL()?.absoluteString == "https://collectibles.manutd.com/", collections["blah9"]?.websiteURL()?.absoluteString ?? "-")
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 30)
		
		let unresolved = MockConstants.shared.objktClient.unresolvedCollections(addresses: ["KT1PETpupvqJVSTEayqCDchHWFXDPD4TyBNK", "not-in-list"])
		XCTAssert(unresolved.count == 1, unresolved.count.description)
		XCTAssert(unresolved[0] == "not-in-list", unresolved[0].description)
	}
	
	func testResolveToken() {
		let expectation = XCTestExpectation(description: "objkt-resolve-token")
		
		MockConstants.shared.objktClient.resolveToken(address: "KT1XNJ67F3JN2cmq6s1LmqtVg7gy9tCcN4E2", tokenId: 15, forOwnerWalletAddress: MockConstants.hdWallet.address) { result in
			guard let res = try? result.get() else {
				XCTFail(result.getFailure().description)
				expectation.fulfill()
				return
			}
			
			XCTAssert(res.data?.token.count == 1, res.data?.token.count.description ?? "-")
			XCTAssert(res.data?.token[0].highest_offer == nil, res.data?.token[0].highest_offer?.description ?? "-")
			XCTAssert(res.data?.token[0].lowest_ask == 60000, res.data?.token[0].lowest_ask?.description ?? "-")
			XCTAssert(res.data?.token[0].attributes[0].attribute.name == "Colour", res.data?.token[0].attributes[0].attribute.name ?? "-")
			XCTAssert(res.data?.token[0].attributes[0].attribute.value == "Red", res.data?.token[0].attributes[0].attribute.value ?? "-")
			XCTAssert(res.data?.token[0].attributes[0].attribute.attribute_counts[0].editions == 54423, res.data?.token[0].attributes[0].attribute.attribute_counts[0].editions.description ?? "-")
			
			XCTAssert(res.data?.event.count == 1, res.data?.event.count.description ?? "-")
			XCTAssert(res.data?.event[0].price_xtz == 80000, res.data?.event[0].price_xtz?.description ?? "-")
			
			XCTAssert(res.data?.fa.count == 1, res.data?.fa.count.description ?? "-")
			XCTAssert(res.data?.fa[0].editions == 69202, res.data?.fa[0].editions?.description ?? "-")
			XCTAssert(res.data?.fa[0].floor_price == 60000, res.data?.fa[0].floor_price?.description ?? "-")
			
			XCTAssertTrue(res.data?.isOnSale() == true)
			XCTAssertTrue(res.data?.onSalePrice()?.description == "5", res.data?.onSalePrice()?.description ?? "-")
			XCTAssertTrue(res.data?.lastSalePrice()?.description == "0.795", res.data?.lastSalePrice()?.description ?? "-")
			XCTAssertTrue(res.data?.floorPrice()?.description == "0.06", res.data?.floorPrice()?.description ?? "-")
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 30)
		
		let token = MockConstants.shared.objktClient.tokenResponse(forAddress: "KT1XNJ67F3JN2cmq6s1LmqtVg7gy9tCcN4E2", tokenId: 15)
		XCTAssert(token != nil)
		XCTAssert(token?.token[0].attributes[0].attribute.name == "Colour", token?.token[0].attributes[0].attribute.name ?? "-")
		XCTAssert(token?.token[0].attributes[0].attribute.value == "Red", token?.token[0].attributes[0].attribute.value ?? "-")
	}
}
