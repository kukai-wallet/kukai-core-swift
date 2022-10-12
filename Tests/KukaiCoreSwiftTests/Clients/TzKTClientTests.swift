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
	
	func testTransactionHistory() {
		let expectation = XCTestExpectation(description: "tzkt-testTransactionHistory")
		
		MockConstants.shared.tzktClient.fetchTransactions(forAddress: MockConstants.defaultHdWallet.address) { transactions in
			let groups = MockConstants.shared.tzktClient.groupTransactions(transactions: transactions, currentWalletAddress: MockConstants.defaultHdWallet.address)
			
			XCTAssert(groups.count == 35, "\(groups.count)")
			
			XCTAssert(groups[0].groupType == .exchange, groups[0].groupType.rawValue)
			
			// Test Exchange
			XCTAssert(groups[0].hash == "opPA7o4i7JtR2bnsW7rTnqFHoTzK4kDcMgV5SJmR6QS8vhYHp2X", groups[0].hash)
			XCTAssert(groups[0].primaryToken?.token.tokenContractAddress == "KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn", groups[0].primaryToken?.token.tokenContractAddress ?? "-")
			XCTAssert(groups[0].primaryToken?.token.tokenId == 0, groups[0].primaryToken?.token.tokenId?.description ?? "-")
			XCTAssert(groups[0].primaryToken?.amount.normalisedRepresentation == "811", groups[0].primaryToken?.amount.normalisedRepresentation ?? "-")
			XCTAssert(groups[0].secondaryToken?.token.tokenContractAddress == nil, groups[0].secondaryToken?.token.tokenContractAddress ?? "-")
			XCTAssert(groups[0].secondaryToken?.token.tokenId == nil, groups[0].secondaryToken?.token.tokenId?.description ?? "-")
			XCTAssert(groups[0].secondaryToken?.amount.normalisedRepresentation == "0.107519", groups[0].secondaryToken?.amount.normalisedRepresentation ?? "-")
			XCTAssert(groups[0].entrypointCalled == nil, groups[0].entrypointCalled ?? "-")
			
			XCTAssert(groups[0].transactions.count == 4, "\(groups[0].transactions.count)")
			XCTAssert(groups[0].transactions[0].id == 184404704, "\(groups[0].transactions[0].id)")
			XCTAssert(groups[0].transactions[0].amount.normalisedRepresentation == "0.107519", groups[0].transactions[0].amount.normalisedRepresentation)
			XCTAssert(groups[0].transactions[1].id == 184404703, "\(groups[0].transactions[1].id)")
			XCTAssert(groups[0].transactions[1].amount.normalisedRepresentation == "0", groups[0].transactions[1].amount.normalisedRepresentation)
			XCTAssert(groups[0].transactions[2].id == 184404702, "\(groups[0].transactions[2].id)")
			XCTAssert(groups[0].transactions[2].amount.normalisedRepresentation == "0", groups[0].transactions[2].amount.normalisedRepresentation)
			
			// Test Receive
			XCTAssert(groups[1].hash == "onvh7egDq7RmM9CaY8W2hKMPxF4fNhv6sDaNxvpnDKqKNrAwVQq", groups[1].hash)
			XCTAssert(groups[1].primaryToken?.token.tokenContractAddress == nil, groups[1].primaryToken?.token.tokenContractAddress ?? "-")
			XCTAssert(groups[1].primaryToken?.token.tokenId == nil, groups[1].primaryToken?.token.tokenId?.description ?? "-")
			XCTAssert(groups[1].primaryToken?.amount.normalisedRepresentation == "3.298723", groups[1].primaryToken?.amount.normalisedRepresentation ?? "-")
			XCTAssert(groups[1].secondaryToken?.token.tokenContractAddress == nil, groups[1].secondaryToken?.token.tokenContractAddress ?? "-")
			XCTAssert(groups[1].secondaryToken?.token.tokenId == nil, groups[1].secondaryToken?.token.tokenId?.description ?? "-")
			XCTAssert(groups[1].secondaryToken?.amount.normalisedRepresentation == nil, groups[1].secondaryToken?.amount.normalisedRepresentation ?? "-")
			XCTAssert(groups[1].entrypointCalled == nil, groups[1].entrypointCalled ?? "-")
			
			// Test Contract call
			XCTAssert(groups[4].hash == "oosSXAfCAqq18RUydvLvzajATaKzE9DcmgWEKHpqKsQBZGPmrwi", groups[4].hash)
			XCTAssert(groups[4].primaryToken?.token.tokenContractAddress == nil, groups[4].primaryToken?.token.tokenContractAddress ?? "-")
			XCTAssert(groups[4].primaryToken?.token.tokenId == nil, groups[4].primaryToken?.token.tokenId?.description ?? "-")
			XCTAssert(groups[4].primaryToken?.amount.normalisedRepresentation == nil, groups[4].primaryToken?.amount.normalisedRepresentation ?? "-")
			XCTAssert(groups[4].secondaryToken?.token.tokenContractAddress == nil, groups[4].secondaryToken?.token.tokenContractAddress ?? "-")
			XCTAssert(groups[4].secondaryToken?.token.tokenId == nil, groups[4].secondaryToken?.token.tokenId?.description ?? "-")
			XCTAssert(groups[4].secondaryToken?.amount.normalisedRepresentation == nil, groups[4].secondaryToken?.amount.normalisedRepresentation ?? "-")
			XCTAssert(groups[4].entrypointCalled == "update_operators", groups[4].entrypointCalled ?? "-")
			
			// Test Harvest
			XCTAssert(groups[6].hash == "oopWrK35bXMtHoeHsRRUfaMgDX8NNGAVJBzior57zkJWVYubgGX", groups[6].hash)
			XCTAssert(groups[6].primaryToken?.token.tokenContractAddress == nil, groups[6].primaryToken?.token.tokenContractAddress ?? "-")
			XCTAssert(groups[6].primaryToken?.token.tokenId == nil, groups[6].primaryToken?.token.tokenId?.description ?? "-")
			XCTAssert(groups[6].primaryToken?.amount.normalisedRepresentation == nil, groups[6].primaryToken?.amount.normalisedRepresentation ?? "-")
			XCTAssert(groups[6].secondaryToken?.token.tokenContractAddress == nil, groups[6].secondaryToken?.token.tokenContractAddress ?? "-")
			XCTAssert(groups[6].secondaryToken?.token.tokenId == nil, groups[6].secondaryToken?.token.tokenId?.description ?? "-")
			XCTAssert(groups[6].secondaryToken?.amount.normalisedRepresentation == nil, groups[6].secondaryToken?.amount.normalisedRepresentation ?? "-")
			XCTAssert(groups[6].entrypointCalled == "harvest", groups[6].entrypointCalled ?? "-")
			
			XCTAssert(groups[6].transactions.count == 6, "\(groups[6].transactions.count)")
			XCTAssert(groups[6].transactions[0].id == 183382669, "\(groups[6].transactions[0].id)")
			XCTAssert(groups[6].transactions[0].amount.normalisedRepresentation == "0", groups[6].transactions[0].amount.normalisedRepresentation)
			XCTAssert(groups[6].transactions[0].getFaTokenTransferData()?.amount.normalisedRepresentation == "387545563", groups[6].transactions[0].getFaTokenTransferData()?.amount.normalisedRepresentation ?? "-")
			XCTAssert(groups[6].transactions[1].id == 183382668, "\(groups[6].transactions[1].id)")
			XCTAssert(groups[6].transactions[1].amount.normalisedRepresentation == "0", groups[6].transactions[1].amount.normalisedRepresentation)
			XCTAssert(groups[6].transactions[1].getFaTokenTransferData()?.amount.normalisedRepresentation == nil, groups[6].transactions[1].getFaTokenTransferData()?.amount.normalisedRepresentation ?? "-")
			XCTAssert(groups[6].transactions[2].id == 183382667, "\(groups[6].transactions[2].id)")
			XCTAssert(groups[6].transactions[2].amount.normalisedRepresentation == "0", groups[6].transactions[2].amount.normalisedRepresentation)
			XCTAssert(groups[6].transactions[2].getFaTokenTransferData()?.amount.normalisedRepresentation == "435173012223", groups[6].transactions[2].getFaTokenTransferData()?.amount.normalisedRepresentation ?? "-")
			
			// Test FA receive
			XCTAssert(groups[14].hash == "ooetYdtgaC7FTYwfTmWYMHL688ax4vqfcV46MZjXhzQBY7xT9dA", groups[14].hash)
			XCTAssert(groups[14].primaryToken?.token.tokenContractAddress == "KT1Qm7MHmbdiBzoRs7xqBiqoRxw7T2cxTTJN", groups[14].primaryToken?.token.tokenContractAddress ?? "-")
			XCTAssert(groups[14].primaryToken?.token.tokenId == 2, groups[14].primaryToken?.token.tokenId?.description ?? "-")
			XCTAssert(groups[14].primaryToken?.amount.normalisedRepresentation == "2", groups[14].primaryToken?.amount.normalisedRepresentation ?? "-")
			XCTAssert(groups[14].secondaryToken?.token.tokenContractAddress == nil, groups[14].secondaryToken?.token.tokenContractAddress ?? "-")
			XCTAssert(groups[14].secondaryToken?.token.tokenId == nil, groups[14].secondaryToken?.token.tokenId?.description ?? "-")
			XCTAssert(groups[14].secondaryToken?.amount.normalisedRepresentation == nil, groups[14].secondaryToken?.amount.normalisedRepresentation ?? "-")
			XCTAssert(groups[14].entrypointCalled == "transfer", groups[14].entrypointCalled ?? "-")
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 5)
	}
	
	func testGetAllBalances() {
		let expectation = XCTestExpectation(description: "tzkt-testGetAllBalances")
		MockConstants.shared.tzktClient.getAllBalances(forAddress: MockConstants.defaultHdWallet.address) { result in
			
			switch result {
				case .success(let account):
					XCTAssert(account.xtzBalance.normalisedRepresentation == "1.843617", account.xtzBalance.normalisedRepresentation)
					XCTAssert(account.tokens.count == 20, "\(account.tokens.count)")
					XCTAssert(account.tokens[0].symbol == "kUSD", account.tokens[0].symbol)
					XCTAssert(account.tokens[0].name == "Kolibri USD", account.tokens[0].name ?? "")
					XCTAssert(account.tokens[0].balance.normalisedRepresentation == "1.122564894578671941", account.tokens[0].balance.normalisedRepresentation)
					XCTAssert(account.tokens[1].symbol == "USDtz", account.tokens[1].symbol)
					XCTAssert(account.tokens[1].name == "USDtez", account.tokens[1].name ?? "")
					XCTAssert(account.tokens[1].balance.normalisedRepresentation == "0.004337", account.tokens[1].balance.normalisedRepresentation)
					XCTAssert(account.tokens[2].symbol == "crDAO", account.tokens[2].symbol)
					XCTAssert(account.tokens[2].name == "Crunchy DAO", account.tokens[2].name ?? "")
					XCTAssert(account.tokens[2].balance.normalisedRepresentation == "0.12810553", account.tokens[2].balance.normalisedRepresentation)
					
					XCTAssert(account.nfts.count == 6, "\(account.nfts.count)")
					XCTAssert(account.nfts[0].nfts?.count == 1, "\(account.nfts[0].nfts?.count ?? -1)")
					XCTAssert(account.nfts[0].nfts?[0].name == "Taco Mooncake", account.nfts[0].nfts?[0].name ?? "")
					XCTAssert(account.nfts[0].nfts?[0].artifactURL?.absoluteString == "https://static.tcinfra.net/media/small/ipfs/QmeDXtDWpPBeG41izwVYoYbFseczshGMR9JEtm6dc8d83Q", account.nfts[0].nfts?[0].artifactURL?.absoluteString ?? "")
					let keyValueAttributes1 = account.nfts[0].nfts?[0].metadata?.getKeyValueTuplesFromAttributes() ?? []
					XCTAssert(keyValueAttributes1.count == 5, "\(keyValueAttributes1.count)")
					XCTAssert(keyValueAttributes1[0].key == "Mood", keyValueAttributes1[0].key)
					XCTAssert(keyValueAttributes1[0].value == "Taco Tuesday", keyValueAttributes1[0].value)
					XCTAssert(keyValueAttributes1[1].key == "Artist", keyValueAttributes1[1].key)
					XCTAssert(keyValueAttributes1[1].value == "Taco", keyValueAttributes1[1].value)
					XCTAssert(keyValueAttributes1[2].key == "Thought", keyValueAttributes1[2].key)
					XCTAssert(keyValueAttributes1[2].value == "This is my kind of dessert", keyValueAttributes1[2].value)
					
					
					XCTAssert(account.nfts[1].nfts?[0].name == "Zachary Taylor (C)", account.nfts[1].nfts?[0].name ?? "")
					XCTAssert(account.nfts[1].nfts?[0].artifactURL?.absoluteString == "https://static.tcinfra.net/media/small/ipfs/Qmczgp9juksRrzDkXUQQQFb9xwNDimv1gTy6kLjZqVNPoX/full/1012.png", account.nfts[1].nfts?[0].artifactURL?.absoluteString ?? "")
					let keyValueAttributes2 = account.nfts[1].nfts?[0].metadata?.getKeyValueTuplesFromAttributes() ?? []
					XCTAssert(keyValueAttributes2.count == 0, "\(keyValueAttributes2.count)")
					
					
					XCTAssert(account.nfts[2].nfts?[0].name == "Press Your Buttons - Fragment 3", account.nfts[2].nfts?[0].name ?? "")
					XCTAssert(account.nfts[2].nfts?[0].artifactURL?.absoluteString == "https://static.tcinfra.net/media/small/ipfs/QmQ1gVgmE3pfXYH5bL9n1NXA5n9g4XW1mihcrRe4pa2StG", account.nfts[2].nfts?[0].artifactURL?.absoluteString ?? "")
					let keyValueAttributes3 = account.nfts[2].nfts?[0].metadata?.getKeyValueTuplesFromAttributes() ?? []
					XCTAssert(keyValueAttributes3.count == 4, "\(keyValueAttributes3.count)")
					XCTAssert(keyValueAttributes3[0].key == "Cost", keyValueAttributes3[0].key)
					XCTAssert(keyValueAttributes3[0].value == "3", keyValueAttributes3[0].value)
					XCTAssert(keyValueAttributes3[1].key == "Strength", keyValueAttributes3[1].key)
					XCTAssert(keyValueAttributes3[1].value == "5", keyValueAttributes3[1].value)
					XCTAssert(keyValueAttributes3[2].key == "Abilities", keyValueAttributes3[2].key)
					XCTAssert(keyValueAttributes3[2].value == "Reversible: Opponents arguments cost 1 more.", keyValueAttributes3[2].value)
					
					
					
					XCTAssert(account.liquidityTokens.count == 2, "\(account.liquidityTokens.count)")
					XCTAssert(account.liquidityTokens[0].sharesQty == "91", account.liquidityTokens[0].sharesQty)
					XCTAssert(account.liquidityTokens[0].exchange.token.symbol == "tzBTC", account.liquidityTokens[0].exchange.token.symbol)
					
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
	
	func testEstimateRewards() {
		let expectation = XCTestExpectation(description: "tzkt-testEstimateRewards")
		let delegate = TzKTAccountDelegate(alias: "The Shire", address: "tz1ZgkTFmiwddPXGbs4yc6NWdH4gELW7wsnv", active: true)
		
		MockConstants.shared.tzktClient.estimateLastAndNextReward(forAddress: MockConstants.defaultHdWallet.address, delegate: delegate) { result in
			switch result {
				case .success(let rewards):
					XCTAssert(rewards.previousReward?.amount.description == "0.207106", rewards.previousReward?.amount.description ?? "")
					XCTAssert(rewards.previousReward?.fee.description == "0.05", rewards.previousReward?.fee.description ?? "")
					XCTAssert(rewards.previousReward?.cycle.description == "515", rewards.previousReward?.cycle.description ?? "")
					XCTAssert(rewards.previousReward?.bakerAlias == "Bake Nug", rewards.previousReward?.bakerAlias ?? "")
					
					XCTAssert(rewards.estimatedPreviousReward?.amount.normalisedRepresentation == "0.197861", rewards.estimatedPreviousReward?.amount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.fee.description == "0.05", rewards.estimatedPreviousReward?.fee.description ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.cycle.description == "516", rewards.estimatedPreviousReward?.cycle.description ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.bakerAlias == "Bake Nug", rewards.estimatedPreviousReward?.bakerAlias ?? "")
					
					XCTAssert(rewards.estimatedNextReward?.amount.normalisedRepresentation == "0.034051", rewards.estimatedNextReward?.amount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedNextReward?.fee.description == "0.05", rewards.estimatedNextReward?.fee.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.cycle.description == "517", rewards.estimatedNextReward?.cycle.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.bakerAlias == "Bake Nug", rewards.estimatedNextReward?.bakerAlias ?? "")
					
					XCTAssert(rewards.moreThan1CycleBetweenPreiousAndNext() == true)
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 30)
	}
}
