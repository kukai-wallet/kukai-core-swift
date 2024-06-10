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
		let token = Token(name: "test1", symbol: "T", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount(fromNormalisedAmount: 3, decimalPlaces: 4), thumbnailURL: URL(string: "ipfs://abcdefgh1234"), tokenContractAddress: "KT1abc", tokenId: nil, nfts: nil, mintingTool: nil)
		
		let tzktBalance = TzKTBalance(balance: "1", token: TzKTBalanceToken(contract: TzKTAddress(alias: "Test Alias", address: "KT1abc"), tokenId: "0", standard: .fa2, totalSupply: "1", metadata: nil))
		let nft = NFT(fromTzKTBalance: tzktBalance)
		let token2 = Token(name: "test2", symbol: "F", tokenType: .nonfungible, faVersion: .fa2, balance: TokenAmount.zero(), thumbnailURL: URL(string: "ipfs://abcdefgh1234"), tokenContractAddress: "KT1abc", tokenId: 0, nfts: [nft], mintingTool: nil)
		
		
		XCTAssert(token.name == "test1", token.name ?? "")
		XCTAssert(token.symbol == "T", token.symbol)
		XCTAssert(token.tokenType == .fungible, token.tokenType.rawValue)
		XCTAssert(token.tokenId == nil)
		
		XCTAssert(token2.name == "test2", token2.name ?? "")
		XCTAssert(token2.symbol == "F", token2.symbol)
		XCTAssert(token2.tokenType == .nonfungible, token2.tokenType.rawValue)
		XCTAssert(token2.tokenId == 0)
		
		let xtzToken = Token.xtz()
		XCTAssert(xtzToken.isXTZ() == true)
		XCTAssert(xtzToken.symbol == "XTZ")
		XCTAssert(xtzToken.tokenContractAddress == nil)
		
		
		XCTAssert(token.description == "{Symbol: T, Name: test1, Type: fungible, FaVersion: fa1_2, NFT count: 0}", token.description)
		
		let placeholder = Token.placeholder(fromNFT: nft, amount: .init(fromNormalisedAmount: 1, decimalPlaces: 0), thumbnailURL: nil)
		XCTAssert(placeholder.name == "Unknown Token", placeholder.name ?? "-")
		XCTAssert(placeholder.balance.description == "1", placeholder.balance.description)
		XCTAssert(placeholder.availableBalance.description == "1", placeholder.availableBalance.description)
		
		XCTAssert(token == token)
		XCTAssert(token != token2)
		
		XCTAssert(token.id == "KT1abc", token.id)
		XCTAssert(token2.id == "KT1abc:0", token2.id)
	}
}
