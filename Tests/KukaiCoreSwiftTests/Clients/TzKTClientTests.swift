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
		
		wait(for: [expectation], timeout: 120)
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
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testTransactionHistory() {
		let expectation = XCTestExpectation(description: "tzkt-testTransactionHistory")
		
		MockConstants.shared.tzktClient.fetchTransactions(forAddress: MockConstants.defaultHdWallet.address) { transactions in
			let groups = MockConstants.shared.tzktClient.groupTransactions(transactions: transactions, currentWalletAddress: MockConstants.defaultHdWallet.address)
			
			XCTAssert(groups.count == 22, "\(groups.count)")
			
			for (index, group) in groups.enumerated() {
				
				switch index {
					case 0:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "1030074601046021", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1PegvRtG4LTWGjNx8bswVEvqKNC1FBZBjL", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "40", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "TestFirstMCDao", group.primaryToken?.name ?? "-")
						
					case 1:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "op3K5QH2Tho6sUJy54hyRDXaRa7p11AvoVfZDmT4gLojFFDGG6Y", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1CzVSa18hndYupV9NcXy3Qj7p8YFDZKVQv", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "1", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "Wood Mooncake", group.primaryToken?.name ?? "-")
						
					case 2:
						XCTAssert(group.groupType == .contractCall, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "op3K5QH2Tho6sUJy54hyRDXaRa7p11AvoVfZDmT4gLojFFDGG6Y", group.hash)
						XCTAssert(group.entrypointCalled == "claim", group.entrypointCalled ?? "-")
						
					case 3:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "opRQnyqN4fogpRSBCuxFpCm9SGooy1QY3r5Xc4FXre33tNFWh97", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1CzVSa18hndYupV9NcXy3Qj7p8YFDZKVQv", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "1", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "Wood Mooncake", group.primaryToken?.name ?? "-")
						
					case 4:
						XCTAssert(group.groupType == .contractCall, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "opRQnyqN4fogpRSBCuxFpCm9SGooy1QY3r5Xc4FXre33tNFWh97", group.hash)
						XCTAssert(group.entrypointCalled == "claim", group.entrypointCalled ?? "-")
						
					case 5:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "oopQFnCyS9fPYeBftynXH6coUUAy4UPBuA3Hcp8nsApYNKxVuRx", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == nil, group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "0.5", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "Tezos", group.primaryToken?.name ?? "-")
						
					case 6:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "onjmwjKLUPVpguDVYSZp2yh1tqGPp5oEgAjSbiFvxv74XsmMarg", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1914CUZ7EegAFPbfgQMRkw8Uz5mYkEz2ui", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "228.9299288", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "Crunchy.Network CRNCHY", group.primaryToken?.name ?? "-")
						
					case 7:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "onjmwjKLUPVpguDVYSZp2yh1tqGPp5oEgAjSbiFvxv74XsmMarg", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == nil, group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "0.102422", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "Tezos", group.primaryToken?.name ?? "-")
						
					case 8:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "onjmwjKLUPVpguDVYSZp2yh1tqGPp5oEgAjSbiFvxv74XsmMarg", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1KPoyzkj82Sbnafm6pfesZKEhyCpXwQfMc", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "3.160106", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "fDAO", group.primaryToken?.name ?? "-")
						
					case 9:
						XCTAssert(group.groupType == .contractCall, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 7, group.transactions.count.description)
						XCTAssert(group.hash == "onjmwjKLUPVpguDVYSZp2yh1tqGPp5oEgAjSbiFvxv74XsmMarg", group.hash)
						XCTAssert(group.entrypointCalled == "tezToTokenPayment", group.entrypointCalled ?? "-")
						
						XCTAssert(group.transactions[0].subType == .send, group.transactions[0].subType?.rawValue ?? "-")
						XCTAssert(group.transactions[0].primaryToken?.tokenContractAddress == nil, group.transactions[0].primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.transactions[0].primaryToken?.balance.normalisedRepresentation == "0.000099", group.transactions[0].primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.transactions[0].primaryToken?.name == "Tezos", group.transactions[0].primaryToken?.name ?? "-")
						
						XCTAssert(group.transactions[1].subType == .contractCall, group.transactions[1].subType?.rawValue ?? "-")
						XCTAssert(group.transactions[1].entrypointCalled == "tezToTokenPayment", group.transactions[1].entrypointCalled ?? "-")
						
						XCTAssert(group.transactions[2].subType == .contractCall, group.transactions[2].subType?.rawValue ?? "-")
						XCTAssert(group.transactions[2].entrypointCalled == "update_operators", group.transactions[2].entrypointCalled ?? "-")
						
						XCTAssert(group.transactions[3].subType == .send, group.transactions[3].subType?.rawValue ?? "-")
						XCTAssert(group.transactions[3].primaryToken?.tokenContractAddress == "KT1KPoyzkj82Sbnafm6pfesZKEhyCpXwQfMc", group.transactions[3].primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.transactions[3].primaryToken?.balance.normalisedRepresentation == "3.15483", group.transactions[3].primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.transactions[3].primaryToken?.name == "fDAO", group.transactions[3].primaryToken?.name ?? "-")
						
						XCTAssert(group.transactions[4].subType == .contractCall, group.transactions[4].subType?.rawValue ?? "-")
						XCTAssert(group.transactions[4].entrypointCalled == "swap", group.transactions[4].entrypointCalled ?? "-")
						
						XCTAssert(group.transactions[5].subType == .contractCall, group.transactions[5].subType?.rawValue ?? "-")
						XCTAssert(group.transactions[5].entrypointCalled == "update_operators", group.transactions[5].entrypointCalled ?? "-")
						
						XCTAssert(group.transactions[6].subType == .contractCall, group.transactions[6].subType?.rawValue ?? "-")
						XCTAssert(group.transactions[6].entrypointCalled == "tezToTokenPayment", group.transactions[6].entrypointCalled ?? "-")
						
					case 10:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "onqrPbMuVZy6dDELwhXfdF8BbANXy5mLj47gjAf7CE5cAUvSVoQ", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1U6EHmNxJTkvaWJ4ThczG4FSDaHC21ssvi", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "1", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "Unknown Token", group.primaryToken?.name ?? "-")
						
					case 11:
						XCTAssert(group.groupType == .contractCall, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "onqrPbMuVZy6dDELwhXfdF8BbANXy5mLj47gjAf7CE5cAUvSVoQ", group.hash)
						XCTAssert(group.entrypointCalled == "mint", group.entrypointCalled ?? "-")
						
					case 12:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "589699422879746", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1BRADdqGk2eLmMqvyWzqVmPQ1RCBCbW5dY", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "1", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "7/23 McLaren F1 Collectible", group.primaryToken?.name ?? "-")
						
					case 13:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "579854610202626", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1BRADdqGk2eLmMqvyWzqVmPQ1RCBCbW5dY", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "1", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "6/23 McLaren F1 Collectible", group.primaryToken?.name ?? "-")
						
					case 14:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "566013445799938", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1JBNFcB5tiycHNdYGYCtR3kk6JaJysUCi8", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "0", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "Lugh Euro pegged stablecoin", group.primaryToken?.name ?? "-")
						
					case 15:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "ooyKEQLPDHHD2K8ZJSt92braYAPcRjxxfEmXVcdAQ5X4AoRuREA", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1JFjwQ25n58NZr5Bwy9chAxHCaPsjvh5xt", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "0.975223", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "WTZ", group.primaryToken?.name ?? "-")
						
					case 16:
						XCTAssert(group.groupType == .contractCall, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "ooyKEQLPDHHD2K8ZJSt92braYAPcRjxxfEmXVcdAQ5X4AoRuREA", group.hash)
						XCTAssert(group.entrypointCalled == "wrap", group.entrypointCalled ?? "-")
						
					case 17:
						XCTAssert(group.groupType == .delegate, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "onpirLfDfojh84pihNKmrNFZ14Uf8z2SHYBVikcaKfSRBFFFb25", group.hash)
						XCTAssert(group.transactions.first?.prevDelegate?.alias == " Baking Benjamins", group.transactions.first?.prevDelegate?.alias ?? "-")
						XCTAssert(group.transactions.first?.newDelegate?.alias == "ECAD Labs Baker", group.transactions.first?.newDelegate?.alias ?? "-")
						
					case 18:
						XCTAssert(group.groupType == .contractCall, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "opC815T6zqTUtzQktPBBeLAB1eRnvuR5ETZDoLPGgAb3698wwFK", group.hash)
						XCTAssert(group.status == .failed, group.status.rawValue)
						
					case 19:
						XCTAssert(group.groupType == .unstake, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.transactions.first?.amount?.description == "1", group.transactions.first?.amount?.description ?? "-")
						XCTAssert(group.transactions.first?.primaryToken?.balance.description == "1", group.transactions.first?.primaryToken?.balance.description ?? "-")
						XCTAssert(group.transactions.first?.baker?.address == "tz1YgDUQV2eXm8pUWNz3S5aWP86iFzNp4jnD", group.transactions.first?.baker?.address ?? "-")
						XCTAssert(group.transactions.first?.baker?.alias == "Baking Benjamins", group.transactions.first?.baker?.alias ?? "-")
						XCTAssert(group.hash == "ooyVR1r5vt3K4JGoVnH2XLQjwAVpoZaAkfdG1PssCPPovi7m1FL", group.hash)
						XCTAssert(group.status == .applied, group.status.rawValue)
						
					case 20:
						XCTAssert(group.groupType == .stake, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.transactions.first?.amount?.description == "10", group.transactions.first?.amount?.description ?? "-")
						XCTAssert(group.transactions.first?.primaryToken?.balance.description == "10", group.transactions.first?.primaryToken?.balance.description ?? "-")
						XCTAssert(group.transactions.first?.baker?.address == "tz1YgDUQV2eXm8pUWNz3S5aWP86iFzNp4jnD", group.transactions.first?.baker?.address ?? "-")
						XCTAssert(group.transactions.first?.baker?.alias == "Baking Benjamins", group.transactions.first?.baker?.alias ?? "-")
						XCTAssert(group.hash == "opPGcuZ459ZGR11RXaL2rRDtKnHFC9o5JQdyBHj3Qua4BMBkAsi", group.hash)
						XCTAssert(group.status == .applied, group.status.rawValue)
						
					case 21:
						XCTAssert(group.groupType == .finaliseUnstake, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.transactions.first?.amount?.description == "400333", group.transactions.first?.amount?.description ?? "-")
						XCTAssert(group.transactions.first?.primaryToken?.balance.description == "400333", group.transactions.first?.primaryToken?.balance.description ?? "-")
						XCTAssert(group.transactions.first?.baker?.address == "tz1YgDUQV2eXm8pUWNz3S5aWP86iFzNp4jnD", group.transactions.first?.baker?.address ?? "-")
						XCTAssert(group.transactions.first?.baker?.alias == "Baking Benjamins", group.transactions.first?.baker?.alias ?? "-")
						XCTAssert(group.hash == "onnkAJpSQ8SnLB94saCmtQdPge7gCyEwG6UuEW6KhGkbaQobFBu", group.hash)
						XCTAssert(group.status == .applied, group.status.rawValue)
						
					default:
						XCTFail("Missing test for transaction")
				}
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testTransactionHistory_transferBatchSmallAccount() {
		let expectation = XCTestExpectation(description: "tzkt-testTransactionHistory")
		
		MockConstants.shared.tzktClient.fetchTransactions(forAddress: MockConstants.hdWallet_withPassphrase.address) { transactions in
			let groups = MockConstants.shared.tzktClient.groupTransactions(transactions: transactions, currentWalletAddress: MockConstants.hdWallet_withPassphrase.address)
			
			XCTAssert(groups.count == 27, "\(groups.count)")
			
			for (index, group) in groups.enumerated() {
				
				switch index {
					case 0:
						XCTAssert(group.groupType == .send, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "opaWxncYFsRtfJR2mxaDy2j3R9YSP1d6CArJuU5BCVh6Sd1e3op", group.hash)
						
					case 1:
						XCTAssert(group.groupType == .send, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 21, group.transactions.count.description)
						XCTAssert(group.hash == "oop26DbWP1zCDz4Zn1vwZ84SKg6diAT4nXBPHqcPEXXA8McoPko", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1CQPWGQb8E2eessT4whXECWbhwEcGHkqpF", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "1", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "Catami #553", group.primaryToken?.name ?? "-")
						
					case 2:
						XCTAssert(group.groupType == .send, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "ooPUBCDGAX9Gkb7icrRAdPdUdTXBWqRD9jWuAUh6zpoZrVi6YTT", group.hash)
						
					case 3:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "ooWUADYANNWw6yobc3cqGmLQ2Q9HywJUH3PNFPBhdwtUszZVqFf", group.hash)
						
					case 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "opFawEFU3pRhRmtBf7xVtYNQKFV5fTVpqdFu7z1kcFiGj5r8S4H", group.hash)
						
					case 25:
						XCTAssert(group.groupType == .contractCall, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "opFawEFU3pRhRmtBf7xVtYNQKFV5fTVpqdFu7z1kcFiGj5r8S4H", group.hash)
						XCTAssert(group.entrypointCalled == "mint", group.entrypointCalled ?? "-")
						
					case 26:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "oobTbeXGDxHWcbnNTBKj7DTb8B11aDksxeKPKTF3A9kxVTVPsQ4", group.hash)
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "66.358637", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						
						
					default:
						XCTFail("Missing test for transaction")
				}
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testGetAllBalances() {
		let expectation = XCTestExpectation(description: "tzkt-testGetAllBalances")
		MockConstants.shared.tzktClient.getAllBalances(forAddress: MockConstants.defaultHdWallet.address) { result in
			
			switch result {
				case .success(let account):
					
					// Tokens
					XCTAssert(account.xtzBalance.normalisedRepresentation == "1.843617", account.xtzBalance.normalisedRepresentation)
					XCTAssert(account.xtzStakedBalance.normalisedRepresentation == "0", account.xtzStakedBalance.normalisedRepresentation)
					XCTAssert(account.xtzUnstakedBalance.normalisedRepresentation == "0", account.xtzUnstakedBalance.normalisedRepresentation)
					XCTAssert(account.availableBalance.normalisedRepresentation == "1.843617", account.availableBalance.normalisedRepresentation)
					XCTAssert(account.tokens.count == 21, "\(account.tokens.count)")
					XCTAssert(account.tokens[0].symbol == "wBUSD", account.tokens[0].symbol)
					XCTAssert(account.tokens[0].name == "Wrapped Tokens Contract", account.tokens[0].name ?? "")
					XCTAssert(account.tokens[0].balance.normalisedRepresentation == "0.000464038238858254", account.tokens[0].balance.normalisedRepresentation)
					XCTAssert(account.tokens[1].symbol == "kUSD", account.tokens[1].symbol)
					XCTAssert(account.tokens[1].name == "kUSD", account.tokens[1].name ?? "")
					XCTAssert(account.tokens[1].balance.normalisedRepresentation == "1.122564894578671941", account.tokens[1].balance.normalisedRepresentation)
					XCTAssert(account.tokens[2].symbol == "USDtz", account.tokens[2].symbol)
					XCTAssert(account.tokens[2].name == "USDtz", account.tokens[2].name ?? "")
					XCTAssert(account.tokens[2].balance.normalisedRepresentation == "0.004337", account.tokens[2].balance.normalisedRepresentation)
					XCTAssert(account.tokens[3].symbol == "crDAO", account.tokens[3].symbol)
					XCTAssert(account.tokens[3].name == "crDAO", account.tokens[3].name ?? "")
					XCTAssert(account.tokens[3].balance.normalisedRepresentation == "0.12810553", account.tokens[3].balance.normalisedRepresentation)
					
					
					
					// NFTs
					XCTAssert(account.nfts.count == 11, "\(account.nfts.count)")
					
					XCTAssert(account.nfts[0].nfts?.count == 1, "\(account.nfts[0].nfts?.count ?? -1)")
					XCTAssert(account.nfts[0].nfts?[0].name == "Taco Mooncake", account.nfts[0].nfts?[0].name ?? "")
					XCTAssert(account.nfts[0].thumbnailURL?.absoluteString == "https://services.tzkt.io/v1/logos/KT1XRH2L7VFAMvQrAK17aTfrx71NL69gaBAm.png", account.nfts[0].thumbnailURL?.absoluteString ?? "-")
					XCTAssert(account.nfts[0].nfts?[0].artifactURI?.absoluteString == "ipfs://QmeDXtDWpPBeG41izwVYoYbFseczshGMR9JEtm6dc8d83Q", account.nfts[0].nfts?[0].artifactURI?.absoluteString ?? "")
					let keyValueAttributes1 = account.nfts[0].nfts?[0].metadata?.getKeyValuesFromAttributes() ?? []
					XCTAssert(keyValueAttributes1.count == 5, "\(keyValueAttributes1.count)")
					XCTAssert(keyValueAttributes1[0].key == "Mood", keyValueAttributes1[0].key)
					XCTAssert(keyValueAttributes1[0].value == "Taco Tuesday", keyValueAttributes1[0].value)
					XCTAssert(keyValueAttributes1[1].key == "Artist", keyValueAttributes1[1].key)
					XCTAssert(keyValueAttributes1[1].value == "Taco", keyValueAttributes1[1].value)
					XCTAssert(keyValueAttributes1[2].key == "Thought", keyValueAttributes1[2].key)
					XCTAssert(keyValueAttributes1[2].value == "This is my kind of dessert", keyValueAttributes1[2].value)
					
					
					XCTAssert(account.nfts[1].nfts?[0].name == "Zachary Taylor (C)", account.nfts[1].nfts?[0].name ?? "")
					XCTAssert(account.nfts[1].nfts?[0].artifactURI?.absoluteString == "ipfs://Qmczgp9juksRrzDkXUQQQFb9xwNDimv1gTy6kLjZqVNPoX/full/1012.png", account.nfts[1].nfts?[0].artifactURI?.absoluteString ?? "")
					let keyValueAttributes2 = account.nfts[1].nfts?[0].metadata?.getKeyValuesFromAttributes() ?? []
					XCTAssert(keyValueAttributes2.count == 0, "\(keyValueAttributes2.count)")
					
					
					XCTAssert(account.nfts[2].nfts?[0].name == "Press Your Buttons - Fragment 3", account.nfts[2].nfts?[0].name ?? "")
					XCTAssert(account.nfts[2].nfts?[0].artifactURI?.absoluteString == "ipfs://QmQ1gVgmE3pfXYH5bL9n1NXA5n9g4XW1mihcrRe4pa2StG", account.nfts[2].nfts?[0].artifactURI?.absoluteString ?? "")
					let keyValueAttributes3 = account.nfts[2].nfts?[0].metadata?.getKeyValuesFromAttributes() ?? []
					XCTAssert(keyValueAttributes3.count == 4, "\(keyValueAttributes3.count)")
					XCTAssert(keyValueAttributes3[0].key == "Cost", keyValueAttributes3[0].key)
					XCTAssert(keyValueAttributes3[0].value == "3", keyValueAttributes3[0].value)
					XCTAssert(keyValueAttributes3[1].key == "Strength", keyValueAttributes3[1].key)
					XCTAssert(keyValueAttributes3[1].value == "5", keyValueAttributes3[1].value)
					XCTAssert(keyValueAttributes3[2].key == "Abilities", keyValueAttributes3[2].key)
					XCTAssert(keyValueAttributes3[2].value == "Reversible: Opponents arguments cost 1 more.", keyValueAttributes3[2].value)
					
					XCTAssert(account.nfts[3].tokenContractAddress == "KT1UmNSC5gjZeTcTeMEGpXqUZaJwUVRqvunM", account.nfts[3].tokenContractAddress ?? "-")
					XCTAssert(account.nfts[3].name == nil, account.nfts[3].name ?? "-")
					
					XCTAssert(account.nfts[4].name == "FXHASH GENTK v2", account.nfts[4].name ?? "")
					XCTAssert(account.nfts[4].nfts?.count == 2, account.nfts[4].nfts?.count.description ?? "")
					XCTAssert(account.nfts[4].nfts?[0].name == "[WAITING TO BE SIGNED]", account.nfts[4].nfts?[0].name ?? "")
					XCTAssert(account.nfts[4].nfts?[1].name == "Unknown Token", account.nfts[4].nfts?[1].name ?? "")
					
					XCTAssert(account.nfts[5].name == "Tezos Domains NameRegistry", account.nfts[5].name ?? "")
					XCTAssert(account.nfts[5].nfts?[0].name == "blah.tez", account.nfts[5].nfts?[0].name ?? "")
					
					XCTAssert(account.nfts[9].name == "DOGAMÍ x GAP", account.nfts[9].name ?? "")
					XCTAssert(account.nfts[9].nfts?[0].name == "Bed Pillow #2435", account.nfts[9].nfts?[0].name ?? "")
					
					XCTAssert(account.nfts[10].tokenContractAddress == "KT1BA9igcUcgkMT4LEEQzwURsdMpQayfb6i4", account.nfts[10].name ?? "")
					XCTAssert(account.nfts[10].nfts?[0].name == "Bear Pawtrait", account.nfts[10].nfts?[0].name ?? "")
					
					// Liquidity tokens
					XCTAssert(account.liquidityTokens.count == 0, "\(account.liquidityTokens.count)")
					//XCTAssert(account.liquidityTokens[0].sharesQty == "91", account.liquidityTokens[0].sharesQty)
					//XCTAssert(account.liquidityTokens[0].exchange.token.symbol == "tzBTC", account.liquidityTokens[0].exchange.token.symbol)
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testAvatarURL() {
		let url = TzKTClient.avatarURL(forToken: "KT1abc123")
		
		XCTAssert(url?.absoluteString == "https://services.tzkt.io/v1/logos/KT1abc123.png", url?.absoluteString ?? "-")
	}
	
	func testEstimateRewardsDelegateOnly() {
		let expectation = XCTestExpectation(description: "tzkt-testEstimateRewards")
		let delegate = TzKTAccountDelegate(alias: "Baking Benjamins", address: "tz1S5WxdZR5f9NzsPXhr7L9L1vrEb5spZFur", active: true)
		
		MockConstants.shared.tzktClient.estimateLastAndNextReward(forAddress: MockConstants.defaultHdWallet.address, delegate: delegate, forceMainnet: true) { result in
			switch result {
				case .success(let rewards):
					XCTAssert(rewards.previousReward?.delegateAmount.description == "0.926578", rewards.previousReward?.delegateAmount.description ?? "")
					XCTAssert(rewards.previousReward?.stakeAmount.description == "0", rewards.previousReward?.stakeAmount.description ?? "")
					XCTAssert(rewards.previousReward?.delegateFee.description == "0.2", rewards.previousReward?.delegateFee.description ?? "")
					XCTAssert(rewards.previousReward?.stakeFee.description == "0.1", rewards.previousReward?.stakeFee.description ?? "")
					XCTAssert(rewards.previousReward?.cycle.description == "797", rewards.previousReward?.cycle.description ?? "")
					XCTAssert(rewards.previousReward?.bakerAlias == "Baking Benjamins", rewards.previousReward?.bakerAlias ?? "")
					
					XCTAssert(rewards.estimatedPreviousReward?.delegateAmount.normalisedRepresentation == "0.926949", rewards.estimatedPreviousReward?.delegateAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.stakeAmount.normalisedRepresentation == "0", rewards.estimatedPreviousReward?.stakeAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.delegateFee.description == "0.2", rewards.estimatedPreviousReward?.delegateFee.description ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.stakeFee.description == "0.1", rewards.estimatedPreviousReward?.stakeFee.description ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.cycle.description == "797", rewards.estimatedPreviousReward?.cycle.description ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.bakerAlias == "Baking Benjamins", rewards.estimatedPreviousReward?.bakerAlias ?? "")
					
					XCTAssert(rewards.estimatedNextReward?.delegateAmount.normalisedRepresentation == "0.851008", rewards.estimatedNextReward?.delegateAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedNextReward?.stakeAmount.normalisedRepresentation == "0", rewards.estimatedNextReward?.stakeAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedNextReward?.delegateFee.description == "0.2", rewards.estimatedNextReward?.delegateFee.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.stakeFee.description == "0.1", rewards.estimatedNextReward?.stakeFee.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.cycle.description == "798", rewards.estimatedNextReward?.cycle.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.bakerAlias == "Baking Benjamins", rewards.estimatedNextReward?.bakerAlias ?? "")
					
					XCTAssert(rewards.moreThan1CycleBetweenPreiousAndNext() == false)
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testEstimateRewardsDelegateAndStake() {
		let expectation = XCTestExpectation(description: "tzkt-testEstimateRewards")
		let delegate = TzKTAccountDelegate(alias: "Baking Benjamins", address: "tz1S5WxdZR5f9NzsPXhr7L9L1vrEb5spZFur", active: true)
		
		MockConstants.shared.tzktClient.estimateLastAndNextReward(forAddress: MockConstants.defaultLinearWallet.address, delegate: delegate, forceMainnet: true) { result in
			switch result {
				case .success(let rewards):
					XCTAssert(rewards.previousReward == nil, rewards.previousReward?.delegateAmount.description ?? "")
					
					XCTAssert(rewards.estimatedPreviousReward?.delegateAmount.normalisedRepresentation == "7.644663", rewards.estimatedPreviousReward?.delegateAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.stakeAmount.normalisedRepresentation == "24.145581", rewards.estimatedPreviousReward?.stakeAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.delegateFee.description == "0.2", rewards.estimatedPreviousReward?.delegateFee.description ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.stakeFee.description == "0.1", rewards.estimatedPreviousReward?.stakeFee.description ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.cycle.description == "800", rewards.estimatedPreviousReward?.cycle.description ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.bakerAlias == "Baking Benjamins", rewards.estimatedPreviousReward?.bakerAlias ?? "")
					
					XCTAssert(rewards.estimatedNextReward?.delegateAmount.normalisedRepresentation == "5.649137", rewards.estimatedNextReward?.delegateAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedNextReward?.stakeAmount.normalisedRepresentation == "20.325563", rewards.estimatedNextReward?.stakeAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedNextReward?.delegateFee.description == "0.2", rewards.estimatedNextReward?.delegateFee.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.stakeFee.description == "0.1", rewards.estimatedNextReward?.stakeFee.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.cycle.description == "801", rewards.estimatedNextReward?.cycle.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.bakerAlias == "Baking Benjamins", rewards.estimatedNextReward?.bakerAlias ?? "")
					
					XCTAssert(rewards.moreThan1CycleBetweenPreiousAndNext() == false)
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testEstimateRewardsNoPayoutAddress() {
		let expectation = XCTestExpectation(description: "tzkt-testEstimateRewardsNoPayoutAddress")
		let delegate = TzKTAccountDelegate(alias: "The", address: "tz1ZgkTFmiwddPXGbs4yc6NWdH4gELW7wsnv", active: true)
		
		MockConstants.shared.tzktClient.estimateLastAndNextReward(forAddress: MockConstants.defaultHdWallet.address, delegate: delegate, forceMainnet: true) { result in
			switch result {
				case .success(let rewards):
					XCTAssert(rewards.previousReward == nil, rewards.previousReward?.delegateAmount.description ?? "")
					
					XCTAssert(rewards.estimatedPreviousReward?.delegateAmount.normalisedRepresentation == "0.926949", rewards.estimatedPreviousReward?.delegateAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.stakeAmount.normalisedRepresentation == "0", rewards.estimatedPreviousReward?.stakeAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.delegateFee.description == "0.2", rewards.estimatedPreviousReward?.delegateFee.description ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.stakeFee.description == "0.1", rewards.estimatedPreviousReward?.stakeFee.description ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.cycle.description == "797", rewards.estimatedPreviousReward?.cycle.description ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.bakerAlias == "Baking Benjamins", rewards.estimatedPreviousReward?.bakerAlias ?? "")
					
					XCTAssert(rewards.estimatedNextReward?.delegateAmount.normalisedRepresentation == "0.851008", rewards.estimatedNextReward?.delegateAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedNextReward?.stakeAmount.normalisedRepresentation == "0", rewards.estimatedNextReward?.stakeAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedNextReward?.delegateFee.description == "0.2", rewards.estimatedNextReward?.delegateFee.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.stakeFee.description == "0.1", rewards.estimatedNextReward?.stakeFee.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.cycle.description == "798", rewards.estimatedNextReward?.cycle.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.bakerAlias == "Baking Benjamins", rewards.estimatedNextReward?.bakerAlias ?? "")
					
					XCTAssert(rewards.moreThan1CycleBetweenPreiousAndNext() == false)
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testEstimateRewardsNoPrevious() {
		let expectation = XCTestExpectation(description: "tzkt-testEstimateRewardsNoPrevious")
		let delegate = TzKTAccountDelegate(alias: "The Shire", address: "tz1ZgkTFmiwddPXGbs4yc6NWdH4gELW7wsnv", active: true)
		
		MockConstants.shared.tzktClient.estimateLastAndNextReward(forAddress: "tz1iv8r8UUCEZK5gqpLPnMPzP4VRJBJUdGgr", delegate: delegate, forceMainnet: true) { result in
			switch result {
				case .success(let rewards):
					XCTAssert(rewards.previousReward == nil, rewards.previousReward?.delegateAmount.description ?? "")
					
					XCTAssert(rewards.estimatedPreviousReward == nil, rewards.estimatedPreviousReward?.delegateAmount.normalisedRepresentation ?? "")
					
					XCTAssert(rewards.estimatedNextReward?.delegateAmount.normalisedRepresentation == "0.000369", rewards.estimatedNextReward?.delegateAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedNextReward?.stakeAmount.normalisedRepresentation == "0", rewards.estimatedNextReward?.stakeAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedNextReward?.delegateFee.description == "0.042", rewards.estimatedNextReward?.delegateFee.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.stakeFee.description == "0.042", rewards.estimatedNextReward?.stakeFee.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.cycle.description == "748", rewards.estimatedNextReward?.cycle.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.bakerAlias == "The Shire", rewards.estimatedNextReward?.bakerAlias ?? "")
					
					XCTAssert(rewards.moreThan1CycleBetweenPreiousAndNext() == false)
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testEstimateRewardsNone() {
		let expectation = XCTestExpectation(description: "tzkt-testEstimateRewardsNone")
		let delegate = TzKTAccountDelegate(alias: "Teztillery", address: "tz1bdTgmF8pzBH9chtJptsjjrh5UfSXp1SQ4", active: true)
		
		MockConstants.shared.tzktClient.estimateLastAndNextReward(forAddress: "tz1ckwbvP7pdTLS1aAe6YPoiKpG2d8ENU8Ac", delegate: delegate, forceMainnet: true) { result in
			switch result {
				case .success(let rewards):
					XCTAssert(rewards.previousReward == nil, rewards.previousReward?.delegateAmount.description ?? "")
					
					XCTAssert(rewards.estimatedPreviousReward == nil, rewards.estimatedPreviousReward?.delegateAmount.normalisedRepresentation ?? "")
					
					XCTAssert(rewards.estimatedNextReward?.delegateAmount.normalisedRepresentation == "0", rewards.estimatedNextReward?.delegateAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedNextReward?.stakeAmount.normalisedRepresentation == "0", rewards.estimatedNextReward?.stakeAmount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedNextReward?.delegateFee.description == "0.0499", rewards.estimatedNextReward?.delegateFee.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.stakeFee.description == "0.05", rewards.estimatedNextReward?.stakeFee.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.cycle.description == "752", rewards.estimatedNextReward?.cycle.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.bakerAlias == "Teztillery", rewards.estimatedNextReward?.bakerAlias ?? "")
					
					XCTAssert(rewards.moreThan1CycleBetweenPreiousAndNext() == false)
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testBakers() {
		let expectation = XCTestExpectation(description: "tzkt-bakers")
		
		MockConstants.shared.tzktClient.bakers { result in
			switch result {
				case .success(let bakers):
					XCTAssert(bakers.count == 22, bakers.count.description)
					XCTAssert(bakers[0].name == "Baking Benjamins", bakers[0].name ?? "")
					XCTAssert(bakers[0].address == "tz1YgDUQV2eXm8pUWNz3S5aWP86iFzNp4jnD", bakers[0].address)
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
    
    func testBakersMainnet() {
        let expectation = XCTestExpectation(description: "tzkt-bakers-mainent")
        
        MockConstants.shared.tzktClient.bakers { result in
            switch result {
                case .success(let bakers):
                    XCTAssert(bakers.count == 22, bakers.count.description)
                    XCTAssert(bakers[0].name == "Baking Benjamins", bakers[0].name ?? "")
                    XCTAssert(bakers[0].address == "tz1YgDUQV2eXm8pUWNz3S5aWP86iFzNp4jnD", bakers[0].address)
                    
                case .failure(let error):
                    XCTFail("Error: \(error)")
            }
            
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 120)
    }
	
	func testBakerVoteParticipation() {
		let expectation = XCTestExpectation(description: "tzkt-vote-participation")
		
		MockConstants.shared.tzktClient.checkBakerVoteParticipation(forAddress: "tz1abc123", completion: { result in
			switch result {
				case .success(let votes):
				XCTAssert(votes.count == 5, votes.count.description)
				
				let filterOnlyTrue = votes.filter({ $0 }).count
				XCTAssert(filterOnlyTrue == 4, filterOnlyTrue.description)
				
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectation.fulfill()
		})
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testGhostnetBakerConfig() {
		let expectation = XCTestExpectation(description: "tzkt-ghostnet-baker-config")
		
		MockConstants.shared.tzktClient.bakerConfig(forAddress: "tz1abc123", forceMainnet: false, completion: { result in
			switch result {
				case .success(let baker):
				XCTAssert(baker.name == "Baking Benjamins", baker.name ?? "-")
				XCTAssert(baker.address == "tz1YgDUQV2eXm8pUWNz3S5aWP86iFzNp4jnD", baker.address)
				XCTAssert(baker.balance.description == "76085813.531722", baker.balance.description)
				
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectation.fulfill()
		})
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testPendingStakingUpdates() {
		let expectation = XCTestExpectation(description: "tzkt-pending-staking-updates")
		
		MockConstants.shared.tzktClient.pendingStakingUpdates(forAddress: "tz1abc123", ofType: "unstake") { result in
			switch result {
				case .success(let updates):
					XCTAssert(updates.count == 2, updates.count.description)
					XCTAssert(updates.first?.cycle == 1272, updates.first?.cycle.description ?? "-")
					XCTAssert(updates.first?.xtzAmount.normalisedRepresentation == "2.999997", updates.first?.xtzAmount.normalisedRepresentation ?? "-")
					XCTAssert(updates.first?.dateTime.description == "2024-11-22 10:08:35 +0000", updates.first?.dateTime.description ?? "-")
				
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
}
