//
//  TorusAuthServiceTests.swift
//  
//
//  Created by Simon Mcloughlin on 12/07/2021.
//

import XCTest
import TorusSwiftDirectSDK
@testable import KukaiCoreSwift

/*
class TorusAuthServiceTests: XCTestCase {
	
	let torusService = TorusAuthService(networkType: .testnet, networkService: MockConstants.shared.networkService, nativeRedirectURL: "native://mock1", googleRedirectURL: "https://mock2", browserRedirectURL: "https://mock3",
										utils: MockTorusUtils(),
										fetchNodeDetails: MockFetchNodeDetails(proxyAddress: "0x4023d2a0D330bF11426B12C6144Cfb96B7fa6183", network: .ROPSTEN))
	
	override func setUpWithError() throws {
	}

	override func tearDownWithError() throws {
	}
	
	func testCreateAppleWallet() {
		let expectation = XCTestExpectation(description: "torus apple")
		let appleVerifier = SubVerifierDetails(loginType: .web, loginProvider: .apple, clientId: "mock-apple-id", verifierName: "mock-apple-name", redirectURL: "native://mock1", jwtParams: ["domain": "torus-test.auth0.com"])
		let mockedTorus = MockTorusSwiftDirectSDK(aggregateVerifierType: .singleLogin, aggregateVerifierName: "mock-apple-name", subVerifierDetails: [appleVerifier], network: .ROPSTEN, loglevel: .none)
		
		torusService.createWallet(from: .apple, displayOver: nil, mockedTorus: mockedTorus) { result in
			
			switch result {
				case .success(let wallet):
					XCTAssert(wallet.address == MockConstants.linearWalletSecp256k1.address, wallet.address)
					XCTAssert(wallet.authProvider == .apple, wallet.authProvider.rawValue)
					XCTAssert(wallet.socialUsername == "Test McTestface", wallet.socialUsername ?? "-")
					XCTAssert(wallet.socialUserId == "blah@privaterelay.appleid.com", wallet.socialUserId ?? "-")
					XCTAssert(wallet.socialProfilePictureURL?.absoluteString == "https://www.redditstatic.com/avatars/avatar_default_06_0DD3BB.png", wallet.socialProfilePictureURL?.absoluteString ?? "-")
					XCTAssert(wallet.mnemonic == nil)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
	
		wait(for: [expectation], timeout: 3)
	}
	
	func testCreateTwitterWallet() {
		let expectation = XCTestExpectation(description: "torus twitter")
		let appleVerifier = SubVerifierDetails(loginType: .web, loginProvider: .twitter, clientId: "mock-twitter-id", verifierName: "mock-twitter-name", redirectURL: "native://mock1", jwtParams: ["domain": "torus-test.auth0.com"])
		let mockedTorus = MockTorusSwiftDirectSDK(aggregateVerifierType: .singleLogin, aggregateVerifierName: "mock-twitter-name", subVerifierDetails: [appleVerifier], network: .ROPSTEN, loglevel: .none)
		
		torusService.createWallet(from: .twitter, displayOver: nil, mockedTorus: mockedTorus) { result in
			
			switch result {
				case .success(let wallet):
					XCTAssert(wallet.address == MockConstants.linearWalletSecp256k1.address, wallet.address)
					XCTAssert(wallet.authProvider == .twitter, wallet.authProvider.rawValue)
					XCTAssert(wallet.socialUsername == "testy", wallet.socialUsername ?? "-")
					XCTAssert(wallet.socialUserId == "twitter|123456789", wallet.socialUserId ?? "-")
					XCTAssert(wallet.socialProfilePictureURL?.absoluteString == "https://www.redditstatic.com/avatars/avatar_default_06_0DD3BB.png", wallet.socialProfilePictureURL?.absoluteString ?? "-")
					XCTAssert(wallet.mnemonic == nil)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
	
		wait(for: [expectation], timeout: 3)
	}
	
	func testCreateRedditWallet() {
		let expectation = XCTestExpectation(description: "torus reddit")
		let appleVerifier = SubVerifierDetails(loginType: .web, loginProvider: .reddit, clientId: "mock-reddit-id", verifierName: "reddit-shubs", redirectURL: "native://mock1")
		let mockedTorus = MockTorusSwiftDirectSDK(aggregateVerifierType: .singleLogin, aggregateVerifierName: "mock-reddit-name", subVerifierDetails: [appleVerifier], network: .ROPSTEN, loglevel: .none)
		
		torusService.createWallet(from: .reddit, displayOver: nil, mockedTorus: mockedTorus) { result in
			
			switch result {
				case .success(let wallet):
					XCTAssert(wallet.address == MockConstants.linearWalletSecp256k1.address, wallet.address)
					XCTAssert(wallet.authProvider == .reddit, wallet.authProvider.rawValue)
					XCTAssert(wallet.socialUsername == "testyMcTestface", wallet.socialUsername ?? "-")
					XCTAssert(wallet.socialUserId == nil)
					XCTAssert(wallet.socialProfilePictureURL?.absoluteString == "https://www.redditstatic.com/avatars/avatar_default_06_0DD3BB.png", wallet.socialProfilePictureURL?.absoluteString ?? "-")
					XCTAssert(wallet.mnemonic == nil)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
	
		wait(for: [expectation], timeout: 3)
	}
	
	func testGetPublicAddress() {
		let expectation = XCTestExpectation(description: "torus reddit")
		
		torusService.getAddress(from: .twitter, for: "testy") { result in
			switch result {
				case .success(let address):
					XCTAssert(address == MockConstants.linearWalletSecp256k1.address, address)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
	
		wait(for: [expectation], timeout: 3)
	}
}
*/
