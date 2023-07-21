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
			let groups = MockConstants.shared.tzktClient.groupTransactions(transactions: transactions, currentWalletAddress: MockConstants.defaultHdWallet.address)
			
			XCTAssert(groups.count == 17, "\(groups.count)")
			
			for (index, group) in groups.enumerated() {
				
				switch index {
					case 0:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "op3K5QH2Tho6sUJy54hyRDXaRa7p11AvoVfZDmT4gLojFFDGG6Y", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1CzVSa18hndYupV9NcXy3Qj7p8YFDZKVQv", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "1", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "Wood Mooncake", group.primaryToken?.name ?? "-")
						
					case 1:
						XCTAssert(group.groupType == .contractCall, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "op3K5QH2Tho6sUJy54hyRDXaRa7p11AvoVfZDmT4gLojFFDGG6Y", group.hash)
						XCTAssert(group.entrypointCalled == "claim", group.entrypointCalled ?? "-")
						
					case 2:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "opRQnyqN4fogpRSBCuxFpCm9SGooy1QY3r5Xc4FXre33tNFWh97", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1CzVSa18hndYupV9NcXy3Qj7p8YFDZKVQv", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "1", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "Wood Mooncake", group.primaryToken?.name ?? "-")
						
					case 3:
						XCTAssert(group.groupType == .contractCall, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "opRQnyqN4fogpRSBCuxFpCm9SGooy1QY3r5Xc4FXre33tNFWh97", group.hash)
						XCTAssert(group.entrypointCalled == "claim", group.entrypointCalled ?? "-")
						
					case 4:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "oopQFnCyS9fPYeBftynXH6coUUAy4UPBuA3Hcp8nsApYNKxVuRx", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == nil, group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "0.5", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "Tezos", group.primaryToken?.name ?? "-")
						
					case 5:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "onjmwjKLUPVpguDVYSZp2yh1tqGPp5oEgAjSbiFvxv74XsmMarg", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1914CUZ7EegAFPbfgQMRkw8Uz5mYkEz2ui", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "228.9299288", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "Crunchy.Network CRNCHY", group.primaryToken?.name ?? "-")
						
					case 6:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "onjmwjKLUPVpguDVYSZp2yh1tqGPp5oEgAjSbiFvxv74XsmMarg", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == nil, group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "0.102422", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "Tezos", group.primaryToken?.name ?? "-")
						
					case 7:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "onjmwjKLUPVpguDVYSZp2yh1tqGPp5oEgAjSbiFvxv74XsmMarg", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1KPoyzkj82Sbnafm6pfesZKEhyCpXwQfMc", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "3.160106", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "fDAO", group.primaryToken?.name ?? "-")
						
					case 8:
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
						
					case 9:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "onqrPbMuVZy6dDELwhXfdF8BbANXy5mLj47gjAf7CE5cAUvSVoQ", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1U6EHmNxJTkvaWJ4ThczG4FSDaHC21ssvi", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "1", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "Unknown Token", group.primaryToken?.name ?? "-")
						
					case 10:
						XCTAssert(group.groupType == .contractCall, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "onqrPbMuVZy6dDELwhXfdF8BbANXy5mLj47gjAf7CE5cAUvSVoQ", group.hash)
						XCTAssert(group.entrypointCalled == "mint", group.entrypointCalled ?? "-")
						
					case 11:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "589699422879746", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1BRADdqGk2eLmMqvyWzqVmPQ1RCBCbW5dY", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "1", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "7/23 McLaren F1 Collectible", group.primaryToken?.name ?? "-")
						
					case 12:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "579854610202626", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1BRADdqGk2eLmMqvyWzqVmPQ1RCBCbW5dY", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "1", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "6/23 McLaren F1 Collectible", group.primaryToken?.name ?? "-")
						
					case 13:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "566013445799938", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1JBNFcB5tiycHNdYGYCtR3kk6JaJysUCi8", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "0", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "Lugh Euro pegged stablecoin", group.primaryToken?.name ?? "-")
						
					case 14:
						XCTAssert(group.groupType == .receive, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "ooyKEQLPDHHD2K8ZJSt92braYAPcRjxxfEmXVcdAQ5X4AoRuREA", group.hash)
						XCTAssert(group.primaryToken?.tokenContractAddress == "KT1JFjwQ25n58NZr5Bwy9chAxHCaPsjvh5xt", group.primaryToken?.tokenContractAddress ?? "-")
						XCTAssert(group.primaryToken?.balance.normalisedRepresentation == "0.975223", group.primaryToken?.balance.normalisedRepresentation ?? "-")
						XCTAssert(group.primaryToken?.name == "WTZ", group.primaryToken?.name ?? "-")
						
					case 15:
						XCTAssert(group.groupType == .contractCall, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "ooyKEQLPDHHD2K8ZJSt92braYAPcRjxxfEmXVcdAQ5X4AoRuREA", group.hash)
						XCTAssert(group.entrypointCalled == "wrap", group.entrypointCalled ?? "-")
						
					case 16:
						XCTAssert(group.groupType == .delegate, group.groupType.rawValue)
						XCTAssert(group.transactions.count == 1, group.transactions.count.description)
						XCTAssert(group.hash == "onpirLfDfojh84pihNKmrNFZ14Uf8z2SHYBVikcaKfSRBFFFb25", group.hash)
						XCTAssert(group.transactions.first?.prevDelegate?.alias == " Baking Benjamins", group.transactions.first?.prevDelegate?.alias ?? "-")
						XCTAssert(group.transactions.first?.newDelegate?.alias == "ECAD Labs Baker", group.transactions.first?.newDelegate?.alias ?? "-")
						
					default:
						XCTFail("Missing test for transaction")
				}
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 10)
	}
	
	func testGetAllBalances() {
		let expectation = XCTestExpectation(description: "tzkt-testGetAllBalances")
		MockConstants.shared.tzktClient.getAllBalances(forAddress: MockConstants.defaultHdWallet.address) { result in
			
			switch result {
				case .success(let account):
					
					// Tokens
					XCTAssert(account.xtzBalance.normalisedRepresentation == "1.843617", account.xtzBalance.normalisedRepresentation)
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
					XCTAssert(account.nfts.count == 10, "\(account.nfts.count)")
					
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
					
					XCTAssert(account.nfts[3].tokenContractAddress == "KT1UmNSC5gjZeTcTeMEGpXqUZaJwUVRqvunM", account.nfts[3].tokenContractAddress ?? "-")
					XCTAssert(account.nfts[3].name == nil, account.nfts[3].name ?? "-")
					
					XCTAssert(account.nfts[4].name == "Tezos Domains NameRegistry", account.nfts[4].name ?? "")
					XCTAssert(account.nfts[4].nfts?[0].name == "blah.tez", account.nfts[4].nfts?[0].name ?? "")
					
					XCTAssert(account.nfts[8].name == "DOGAMÍ x GAP", account.nfts[8].name ?? "")
					XCTAssert(account.nfts[8].nfts?[0].name == "Bed Pillow #2435", account.nfts[8].nfts?[0].name ?? "")
					
					XCTAssert(account.nfts[9].tokenContractAddress == "KT1BA9igcUcgkMT4LEEQzwURsdMpQayfb6i4", account.nfts[9].name ?? "")
					XCTAssert(account.nfts[9].nfts?[0].name == "Bear Pawtrait", account.nfts[9].nfts?[0].name ?? "")
					
					// Liquidity tokens
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
