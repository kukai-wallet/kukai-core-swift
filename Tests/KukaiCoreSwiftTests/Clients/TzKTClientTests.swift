//
//  TzKTClientTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class TzKTClientTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
	
	func testGetOperation() {
		let expectation = XCTestExpectation(description: "tzkt-testGetOperation")
		MockConstants.shared.tzktClient.getOperation(byHash: "ooT5uBirxWi9GXRqf6eGCEjoPhQid3U8yvsbP9JQHBXifVsinY8") { operations, error in
			XCTAssert(operations?.count == 4, "\(operations?.count ?? 0)")
			XCTAssert(operations?.first?.containsError() == false)
			XCTAssert(operations?.first?.type == "transaction", operations?.first?.type ?? "-")
			XCTAssert(operations?.first?.block == "BLucVFycsqX33udYmbQ8qKt41nLCvP1viGxjteCnZ8MqGFv7BEV", operations?.first?.block ?? "-")
			
			XCTAssertNil(error)
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
	
	func testGetOperationError() {
		let expectation = XCTestExpectation(description: "tzkt-testGetOperationError")
		MockConstants.shared.tzktClient.getOperation(byHash: "oo5XsmdPjxvBAbCyL9kh3x5irUmkWNwUFfi2rfiKqJGKA6Sxjzf") { operations, error in
			XCTAssert(operations?.count == 1, "\(operations?.count ?? 0)")
			XCTAssert(operations?.first?.containsError() == true)
			XCTAssert(operations?.first?.errors?.count == 2, "\(operations?.first?.errors?.count ?? 0)")
			XCTAssert(operations?.first?.errors?.first?.type == "michelson_v1.runtime_error", operations?.first?.errors?.first?.type ?? "-")
			XCTAssert(operations?.first?.type == "transaction", operations?.first?.type ?? "-")
			XCTAssert(operations?.first?.block == "BL4AgfjH9Mk6ZknQc7Ygf66CX2nbUH3E2w2mN3tZ9nnVq7zHpwu", operations?.first?.block ?? "-")
			
			XCTAssertNil(error)
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 3)
	}
	
	/*
	func testTransactionHistory() {
		let expectation = XCTestExpectation(description: "tzkt-testTransactionHistory")
		MockConstants.shared.tzktClient.refreshTransactionHistory(forAddress: MockConstants.defaultHdWallet.address, andSupportedTokens: [MockConstants.token3Decimals, MockConstants.token10Decimals]) {
			
			
			let transactions = MockConstants.shared.tzktClient.currentTransactionHistory(filterByToken: nil, orFilterByAddress: nil)
			XCTAssert(transactions.count == 7, "\(transactions.count)")
			
			for key in transactions.keys {
				let transactionArray = transactions[key]
				
				if key == 1603234800.0 {
					XCTAssert(transactionArray?.count == 2, "\(transactionArray?.count ?? 0)")
					XCTAssert(transactionArray?.first?.type == .transaction, transactionArray?.first?.type.rawValue ?? "-")
					XCTAssert(transactionArray?.first?.subType == .receive, transactionArray?.first?.subType.rawValue ?? "-")
					XCTAssert(transactionArray?.first?.hash == "ooNikcHDL1DUsfuh7N8DkJwbcHPBhgyij2FxQvA99NtuRWTzcnk", transactionArray?.first?.hash ?? "-")
					XCTAssert(transactionArray?.first?.sender.address == "tz1X2yA7evDKputSBthrwuGpxpAYHkDUkVCN", transactionArray?.first?.sender.address ?? "-")
					XCTAssert(transactionArray?.first?.networkFee == XTZAmount(fromNormalisedAmount: "0.259415", decimalPlaces: 6), transactionArray?.first?.networkFee.normalisedRepresentation ?? "-")
					
				} else if key == 1595458800.0 {
					XCTAssert(transactionArray?.count == 1, "\(transactionArray?.count ?? 0)")
					XCTAssert(transactionArray?.first?.type == .delegation, transactionArray?.first?.type.rawValue ?? "-")
					XCTAssert(transactionArray?.first?.subType == .delegation, transactionArray?.first?.subType.rawValue ?? "-")
					XCTAssert(transactionArray?.first?.hash == "ooPWdDR8L1zz6uAmdCPFLf5rVwba7HrStZX1PxKc8vKuS9y1tBh", transactionArray?.first?.hash ?? "-")
					XCTAssert(transactionArray?.first?.sender.address == "tz1X2yA7evDKputSBthrwuGpxpAYHkDUkVCN", transactionArray?.first?.sender.address ?? "-")
					XCTAssert(transactionArray?.first?.networkFee == XTZAmount(fromNormalisedAmount: 0.00138), transactionArray?.first?.networkFee.normalisedRepresentation ?? "-")
					
				} else if key == 1602802800.0  {
					XCTAssert(transactionArray?.count == 1, "\(transactionArray?.count ?? 0)")
					XCTAssert(transactionArray?.first?.type == .transaction, transactionArray?.first?.type.rawValue ?? "-")
					XCTAssert(transactionArray?.first?.subType == .receive, transactionArray?.first?.subType.rawValue ?? "-")
					XCTAssert(transactionArray?.first?.hash == "opND5nyS1GWgxvp3xhFwi9heLjUvgvbTCSLsgRcSU3xghk1hCYd", transactionArray?.first?.hash ?? "-")
					XCTAssert(transactionArray?.first?.sender.address == "tz1RKLWbGm7T4mnxDZHWazkbnvaryKsxxZTF", transactionArray?.first?.sender.address ?? "-")
					XCTAssert(transactionArray?.first?.networkFee == XTZAmount(fromNormalisedAmount: 0.258413), transactionArray?.first?.networkFee.normalisedRepresentation ?? "-")
					
				} else if key == 1603756800.0  {
					XCTAssert(transactionArray?.count == 2, "\(transactionArray?.count ?? 0)")
					XCTAssert(transactionArray?.first?.type == .transaction, transactionArray?.first?.type.rawValue ?? "-")
					XCTAssert(transactionArray?.first?.subType == .exchangeTokenToXTZ, transactionArray?.first?.subType.rawValue ?? "-")
					XCTAssert(transactionArray?.first?.hash == "ooRXrm9wNiguRhJSAfy58ta2ZE89W3aW5ZPprAhSWojwNQFdwb9", transactionArray?.first?.hash ?? "-")
					XCTAssert(transactionArray?.first?.sender.address == "tz1X2yA7evDKputSBthrwuGpxpAYHkDUkVCN", transactionArray?.first?.sender.address ?? "-")
					XCTAssert(transactionArray?.first?.networkFee == XTZAmount(fromNormalisedAmount: 0.0876), transactionArray?.first?.networkFee.normalisedRepresentation ?? "-")
					
				} else if key == 1603843200.0  {
					XCTAssert(transactionArray?.count == 1, "\(transactionArray?.count ?? 0)")
					XCTAssert(transactionArray?.first?.type == .transaction, transactionArray?.first?.type.rawValue ?? "-")
					XCTAssert(transactionArray?.first?.subType == .exchangeXTZToToken, transactionArray?.first?.subType.rawValue ?? "-")
					XCTAssert(transactionArray?.first?.hash == "ooVkQGcqMdtYbbrNAmE1Ht1v46LD4NQVnDCLCviL5QQ9HukUJUJ", transactionArray?.first?.hash ?? "-")
					XCTAssert(transactionArray?.first?.sender.address == "tz1X2yA7evDKputSBthrwuGpxpAYHkDUkVCN", transactionArray?.first?.sender.address ?? "-")
					XCTAssert(transactionArray?.first?.networkFee == XTZAmount(fromNormalisedAmount: 0.045359), transactionArray?.first?.networkFee.normalisedRepresentation ?? "-")
				}
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 5)
	}
	*/
	
	func testGetAllBalances() {
		let expectation = XCTestExpectation(description: "tzkt-testGetAllBalances")
		MockConstants.shared.tzktClient.getAllBalances(forAddress: MockConstants.defaultHdWallet.address) { result in
			
			switch result {
				case .success(let account):
					XCTAssert(account.xtzBalance.normalisedRepresentation == "1.843617", account.xtzBalance.normalisedRepresentation)
					XCTAssert(account.tokens.count == 13, "\(account.tokens.count)")
					XCTAssert(account.tokens[0].symbol == "tzBTC", account.tokens[0].symbol)
					XCTAssert(account.tokens[0].name == "tzBTC", account.tokens[0].name ?? "")
					XCTAssert(account.tokens[0].balance.normalisedRepresentation == "0.00038055", account.tokens[0].balance.normalisedRepresentation)
					XCTAssert(account.tokens[1].symbol == "Liquidity Baking LT", account.tokens[1].symbol)
					XCTAssert(account.tokens[1].name == "LB Token", account.tokens[1].name ?? "")
					XCTAssert(account.tokens[1].balance.normalisedRepresentation == "91", account.tokens[1].balance.normalisedRepresentation)
					XCTAssert(account.tokens[2].symbol == "WHEAT", account.tokens[2].symbol)
					XCTAssert(account.tokens[2].name == "Wheat", account.tokens[2].name ?? "")
					XCTAssert(account.tokens[2].balance.normalisedRepresentation == "880562.72985", account.tokens[2].balance.normalisedRepresentation)
					
					XCTAssert(account.nfts.count == 6, "\(account.nfts.count)")
					XCTAssert(account.nfts[0].nfts?.count == 3, "\(account.nfts[0].nfts?.count ?? -1)")
					XCTAssert(account.nfts[0].nfts?[0].name == "Donald J. Trump (C)", account.nfts[0].nfts?[0].name ?? "")
					XCTAssert(account.nfts[0].nfts?[0].artifactURL?.absoluteString == "https://static.tcinfra.net/media/small/ipfs/QmS1DhwQ8jfadjAK1kWHH22FPmgL33FNNHfM74cpXyTp7R/full/1045.png", account.nfts[0].nfts?[0].artifactURL?.absoluteString ?? "")
					XCTAssert(account.nfts[1].nfts?[0].name == "The Nine #0 (Steve Ellis Cover) - Free NFT", account.nfts[1].nfts?[0].name ?? "")
					XCTAssert(account.nfts[1].nfts?[0].artifactURL?.absoluteString == "https://static.tcinfra.net/media/small/ipfs/bafybeihhlrzfelp3rhz4dcz5ydvui5ntfh3j4luyrc2pbwgkjyhqca4ap4", account.nfts[1].nfts?[0].artifactURL?.absoluteString ?? "")
					XCTAssert(account.nfts[2].nfts?[0].name == "Tez Swords: #5. Excalibur", account.nfts[2].nfts?[0].name ?? "")
					XCTAssert(account.nfts[2].nfts?[0].artifactURL?.absoluteString == "https://static.tcinfra.net/media/small/ipfs/QmdoYC76e1R9J3fYWCEsktYimAdYSNMSv6avtxmVt9LQrE", account.nfts[2].nfts?[0].artifactURL?.absoluteString ?? "")
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 5)
	}
	
	func testAvatarURL() {
		let url = MockConstants.shared.tzktClient.avatarURL(forToken: "KT1abc123")
		
		XCTAssert(url?.absoluteString == "https://services.tzkt.io/v1/avatars/KT1abc123", url?.absoluteString ?? "-")
	}
}
