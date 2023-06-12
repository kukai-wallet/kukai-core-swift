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
		
		wait(for: [expectation], timeout: 10)
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
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testTransactionHistory() {
		let expectation = XCTestExpectation(description: "tzkt-testTransactionHistory")
		
		MockConstants.shared.tzktClient.fetchTransactions(forAddress: MockConstants.defaultHdWallet.address) { transactions in
			/*let groups = MockConstants.shared.tzktClient.groupTransactions(transactions: transactions, currentWalletAddress: MockConstants.defaultHdWallet.address)
			
			XCTAssert(groups.count == 118, "\(groups.count)")
			
			// Test FA receive 1 mooncake
			XCTAssert(groups[0].groupType == .receive, groups[0].groupType.rawValue)
			XCTAssert(groups[0].hash == "491989007073282", groups[0].hash)
			XCTAssert(groups[0].primaryToken?.tokenContractAddress == "KT1CzVSa18hndYupV9NcXy3Qj7p8YFDZKVQv", groups[0].primaryToken?.tokenContractAddress ?? "-")
			XCTAssert(groups[0].primaryToken?.balance.normalisedRepresentation == "1", groups[0].primaryToken?.balance.normalisedRepresentation ?? "-")
			XCTAssert(groups[0].primaryToken?.name == "Mystique Mooncake", groups[0].primaryToken?.name ?? "-")
			
			
			// Test FA receive token with decimals as part of a batch
			XCTAssert(groups[41].groupType == .receive, groups[41].groupType.rawValue)
			XCTAssert(groups[41].transactions.count == 1, groups[41].transactions.count.description)
			XCTAssert(groups[41].hash == "450568422162433", groups[41].hash)
			XCTAssert(groups[41].primaryToken?.tokenContractAddress == "KT1JVjgXPMMSaa6FkzeJcgb8q9cUaLmwaJUX", groups[41].primaryToken?.tokenContractAddress ?? "-")
			XCTAssert(groups[41].primaryToken?.balance.normalisedRepresentation == "251.870030155121634748", groups[41].primaryToken?.balance.normalisedRepresentation ?? "-")
			XCTAssert(groups[41].primaryToken?.name == "Plenty PLY", groups[41].primaryToken?.name ?? "-")
			
			
			// Test FA send
			XCTAssert(groups[46].groupType == .send, groups[46].groupType.rawValue)
			XCTAssert(groups[46].transactions.count == 1, groups[46].transactions.count.description)
			XCTAssert(groups[46].hash == "448920109973506", groups[46].hash)
			XCTAssert(groups[46].primaryToken?.tokenContractAddress == "KT1CzVSa18hndYupV9NcXy3Qj7p8YFDZKVQv", groups[46].primaryToken?.tokenContractAddress ?? "-")
			XCTAssert(groups[46].primaryToken?.balance.normalisedRepresentation == "2", groups[46].primaryToken?.balance.normalisedRepresentation ?? "-")
			XCTAssert(groups[46].primaryToken?.name == "Longevity Mooncake", groups[46].primaryToken?.name ?? "-")
			
			
			// Test Exchange
			XCTAssert(groups[100].groupType == .contractCall, groups[100].groupType.rawValue)
			XCTAssert(groups[100].hash == "opPA7o4i7JtR2bnsW7rTnqFHoTzK4kDcMgV5SJmR6QS8vhYHp2X", groups[100].hash)
			XCTAssert(groups[100].entrypointCalled == "tokenToTezPayment", groups[100].entrypointCalled ?? "-")
			
			XCTAssert(groups[100].transactions.count == 3, groups[84].transactions.count.description)
			XCTAssert(groups[100].transactions[0].primaryToken?.balance.normalisedRepresentation == "0.107519", groups[100].transactions[0].primaryToken?.balance.normalisedRepresentation ?? "-")
			XCTAssert(groups[100].transactions[0].primaryToken?.symbol == "XTZ", groups[100].transactions[0].primaryToken?.symbol ?? "-")
			
			// Test Receive
			XCTAssert(groups[101].hash == "onvh7egDq7RmM9CaY8W2hKMPxF4fNhv6sDaNxvpnDKqKNrAwVQq", groups[101].hash)
			XCTAssert(groups[101].primaryToken?.tokenContractAddress == nil, groups[101].primaryToken?.tokenContractAddress ?? "-")
			XCTAssert(groups[101].primaryToken?.tokenId == nil, groups[101].primaryToken?.tokenId?.description ?? "-")
			XCTAssert(groups[101].primaryToken?.balance.normalisedRepresentation == "3.298723", groups[101].primaryToken?.balance.normalisedRepresentation ?? "-")
			XCTAssert(groups[101].secondaryToken?.tokenContractAddress == nil, groups[101].secondaryToken?.tokenContractAddress ?? "-")
			XCTAssert(groups[101].secondaryToken?.tokenId == nil, groups[101].secondaryToken?.tokenId?.description ?? "-")
			XCTAssert(groups[101].secondaryToken?.balance.normalisedRepresentation == nil, groups[101].secondaryToken?.balance.normalisedRepresentation ?? "-")
			XCTAssert(groups[101].entrypointCalled == nil, groups[101].entrypointCalled ?? "-")
			
			// Test Contract call
			XCTAssert(groups[104].hash == "oosSXAfCAqq18RUydvLvzajATaKzE9DcmgWEKHpqKsQBZGPmrwi", groups[104].hash)
			XCTAssert(groups[104].primaryToken?.tokenContractAddress == nil, groups[104].primaryToken?.tokenContractAddress ?? "-")
			XCTAssert(groups[104].primaryToken?.tokenId == nil, groups[104].primaryToken?.tokenId?.description ?? "-")
			XCTAssert(groups[104].primaryToken?.balance.normalisedRepresentation == nil, groups[104].primaryToken?.balance.normalisedRepresentation ?? "-")
			XCTAssert(groups[104].secondaryToken?.tokenContractAddress == nil, groups[104].secondaryToken?.tokenContractAddress ?? "-")
			XCTAssert(groups[104].secondaryToken?.tokenId == nil, groups[104].secondaryToken?.tokenId?.description ?? "-")
			XCTAssert(groups[104].secondaryToken?.balance.normalisedRepresentation == nil, groups[104].secondaryToken?.balance.normalisedRepresentation ?? "-")
			XCTAssert(groups[104].entrypointCalled == "ask", groups[104].entrypointCalled ?? "-")
			
			// Test Harvest
			XCTAssert(groups[106].groupType == .contractCall, groups[106].groupType.rawValue)
			XCTAssert(groups[106].hash == "oopWrK35bXMtHoeHsRRUfaMgDX8NNGAVJBzior57zkJWVYubgGX", groups[106].hash)
			XCTAssert(groups[106].entrypointCalled == "harvest", groups[106].entrypointCalled ?? "-")
			*/
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testGetAllBalances() {
		let expectation = XCTestExpectation(description: "tzkt-testGetAllBalances")
		MockConstants.shared.tzktClient.getAllBalances(forAddress: MockConstants.defaultHdWallet.address) { result in
			
			switch result {
				case .success(let account):
					XCTAssert(account.xtzBalance.normalisedRepresentation == "1.843617", account.xtzBalance.normalisedRepresentation)
					XCTAssert(account.tokens.count == 20, "\(account.tokens.count)")
					XCTAssert(account.tokens[0].symbol == "kUSD", account.tokens[0].symbol)
					XCTAssert(account.tokens[0].name == "kUSD", account.tokens[0].name ?? "")
					XCTAssert(account.tokens[0].balance.normalisedRepresentation == "1.122564894578671941", account.tokens[0].balance.normalisedRepresentation)
					XCTAssert(account.tokens[1].symbol == "USDtz", account.tokens[1].symbol)
					XCTAssert(account.tokens[1].name == "USDtz", account.tokens[1].name ?? "")
					XCTAssert(account.tokens[1].balance.normalisedRepresentation == "0.004337", account.tokens[1].balance.normalisedRepresentation)
					XCTAssert(account.tokens[2].symbol == "crDAO", account.tokens[2].symbol)
					XCTAssert(account.tokens[2].name == "crDAO", account.tokens[2].name ?? "")
					XCTAssert(account.tokens[2].balance.normalisedRepresentation == "0.12810553", account.tokens[2].balance.normalisedRepresentation)
					
					XCTAssert(account.nfts.count == 6, "\(account.nfts.count)")
					XCTAssert(account.nfts[0].nfts?.count == 1, "\(account.nfts[0].nfts?.count ?? -1)")
					XCTAssert(account.nfts[0].nfts?[0].name == "Taco Mooncake", account.nfts[0].nfts?[0].name ?? "")
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
					
					
					
					XCTAssert(account.liquidityTokens.count == 2, "\(account.liquidityTokens.count)")
					XCTAssert(account.liquidityTokens[0].sharesQty == "91", account.liquidityTokens[0].sharesQty)
					XCTAssert(account.liquidityTokens[0].exchange.token.symbol == "tzBTC", account.liquidityTokens[0].exchange.token.symbol)
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 30)
	}
	
	func testAvatarURL() {
		let url = TzKTClient.avatarURL(forToken: "KT1abc123")
		
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
	
	func testEstimateRewardsNoPayoutAddress() {
		let expectation = XCTestExpectation(description: "tzkt-testEstimateRewardsNoPayoutAddress")
		let delegate = TzKTAccountDelegate(alias: "The", address: "tz1ZgkTFmiwddPXGbs4yc6NWdH4gELW7wsnv", active: true)
		
		MockConstants.shared.tzktClient.estimateLastAndNextReward(forAddress: MockConstants.defaultHdWallet.address, delegate: delegate) { result in
			switch result {
				case .success(let rewards):
					XCTAssert(rewards.previousReward == nil, rewards.previousReward?.amount.description ?? "")
					
					XCTAssert(rewards.estimatedPreviousReward?.amount.normalisedRepresentation == "0.197861", rewards.estimatedPreviousReward?.amount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.fee.description == "0.05", rewards.estimatedPreviousReward?.fee.description ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.cycle.description == "516", rewards.estimatedPreviousReward?.cycle.description ?? "")
					XCTAssert(rewards.estimatedPreviousReward?.bakerAlias == "Bake Nug", rewards.estimatedPreviousReward?.bakerAlias ?? "")
					
					XCTAssert(rewards.estimatedNextReward?.amount.normalisedRepresentation == "0.034051", rewards.estimatedNextReward?.amount.normalisedRepresentation ?? "")
					XCTAssert(rewards.estimatedNextReward?.fee.description == "0.05", rewards.estimatedNextReward?.fee.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.cycle.description == "517", rewards.estimatedNextReward?.cycle.description ?? "")
					XCTAssert(rewards.estimatedNextReward?.bakerAlias == "Bake Nug", rewards.estimatedNextReward?.bakerAlias ?? "")
					
					XCTAssert(rewards.moreThan1CycleBetweenPreiousAndNext() == false)
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 30)
	}
}
