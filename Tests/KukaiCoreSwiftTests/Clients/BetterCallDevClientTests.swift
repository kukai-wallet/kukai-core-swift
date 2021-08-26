//
//  BetterCallDevClientTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 17/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class BetterCallDevClientTests: XCTestCase {
	
	func testMoreDetailedError() {
		let expectation = XCTestExpectation(description: "bcd-testMoreDetailedError")
		MockConstants.shared.betterCallDevClient.getMoreDetailedError(byHash: MockConstants.operationHashToSearch) { bcdError, errorResponse in
			
			XCTAssert(bcdError?.kind == "temporary", bcdError?.kind ?? "-")
			XCTAssert(bcdError?.title == "Script failed", bcdError?.title ?? "-")
			XCTAssert(bcdError?.descr == "A FAILWITH instruction was reached", bcdError?.descr ?? "-")
			XCTAssert(bcdError?.with == "xtzBought is less than minXtzBought.", bcdError?.with ?? "-")
			
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 3)
	}
	
	func testAccount() {
		let expectation = XCTestExpectation(description: "bcd-testAccount")
		MockConstants.shared.betterCallDevClient.account(forAddress: MockConstants.defaultHdWallet.address) { result in
			switch result {
				case .success(let account):
					XCTAssert(account.address == "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG", account.address)
					XCTAssert(account.balance == XTZAmount(fromNormalisedAmount: 243.078784), account.balance.normalisedRepresentation)
					XCTAssert(account.network == .florencenet, account.network.rawValue)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 3)
	}
	
	func testTokenCount() {
		let expectation = XCTestExpectation(description: "bcd-testTokenCount")
		MockConstants.shared.betterCallDevClient.accountTokenCount(forAddress: MockConstants.defaultHdWallet.address, completion: { result in
			switch result {
				case .success(let dict):
					XCTAssert(dict.keys.count == 8, "\(dict.keys.count)")
					XCTAssert(dict.values.count == 8, "\(dict.values.count)")
					XCTAssert(dict["KT1P3RGEAa78XLTs3Hkpd1VWtryQRLDjiXqF"] == 1, "\(dict["KT1P3RGEAa78XLTs3Hkpd1VWtryQRLDjiXqF"] ?? 0)")
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		})
		wait(for: [expectation], timeout: 3)
	}
	
	func testTokenBalances() {
		let expectation = XCTestExpectation(description: "bcd-testTokenBalances")
		MockConstants.shared.betterCallDevClient.tokenBalances(forAddress: MockConstants.defaultHdWallet.address) { result in
			switch result {
				case .success(let balances):
					XCTAssert(balances.balances.count == 9, "\(balances.balances.count)")
					XCTAssert(balances.balances.first?.symbol == "T1", balances.balances.first?.symbol ?? "-")
					XCTAssert(balances.balances.first?.name == "Token 1", balances.balances.first?.name ?? "-")
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 3)
	}
	
	func testTokenMetadata() {
		let expectation = XCTestExpectation(description: "bcd-testTokenMetadata")
		MockConstants.shared.betterCallDevClient.tokenMetadata(forTokenAddress: MockConstants.token3Decimals.tokenContractAddress ?? "-") { result in
			switch result {
				case .success(let metadata):
					XCTAssert(metadata?.contract == "KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8", metadata?.contract ?? "-")
					XCTAssert(metadata?.name == "ETHtez", metadata?.name ?? "-")
					XCTAssert(metadata?.symbol == "ETHtz", metadata?.symbol ?? "-")
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		}
		wait(for: [expectation], timeout: 3)
	}
	
	func testContractMetadata() {
		let expectation = XCTestExpectation(description: "bcd-testContractMetadata")
		MockConstants.shared.betterCallDevClient.contractMetdata(forContractAddress: MockConstants.token3Decimals.tokenContractAddress ?? "-", completion: { result in
			switch result {
				case .success(let contract):
					XCTAssert(contract.address == "KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8", contract.address)
					XCTAssert(contract.manager == "tz1UhnGg2ND5toEkWjybfvXKTsFEsQ9rj2B8", contract.manager ?? "")
					XCTAssert(contract.faVersionFromTags() == .fa1_2, contract.faVersionFromTags().rawValue)
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			expectation.fulfill()
		})
		wait(for: [expectation], timeout: 3)
	}
	
	func testAccountInfo() {
		let delete1 = DiskService.delete(fileName: BetterCallDevClient.Constants.accountHashFilename)
		let delete2 = DiskService.delete(fileName: BetterCallDevClient.Constants.parsedAccountFilename)
		let delete3 = DiskService.delete(fileName: BetterCallDevClient.Constants.tokenMetadataFilename)
		XCTAssert(delete1 && delete2 && delete3)
		
		
		let expectation = XCTestExpectation(description: "bcd-testAccountInfo")
		MockConstants.shared.betterCallDevClient.fetchAccountInfo(forAddress: MockConstants.defaultHdWallet.address, completion: { result in
			switch result {
				case .success(let account):
					XCTAssert(account.walletAddress == "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG", account.walletAddress)
					XCTAssert(account.tokens.count == 7, "\(account.tokens.count)")
					XCTAssert(account.tokens.first?.name == "Token 4", account.tokens.first?.name ?? "-")
					XCTAssert(account.tokens.first?.symbol == "T4", account.tokens.first?.symbol ?? "-")
					XCTAssert(account.nfts.count == 1, "\(account.nfts.count)")
					XCTAssert(account.nfts.first?.nfts?.count == 2, "\(account.nfts.first?.nfts?.count ?? 0)")
					XCTAssert(account.nfts.first?.nfts?.first?.name == "matrix 6", account.nfts.first?.nfts?.first?.name ?? "-")
					XCTAssert(account.nfts.first?.nfts?.first?.symbol == "MATRI", account.nfts.first?.nfts?.first?.symbol ?? "-")
					
				case .failure(let error):
					XCTFail(error.description)
			}
			
			
			let cachedAccount = MockConstants.shared.betterCallDevClient.cachedAccountInfo()
			XCTAssert(cachedAccount?.walletAddress == "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG", cachedAccount?.walletAddress ?? "-")
			XCTAssert(cachedAccount?.tokens.count == 7, "\(cachedAccount?.tokens.count ?? 0)")
			XCTAssert(cachedAccount?.tokens.first?.name == "Token 4", cachedAccount?.tokens.first?.name ?? "-")
			XCTAssert(cachedAccount?.tokens.first?.symbol == "T4", cachedAccount?.tokens.first?.symbol ?? "-")
			XCTAssert(cachedAccount?.nfts.count == 1, "\(cachedAccount?.nfts.count ?? 0)")
			XCTAssert(cachedAccount?.nfts.first?.nfts?.count == 2, "\(cachedAccount?.nfts.first?.nfts?.count ?? 0)")
			XCTAssert(cachedAccount?.nfts.first?.nfts?.first?.name == "matrix 6", cachedAccount?.nfts.first?.nfts?.first?.name ?? "-")
			XCTAssert(cachedAccount?.nfts.first?.nfts?.first?.symbol == "MATRI", cachedAccount?.nfts.first?.nfts?.first?.symbol ?? "-")
			
			expectation.fulfill()
		})
		wait(for: [expectation], timeout: 10)
	}
	
	func testImageURL() {
		let testURL = MockConstants.shared.betterCallDevClient.avatarURL(forToken: MockConstants.token3Decimals.tokenContractAddress ?? "")
		XCTAssert(testURL?.absoluteString == "https://services.tzkt.io/v1/avatars/KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8", testURL?.absoluteString ?? "-")
	}
}
