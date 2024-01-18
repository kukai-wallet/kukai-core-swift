//
//  TorusAuthServiceTests.swift
//  
//
//  Created by Simon Mcloughlin on 12/07/2021.
//

import XCTest
import CustomAuth
@testable import KukaiCoreSwift

class TorusAuthServiceTests: XCTestCase {
	
	static let googleSubVerifier = SubVerifierDetails(loginType: .web, loginProvider: .google, clientId: "mock-google-id", verifier: "mock-google-name", redirectURL: "native://mock1")
	let torusService = TorusAuthService(networkService: MockConstants.shared.networkService, verifiers: [
		.twitter: SubverifierWrapper(aggregateVerifierName: "mock-twitter-verifier", verifierType: .singleLogin, networkType: .testnet, subverifier: SubVerifierDetails(loginType: .web, loginProvider: .twitter, clientId: "mock-twitter-id", verifier: "mock-twitter-name", redirectURL: "native://mock1", jwtParams: ["domain": "torus-test.auth0.com"])),
		.google: SubverifierWrapper(aggregateVerifierName: "mock-google-verifier", verifierType: .singleIdVerifier, networkType: .testnet, subverifier: TorusAuthServiceTests.googleSubVerifier)
	])
	
	override func setUpWithError() throws {
	}
	
	override func tearDownWithError() throws {
	}
	
	func testCreateGoogleWallet() {
		let mockTorus = MockCustomAuth(aggregateVerifierType: .singleIdVerifier,
									   aggregateVerifier: "mock-google-verifier",
									   subVerifierDetails: [TorusAuthServiceTests.googleSubVerifier],
									   network: .TESTNET,
									   loglevel: .info,
									   urlSession: MockConstants.shared.networkService.urlSession)
		
		
		let expectation = XCTestExpectation(description: "torus create wallet")
		torusService.createWallet(from: .google, displayOver: nil, mockedTorus: mockTorus) { result in
			switch result {
				case .success(let wallet):
					XCTAssert(wallet.address == MockConstants.linearWalletSecp256k1.address, wallet.address)
					XCTAssert(wallet.authProvider == .google, wallet.authProvider.rawValue)
					XCTAssert(wallet.socialUsername == "testyMcTestface", wallet.socialUsername ?? "-")
					XCTAssert(wallet.socialUserId == "testy@domain.com", wallet.socialUserId ?? "-")
					XCTAssert(wallet.socialProfilePictureURL?.absoluteString == "https://www.redditstatic.com/avatars/avatar_default_06_0DD3BB.png", wallet.socialProfilePictureURL?.absoluteString ?? "-")
					XCTAssert(wallet.mnemonic == nil)
					
				case .failure(let error):
					XCTFail(error.description)
			}
					
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	/*
	// Need to mock a non-open function in TorusUtils
	func testGetPublicAddress() {
		let expectation = XCTestExpectation(description: "torus get address")
		
		torusService.getAddress(from: .twitter, for: "testy") { result in
			switch result {
				case .success(let address):
					XCTAssert(address == MockConstants.linearWalletSecp256k1.address, address)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	*/
}
