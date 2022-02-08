//
//  TokenTests.swift
//  
//
//  Created by Simon Mcloughlin on 31/08/2021.
//

import XCTest
@testable import KukaiCoreSwift

class TokenTests: XCTestCase {

	override func setUpWithError() throws {
		
	}

	override func tearDownWithError() throws {
		
	}
	
	
	func testToken() {
		let token = Token(name: "test1", symbol: "T", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount(fromNormalisedAmount: 3, decimalPlaces: 4), thumbnailURL: URL(string: "ipfs://abcdefgh1234"), tokenContractAddress: "KT1abc", tokenId: nil, nfts: nil)
		
		// TODO: replace
		//let nft = NFT(fromBcdBalance: bcdBalance)
		//let token2 = Token(name: "test2", symbol: "F", tokenType: .nonfungible, faVersion: .fa2, balance: TokenAmount.zero(), thumbnailURL: URL(string: "ipfs://abcdefgh1234"), tokenContractAddress: "KT1abc", tokenId: 0, nfts: [nft])
		
		
		XCTAssert(token.name == "test1", token.name ?? "")
		XCTAssert(token.symbol == "T", token.symbol)
		XCTAssert(token.tokenType == .fungible, token.tokenType.rawValue)
		XCTAssert(token.tokenId == nil)
		
		/*
		XCTAssert(token2.name == "test2", token2.name ?? "")
		XCTAssert(token2.symbol == "F", token2.symbol)
		XCTAssert(token2.tokenType == .nonfungible, token2.tokenType.rawValue)
		XCTAssert(token2.tokenId == 0)
		*/
	}
}
