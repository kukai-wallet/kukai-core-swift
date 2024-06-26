//
//  MockConstants.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
@testable import KukaiCoreSwift
@testable import KukaiCryptoSwift

public struct MockConstants {
	
	static let shared = MockConstants()
	
	public let mockURLSession: URLSession
	
	// MARK: - Config / Services
	
	public var config: TezosNodeClientConfig
	public let loggingConfig: LoggingConfig
	public let networkService: NetworkService
	public let tezosNodeClient: TezosNodeClient
	public let betterCallDevClient: BetterCallDevClient
	public let tzktClient: TzKTClient
	public let tezosDomainsClient: TezosDomainsClient
	public let dipDupClient: DipDupClient
	public let objktClient: ObjktClient
	
	
	public static let http200 = HTTPURLResponse(url: URL(string: "http://google.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
	public static let http500 = HTTPURLResponse(url: URL(string: "http://google.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
	public static let ipfsResponseWithHeaders = HTTPURLResponse(url: URL(string: "ipfs://bafybeiatpitaej7bynhsequ5hl45jbtjft2nkkho74jfocvnw4vrqlhdea")!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "image/png"])
	
	// MARK: - Init
	
	private init() {
		config = TezosNodeClientConfig(withDefaultsForNetworkType: .ghostnet)
		loggingConfig = LoggingConfig(logNetworkFailures: true, logNetworkSuccesses: true)
		
		let sessionConfig = URLSessionConfiguration.ephemeral // Uses no caching / storage
		sessionConfig.protocolClasses = [MockURLProtocol.self]
		
		mockURLSession = URLSession(configuration: sessionConfig)
		
		// Setup URL mocks
		let baseURL = config.nodeURLs[0]
		let secondBaseURL = config.nodeURLs[1]
		let bcdURL = config.betterCallDevURL
		let tzktURL = config.tzktURL
		let bakingBadURL = URL(string: "https://api.baking-bad.org/")!
		
		var bcdTokenBalanceURL = bcdURL.appendingPathComponent("v1/account/ithacanet/tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss/token_balances")
		bcdTokenBalanceURL.appendQueryItem(name: "offset", value: 0)
		bcdTokenBalanceURL.appendQueryItem(name: "size", value: 50)
		bcdTokenBalanceURL.appendQueryItem(name: "hide_empty", value: "true")
		
		var tzktHistoryMainURL = tzktURL.appendingPathComponent("v1/accounts/tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss/operations")
		tzktHistoryMainURL.appendQueryItem(name: "type", value: "delegation,origination,transaction,staking")
		tzktHistoryMainURL.appendQueryItem(name: "micheline", value: "1")
		tzktHistoryMainURL.appendQueryItem(name: "limit", value: "50")
		
		var tzktHistoryNativeReceiveURL = tzktURL.appendingPathComponent("v1/tokens/transfers")
		tzktHistoryNativeReceiveURL.appendQueryItem(name: "anyof.from.to", value: "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss")
		tzktHistoryNativeReceiveURL.appendQueryItem(name: "limit", value: 50)
		tzktHistoryNativeReceiveURL.appendQueryItem(name: "offset", value: 0)
		tzktHistoryNativeReceiveURL.appendQueryItem(name: "sort.desc", value: "id")
		
		var tzktBigmapUserRewardsURL = tzktURL.appendingPathComponent("v1/bigmaps/1494/keys")
		tzktBigmapUserRewardsURL.appendQueryItem(name: "key", value: "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss")
		
		var tzktBigmapLedgerURL = tzktURL.appendingPathComponent("v1/bigmaps/1493/keys")
		tzktBigmapLedgerURL.appendQueryItem(name: "key", value: "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss")
		
		var tzktBalanceCountURL = tzktURL.appendingPathComponent("v1/tokens/balances/count")
		tzktBalanceCountURL.appendQueryItem(name: "account", value: "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss")
		tzktBalanceCountURL.appendQueryItem(name: "balance.gt", value: 0)
		
		var tzktBalancePageURL = tzktURL.appendingPathComponent("v1/tokens/balances")
		tzktBalancePageURL.appendQueryItem(name: "account", value: "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss")
		tzktBalancePageURL.appendQueryItem(name: "balance.gt", value: 0)
		tzktBalancePageURL.appendQueryItem(name: "offset", value: 0)
		tzktBalancePageURL.appendQueryItem(name: "limit", value: 10000)
		tzktBalancePageURL.appendQueryItem(name: "sort.desc", value: "lastLevel")
		
		var tzktCyclesURL = tzktURL.appendingPathComponent("v1/cycles")
		tzktCyclesURL.appendQueryItem(name: "limit", value: 25)
		
		var tzktDelegatorRewardsURL = tzktURL.appendingPathComponent("v1/rewards/delegators/tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss")
		tzktDelegatorRewardsURL.appendQueryItem(name: "limit", value: 25)
		
		var tzktDelegatorRewardsNoPreviousURL = tzktURL.appendingPathComponent("v1/rewards/delegators/tz1iv8r8UUCEZK5gqpLPnMPzP4VRJBJUdGgr")
		tzktDelegatorRewardsNoPreviousURL.appendQueryItem(name: "limit", value: 25)
		
		var bakingBadConfigURL1 = bakingBadURL.appendingPathComponent("v2/bakers/tz1fwnfJNgiDACshK9avfRfFbMaXrs3ghoJa")
		bakingBadConfigURL1.appendQueryItem(name: "configs", value: "true")
		
		var bakingBadConfigURL2 = bakingBadURL.appendingPathComponent("v2/bakers/tz1ZgkTFmiwddPXGbs4yc6NWdH4gELW7wsnv")
		bakingBadConfigURL2.appendQueryItem(name: "configs", value: "true")
		
		var bakingBadConfigURL3 = bakingBadURL.appendingPathComponent("v2/bakers/tz1S5WxdZR5f9NzsPXhr7L9L1vrEb5spZFur")
		bakingBadConfigURL3.appendQueryItem(name: "configs", value: "true")
		
		var bakingBadConfigURL4 = bakingBadURL.appendingPathComponent("v2/bakers/tz1aRoaRhSpRYvFdyvgWLL6TGyRoGF51wDjM")
		bakingBadConfigURL4.appendQueryItem(name: "configs", value: "true")
		
		var tzktsuggestURL1 = tzktURL.appendingPathComponent("v1/suggest/accounts/Bake Nug Payouts")
		tzktsuggestURL1.appendQueryItem(name: "limit", value: 1)
		
		var tzktsuggestURL2 = tzktURL.appendingPathComponent("v1/suggest/accounts/The Shire Payouts")
		tzktsuggestURL2.appendQueryItem(name: "limit", value: 1)
		
		var tzktsuggestURL3 = tzktURL.appendingPathComponent("v1/suggest/accounts/The Payouts")
		tzktsuggestURL3.appendQueryItem(name: "limit", value: 1)
		
		var tzktsuggestURL4 = tzktURL.appendingPathComponent("v1/suggest/accounts/Baking Benjamins Payouts")
		tzktsuggestURL4.appendQueryItem(name: "limit", value: 1)
		
		var tzktLastBakerRewardURL = tzktURL.appendingPathComponent("v1/accounts/tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss/operations")
		tzktLastBakerRewardURL.appendQueryItem(name: "limit", value: 1)
		tzktLastBakerRewardURL.appendQueryItem(name: "type", value: "transaction")
		tzktLastBakerRewardURL.appendQueryItem(name: "sender.in", value: "tz1ZgkTFmiwddPXGbs4yc6NWdH4gELW7wsnv,tz1S5WxdZR5f9NzsPXhr7L9L1vrEb5spZFur,tz1ShireJgwr8ag5dETMY4RNqkXeu1YgyDYC,tz1gnuBF9TbBcgHPV2mUE96tBrW7PxqRmx1h")
		
		var tzktLastBakerRewardURL2 = tzktURL.appendingPathComponent("v1/accounts/tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss/operations")
		tzktLastBakerRewardURL2.appendQueryItem(name: "limit", value: 1)
		tzktLastBakerRewardURL2.appendQueryItem(name: "type", value: "transaction")
		tzktLastBakerRewardURL2.appendQueryItem(name: "sender.in", value: "tz1ZgkTFmiwddPXGbs4yc6NWdH4gELW7wsnv,tz1S5WxdZR5f9NzsPXhr7L9L1vrEb5spZFur,tz1gnuBF9TbBcgHPV2mUE96tBrW7PxqRmx1h,tz1ShireJgwr8ag5dETMY4RNqkXeu1YgyDYC")
		
		var tzktLastBakerRewardURL3 = tzktURL.appendingPathComponent("v1/accounts/tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss/operations")
		tzktLastBakerRewardURL3.appendQueryItem(name: "limit", value: 1)
		tzktLastBakerRewardURL3.appendQueryItem(name: "type", value: "transaction")
		tzktLastBakerRewardURL3.appendQueryItem(name: "sender.in", value: "tz1ZgkTFmiwddPXGbs4yc6NWdH4gELW7wsnv,tz1S5WxdZR5f9NzsPXhr7L9L1vrEb5spZFur,tz1gnuBF9TbBcgHPV2mUE96tBrW7PxqRmx1h")
		
		var tzktLastBakerRewardURL4 = tzktURL.appendingPathComponent("v1/accounts/tz1iv8r8UUCEZK5gqpLPnMPzP4VRJBJUdGgr/operations")
		tzktLastBakerRewardURL4.appendQueryItem(name: "limit", value: 1)
		tzktLastBakerRewardURL4.appendQueryItem(name: "type", value: "transaction")
		tzktLastBakerRewardURL4.appendQueryItem(name: "sender.in", value: "tz1ZgkTFmiwddPXGbs4yc6NWdH4gELW7wsnv,tz1ShireJgwr8ag5dETMY4RNqkXeu1YgyDYC")
		
		var tzktDelegatesURL = tzktURL.appendingPathComponent("v1/delegates")
		tzktDelegatesURL.appendQueryItem(name: "select.values", value: "address,alias,balance,stakingBalance")
		tzktDelegatesURL.appendQueryItem(name: "active", value: "true")
		tzktDelegatesURL.appendQueryItem(name: "sort.desc", value: "stakingBalance")
		tzktDelegatesURL.appendQueryItem(name: "limit", value: 10)
		
		var simulateURL1 = baseURL.appendingPathComponent("chains/main/blocks/head/helpers/scripts/simulate_operation")
		simulateURL1.appendQueryItem(name: "version", value: "0")
		
		var simulateURL2 = secondBaseURL.appendingPathComponent("chains/main/blocks/head/helpers/scripts/simulate_operation")
		simulateURL2.appendQueryItem(name: "version", value: "0")
		
		
		// Format [ URL: ( Data?, HTTPURLResponse? ) ]
		MockURLProtocol.mockURLs = [
			
			// RPC URLs
			baseURL.appendingPathComponent("version"): (MockConstants.jsonStub(fromFilename: "version"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/constants"): (MockConstants.jsonStub(fromFilename: "constants"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss/manager_key"): (MockConstants.jsonStub(fromFilename: "manager_key"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss/counter"): (MockConstants.jsonStub(fromFilename: "counter"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head"): (MockConstants.jsonStub(fromFilename: "head"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head~3"): (MockConstants.jsonStub(fromFilename: "head"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/helpers/scripts/run_operation"): (MockConstants.jsonStub(fromFilename: "run_operation"), MockConstants.http200),
			secondBaseURL.appendingPathComponent("chains/main/blocks/head/helpers/scripts/run_operation"): (MockConstants.jsonStub(fromFilename: "run_operation"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/helpers/forge/operations"): (MockConstants.jsonStub(fromFilename: "forge"), MockConstants.http200),
			// Parse is handled inside MockURLProtocol due to its special requirements
			baseURL.appendingPathComponent("chains/main/blocks/head/helpers/preapply/operations"): (MockConstants.jsonStub(fromFilename: "preapply"), MockConstants.http200),
			secondBaseURL.appendingPathComponent("chains/main/blocks/head/helpers/preapply/operations"): (MockConstants.jsonStub(fromFilename: "preapply"), MockConstants.http200),
			baseURL.appendingPathComponent("injection/operation"): (MockConstants.jsonStub(fromFilename: "inject"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss/balance"): (MockConstants.jsonStub(fromFilename: "balance"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss/delegate"): (MockConstants.jsonStub(fromFilename: "delegate"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8/storage"): (MockConstants.jsonStub(fromFilename: "contract_storage"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5/storage"): (MockConstants.jsonStub(fromFilename: "token-pool"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5/balance"): (MockConstants.jsonStub(fromFilename: "xtz-pool"), MockConstants.http200),
			
			// BCD URLs
			bcdURL.appendingPathComponent("v1/opg/ooVTdEf3WVFgubEHRpJGPkwUfidsfNiTESY3D6i5PbaNNisZjZ8"): (MockConstants.jsonStub(fromFilename: "bcd_more-detailed-error"), MockConstants.http200),
			bcdURL.appendingPathComponent("v1/opg/oo5XsmdPjxvBAbCyL9kh3x5irUmkWNwUFfi2rfiKqJGKA6Sxjzf"): (MockConstants.jsonStub(fromFilename: "bcd_more-detailed-error"), MockConstants.http200),
			
			// TzKT URLs
			tzktURL.appendingPathComponent("v1/operations/ooT5uBirxWi9GXRqf6eGCEjoPhQid3U8yvsbP9JQHBXifVsinY8"): (MockConstants.jsonStub(fromFilename: "tzkt_operation"), MockConstants.http200),
			tzktURL.appendingPathComponent("v1/operations/oo5XsmdPjxvBAbCyL9kh3x5irUmkWNwUFfi2rfiKqJGKA6Sxjzf"): (MockConstants.jsonStub(fromFilename: "tzkt_operation-error"), MockConstants.http200),
			tzktHistoryMainURL: (MockConstants.jsonStub(fromFilename: "tzkt_transactions-main"), MockConstants.http200),
			tzktHistoryNativeReceiveURL: (MockConstants.jsonStub(fromFilename: "tzkt_transactions-transfers"), MockConstants.http200),
			tzktURL.appendingPathComponent("v1/contracts/KT1WBLrLE2vG8SedBqiSJFm4VVAZZBytJYHc/storage"): (MockConstants.jsonStub(fromFilename: "tzkt_storage_quipu"), MockConstants.http200),
			tzktBigmapUserRewardsURL: (MockConstants.jsonStub(fromFilename: "tzkt_bigmap_userrewards"), MockConstants.http200),
			tzktBigmapLedgerURL: (MockConstants.jsonStub(fromFilename: "tzkt_bigmap_ledger"), MockConstants.http200),
			tzktBalanceCountURL: (MockConstants.jsonStub(fromFilename: "tzkt_balance-count"), MockConstants.http200),
			tzktURL.appendingPathComponent("v1/accounts/tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss"): (MockConstants.jsonStub(fromFilename: "tzkt_account"), MockConstants.http200),
			tzktBalancePageURL: (MockConstants.jsonStub(fromFilename: "tzkt_balance-page"), MockConstants.http200),
			tzktCyclesURL: (MockConstants.jsonStub(fromFilename: "tzkt_cycles"), MockConstants.http200),
			tzktDelegatorRewardsURL: (MockConstants.jsonStub(fromFilename: "tzkt_delegator-rewards"), MockConstants.http200),
			tzktDelegatorRewardsNoPreviousURL: (MockConstants.jsonStub(fromFilename: "tzkt_delegator-rewards-no-previous"), MockConstants.http200),
			bakingBadConfigURL1: (MockConstants.jsonStub(fromFilename: "tzkt_baker-config-tz1fwnfJNgiDACshK9avfRfFbMaXrs3ghoJa"), MockConstants.http200),
			bakingBadConfigURL2: (MockConstants.jsonStub(fromFilename: "tzkt_baker-config-tz1ZgkTFmiwddPXGbs4yc6NWdH4gELW7wsnv"), MockConstants.http200),
			bakingBadConfigURL3: (MockConstants.jsonStub(fromFilename: "tzkt_baker-config-tz1S5WxdZR5f9NzsPXhr7L9L1vrEb5spZFur"), MockConstants.http200),
			bakingBadConfigURL4: (MockConstants.jsonStub(fromFilename: "tzkt_baker-config-tz1aRoaRhSpRYvFdyvgWLL6TGyRoGF51wDjM"), MockConstants.http200),
			tzktsuggestURL1: (MockConstants.jsonStub(fromFilename: "tzkt_suggest-bake-nug"), MockConstants.http200),
			tzktsuggestURL2: (MockConstants.jsonStub(fromFilename: "tzkt_suggest-the-shire"), MockConstants.http200),
			tzktsuggestURL3: (MockConstants.jsonStub(fromFilename: "tzkt_suggest-the-shire_updated"), MockConstants.http200),
			tzktsuggestURL4: (MockConstants.jsonStub(fromFilename: "tzkt_suggest-baking-benjamins"), MockConstants.http200),
			tzktLastBakerRewardURL: (MockConstants.jsonStub(fromFilename: "tzkt_last-baker-payment"), MockConstants.http200),
			tzktLastBakerRewardURL2: (MockConstants.jsonStub(fromFilename: "tzkt_last-baker-payment"), MockConstants.http200),
			tzktLastBakerRewardURL3: (MockConstants.jsonStub(fromFilename: "tzkt_last-baker-payment_updated"), MockConstants.http200),
			tzktLastBakerRewardURL4: (MockConstants.jsonStub(fromFilename: "tzkt_last-baker-payment_updated"), MockConstants.http200),
			tzktDelegatesURL: (MockConstants.jsonStub(fromFilename: "tzkt_ghostnet-bakers"), MockConstants.http200),
			
			// Media proxy
			URL(string: "ipfs://bafybeiatpitaej7bynhsequ5hl45jbtjft2nkkho74jfocvnw4vrqlhdea")!: (nil, MockConstants.ipfsResponseWithHeaders),
			
			// Misc
			URL(string: "https://api.tezos.help/twitter-lookup/")!: (MockConstants.jsonStub(fromFilename: "twitter_lookup"), MockConstants.http200),
		]
		
		MockURLProtocol.mockPostURLs = [
			
			// Tezos domains
			MockPostUrlKey(url: URL(string: "https://ghostnet-api.tezos.domains/graphql")!, requestData: MockConstants.jsonStub(fromFilename: "tezos_domains-domain_request")):
				(MockConstants.jsonStub(fromFilename: "tezos_domains-domain"), MockConstants.http200),
			MockPostUrlKey(url: URL(string: "https://ghostnet-api.tezos.domains/graphql")!, requestData: MockConstants.jsonStub(fromFilename: "tezos_domains-reverseRecord_request")):
				(MockConstants.jsonStub(fromFilename: "tezos_domains-reverseRecord"), MockConstants.http200),
			MockPostUrlKey(url: URL(string: "https://ghostnet-api.tezos.domains/graphql")!, requestData: MockConstants.jsonStub(fromFilename: "tezos_domains-bulk-domain_request")):
				(MockConstants.jsonStub(fromFilename: "tezos_domains-bulk-domain"), MockConstants.http200),
			MockPostUrlKey(url: URL(string: "https://ghostnet-api.tezos.domains/graphql")!, requestData: MockConstants.jsonStub(fromFilename: "tezos_domains-bulk-reverseRecord_request")):
				(MockConstants.jsonStub(fromFilename: "tezos_domains-bulk-reverseRecord"), MockConstants.http200),
			
			MockPostUrlKey(url: URL(string: "https://api.tezos.domains/graphql")!, requestData: MockConstants.jsonStub(fromFilename: "tezos_domains-reverseRecord_request_mainnet")):
				(MockConstants.jsonStub(fromFilename: "tezos_domains-reverseRecord_mainnet"), MockConstants.http200),
			MockPostUrlKey(url: URL(string: "https://api.tezos.domains/graphql")!, requestData: MockConstants.jsonStub(fromFilename: "tezos_domains-bulk-reverseRecord_request_mainnet")):
				(MockConstants.jsonStub(fromFilename: "tezos_domains-bulk-reverseRecord_mainnet"), MockConstants.http200),
			
			// DipDup
			MockPostUrlKey(url: URL(string: "https://dex.dipdup.net/v1/graphql")!, requestData: MockConstants.jsonStub(fromFilename: "dipdup_dex_exchange_request_1")):
				(MockConstants.jsonStub(fromFilename: "dipdup_dex_exchange_response_1"), MockConstants.http200),
			MockPostUrlKey(url: URL(string: "https://dex.dipdup.net/v1/graphql")!, requestData: MockConstants.jsonStub(fromFilename: "dipdup_dex_exchange_request_2")):
				(MockConstants.jsonStub(fromFilename: "dipdup_dex_exchange_response_2"), MockConstants.http200),
			MockPostUrlKey(url: URL(string: "https://dex.dipdup.net/v1/graphql")!, requestData: MockConstants.jsonStub(fromFilename: "dipdup_dex_exchange_request_3")):
				(MockConstants.jsonStub(fromFilename: "dipdup_dex_exchange_response_3"), MockConstants.http200),
			MockPostUrlKey(url: URL(string: "https://dex.dipdup.net/v1/graphql")!, requestData: MockConstants.jsonStub(fromFilename: "dipdup_dex_exchange_request_4")):
				(MockConstants.jsonStub(fromFilename: "dipdup_dex_exchange_response_4"), MockConstants.http200),
			MockPostUrlKey(url: URL(string: "https://dex.dipdup.net/v1/graphql")!, requestData: MockConstants.jsonStub(fromFilename: "dipdup_dex_liquidity_request")):
				(MockConstants.jsonStub(fromFilename: "dipdup_dex_liquidity_response"), MockConstants.http200),
			MockPostUrlKey(url: URL(string: "https://dex.dipdup.net/v1/graphql")!, requestData: MockConstants.jsonStub(fromFilename: "dipdup_dex_chart_request")):
				(MockConstants.jsonStub(fromFilename: "dipdup_dex_chart_response"), MockConstants.http200),
			
			
			// OBJKT
			MockPostUrlKey(url: URL(string: "https://data.objkt.com/v3/graphql")!, requestData: MockConstants.jsonStub(fromFilename: "objkt_collections_request_1")):
				(MockConstants.jsonStub(fromFilename: "objkt_collections_response_1"), MockConstants.http200),
			MockPostUrlKey(url: URL(string: "https://data.objkt.com/v3/graphql")!, requestData: MockConstants.jsonStub(fromFilename: "objkt_collections_request_2")):
				(MockConstants.jsonStub(fromFilename: "objkt_collections_response_2"), MockConstants.http200),
			MockPostUrlKey(url: URL(string: "https://data.objkt.com/v3/graphql")!, requestData: MockConstants.jsonStub(fromFilename: "objkt_token_request")):
				(MockConstants.jsonStub(fromFilename: "objkt_token_response"), MockConstants.http200),
			
			
			// simulate_operation
			MockPostUrlKey(url: simulateURL1, requestData: MockConstants.jsonStub(fromFilename: "simulate_operation-request1")):
				(MockConstants.jsonStub(fromFilename: "simulate_operation-response1"), MockConstants.http200),
			MockPostUrlKey(url: simulateURL1, requestData: MockConstants.jsonStub(fromFilename: "simulate_operation-request3")):
				(MockConstants.jsonStub(fromFilename: "simulate_operation-response1"), MockConstants.http200),
			MockPostUrlKey(url: simulateURL2, requestData: MockConstants.jsonStub(fromFilename: "simulate_operation-request2")):
				(MockConstants.jsonStub(fromFilename: "simulate_operation-response1"), MockConstants.http200),
			
			MockPostUrlKey(url: simulateURL1, requestData: MockConstants.jsonStub(fromFilename: "simulate_operation-crunchy-stake-request")):
				(MockConstants.jsonStub(fromFilename: "simulate_operation-crunchy-stake-response"), MockConstants.http200),
			MockPostUrlKey(url: simulateURL1, requestData: MockConstants.jsonStub(fromFilename: "simulate_operation-crunchy-swap-request")):
				(MockConstants.jsonStub(fromFilename: "simulate_operation-crunchy-swap-response"), MockConstants.http200),
			MockPostUrlKey(url: simulateURL1, requestData: MockConstants.jsonStub(fromFilename: "simulate_operation-high-gas-low-storage-request")):
				(MockConstants.jsonStub(fromFilename: "simulate_operation-high-gas-low-storage-response"), MockConstants.http200),
			MockPostUrlKey(url: simulateURL1, requestData: MockConstants.jsonStub(fromFilename: "simulate_operation-stake-request")):
				(MockConstants.jsonStub(fromFilename: "simulate_operation-stake-response"), MockConstants.http200),
			MockPostUrlKey(url: simulateURL1, requestData: MockConstants.jsonStub(fromFilename: "simulate_operation-unstake-request")):
				(MockConstants.jsonStub(fromFilename: "simulate_operation-unstake-response"), MockConstants.http200),
		]
		
		config.urlSession = mockURLSession
		networkService = NetworkService(urlSession: mockURLSession, loggingConfig: loggingConfig)
		tezosNodeClient = TezosNodeClient(config: config)
		tezosNodeClient.networkService = networkService
		
		let opService = OperationService(config: config, networkService: networkService)
		tezosNodeClient.operationService = opService
		dipDupClient = DipDupClient(networkService: networkService, config: config)
		objktClient = ObjktClient(networkService: networkService, config: config)
		tezosNodeClient.feeEstimatorService = FeeEstimatorService(config: config, operationService: opService, networkService: networkService)
		betterCallDevClient = BetterCallDevClient(networkService: networkService, config: config)
		tzktClient = TzKTClient(networkService: networkService, config: config, betterCallDevClient: betterCallDevClient, dipDupClient: dipDupClient)
		tezosDomainsClient = TezosDomainsClient(networkService: networkService, config: config)
	}
	
	public static func bcdURL(withPath: String, queryParams: [String: String], andConfig config: TezosNodeClientConfig) -> URL {
		var bcdURL = config.betterCallDevURL.appendingPathComponent(withPath)
		
		for key in queryParams.keys {
			bcdURL.appendQueryItem(name: key, value: queryParams[key] ?? "")
		}
		
		return bcdURL
	}
	
	public static func bcdTokenMetadataURL(config: TezosNodeClientConfig, contract: String) -> URL {
		return MockConstants.bcdURL(withPath: "v1/tokens/ithacanet/metadata", queryParams: ["contract": contract], andConfig: config)
	}
	
	
	
	// MARK: - Wallets
	
	public static let mnemonic = try! Mnemonic(seedPhrase: "rigid obscure hurry scene eyebrow decide empty annual hunt cute also base")
	public static let shiftedMnemonic = try! Mnemonic(seedPhrase: "laugh come news visit ceiling network rich outdoor license enjoy govern drastic slight close panic kingdom wash bring electric convince fiber relief cash siren")
	public static let passphrase = "superSecurePassphrase"
	public static let messageToSign = "something very interesting that needs to be signed"
	
	public static let defaultLinearWallet = RegularWallet(withMnemonic: MockConstants.mnemonic, passphrase: "")!
	public static let defaultHdWallet = HDWallet(withMnemonic: MockConstants.mnemonic, passphrase: "")!
	
	public struct linearWalletEd255519 {
		public static let address = "tz1iQpiBTKtzfbVgogjyhPiGrrV5zAKUKNvy"
		public static let privateKey = "b315e66c1360d9999a353215b5cdca9f892f9a11c2bd5dd46138067131a003312af2e1ea250f665e7b305c46c59c937d7673f40ab875f7242a8332637218579d"
		public static let publicKey = "2af2e1ea250f665e7b305c46c59c937d7673f40ab875f7242a8332637218579d"
		public static let signedData = "fd1d48f19e12bbb40f864e99cc6dae0fca04e6b4b6e1834f782757cc1bbdf6584d9c50e5cb3040fe8120b5dabb0d945c1134dd8fc9ec88ce89243a6f57ad8f05"
		public static let base58Encoded = "edpkty91G7uZdFadCFbJAZs8HUxa9bdG2NgvQrM8icwNUuKLpdknBS"
	}
	
	public struct linearWalletEd255519_withPassphrase {
		public static let address = "tz1NzhMaJnLwcQqLL4C76aytKxyoKxVuYUs4"
		public static let privateKey = "08334529c4930a4da20f38a332ff6c5c6a325ac616f707d40518494842ec4fd751807c1c38156f8a6c6ac8f346e9d76ff40516a2ca5801e53d3eb330699c6ef0"
		public static let publicKey = "51807c1c38156f8a6c6ac8f346e9d76ff40516a2ca5801e53d3eb330699c6ef0"
	}
	
	public struct linearWalletSecp256k1 {
		public static let address = "tz2JhgBr76hVaN4Rxh1r15VouJiGpjfYGpBx"
		public static let privateKey = "b315e66c1360d9999a353215b5cdca9f892f9a11c2bd5dd46138067131a00331"
		public static let publicKey = "038bc818461503be12f80d4a706aff0f5169516d16a590d3648ab3a4b4c66adb6e"
	}
	
	public struct hdWallet {
		public static let address = "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss"
		public static let privateKey = "219ce080def8ba07e7896cb5fe9271b5ea2b6d0ce4079f2f82abc7ea4da403a07a1d691da0b814dba3b829563dc8d0d8bed0a3d8643187b3a6bff75caf8df6ac"
		public static let publicKey = "7a1d691da0b814dba3b829563dc8d0d8bed0a3d8643187b3a6bff75caf8df6ac"
		public static let signedData = "fe0314c41dc32529ca4b32c178ef2c07874eaec16390dba09f151342e7607452626f7709abbe7521852aff8fe23e5fd9da3689be80aefb98cc72b30da9a7c902"
		public static let base58Encoded = "edpkua1CRS7JZ9wr5yZQg6Lxs2oFMM5KwkN77g3n2BaWK8z4rPzb1s"
		
		public static let childWalletAddresses = ["tz1PU77dNjHxFPH1LoEM78AqrbCUThJWw2tW", "tz1Tp2RKCL53SU7CeKMPGpsHE4Mu4dgNRekU", "tz1UDqxfQSJwnkogXotJkYmxFxbM2Xdi44C6"]
	}
	
	public struct hdWallet_withPassphrase {
		public static let address = "tz1ZTLPBs6c7KVmRatGetf5Ds1zTaUrEXtT7"
		public static let privateKey = "5fd3f06aea310f9ac6b4b0390e8488b1c6a8dd48deb3e920a0767af3cb56dacfa0a5fc6c4efd214999ff5cce7a612335b3938e013901bebb74525034ed12822c"
		public static let publicKey = "a0a5fc6c4efd214999ff5cce7a612335b3938e013901bebb74525034ed12822c"
	}
	
	public struct hdWallet_non_hardened {
		public static let address = "tz1gr7B9AsXJMMSBg7NugNvDZpGgvcvX4Q8M"
		public static let privateKey = "2cd4e64b16e9bb9fa7c19aa272bd2dba0d9ae3ee3f764e15351ab7ec11fc37ad"
		public static let publicKey = "caa6f27ebb93808caf3ee7ecbff0fc482bbde9e123293bf34d78dbca105e02c2"
		public static let derivationPath = "m/44'/1729'/0/0"
	}
	
	public struct hdWallet_hardened_change {
		public static let address = "tz1gHeMu3xoSLPArGwa4FtrFwATK3ncdz9Gx"
		public static let privateKey = "efa21dab1ddaf1a6f78cbe7e131bd10209ece4ae0642ac78f9532dbe216a0d39bc1287467d20ea180ee01734ada519322bcb8e60b08c923547e67d8f7a5bc14c"
		public static let publicKey = "bc1287467d20ea180ee01734ada519322bcb8e60b08c923547e67d8f7a5bc14c"
		public static let derivationPath = "m/44'/1729'/0'/1'"
	}
	
	public struct shiftedWallet {
		public static let address = "tz2HpbGQcmU3UyusJ78Sbqeg9fYteamSMDGo"
		public static let privateKey = "7d85c254fa624f29ae54e981295594212cba5767ebd5f763851d97c55b6a88d6"
		public static let publicKey = "025b4cb98848c2288eda85a8083d07d595721e89d3694bd3fb2a4c497ceeac66ca"
	}
	
	
	
	// MARK: - Types
	
	public struct TestCodable: Codable {
		let text: String
		let number: Int
		let date: Date
	}
	
	public static let testCodableFilename = "codableTest.txt"
	public static let testCodableTimestmap: Double = 1623838776
	public static let testCodableInstance = TestCodable(text: "Testing Codable", number: 42, date: Date(timeIntervalSince1970: MockConstants.testCodableTimestmap))
	public static let testCodableString = "something useful for codable"
	public static let testCodableData = MockConstants.testCodableString.data(using: .utf8) ?? Data()
	
	
	
	// MARK: - Tokens
	
	public static let tokenXTZ = Token.xtz()
	public static let token3Decimals = Token(name: "Token 3 decimals", symbol: "TK3", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: "KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8", tokenId: nil, nfts: nil, mintingTool: nil)
	public static let token10Decimals = Token(name: "Token 10 decimals", symbol: "TK10", tokenType: .fungible, faVersion: .fa2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: "KT1G1cCRNBgQ48mVDjopHjEmTN5Sbtar8nn9", tokenId: 0, nfts: nil, mintingTool: nil)
	public static let nftMetadata = TzKTBalanceMetadata(name: "NFT Name", symbol: "NFT", decimals: "0", formats: nil, displayUri: MediaProxySerivceTests.ipfsURIWithoutExtension, artifactUri: nil, thumbnailUri: MediaProxySerivceTests.ipfsURIWithExtension, description: "A sample description", mintingTool: nil, tags: nil, minter: nil, shouldPreferSymbol: nil, attributes: nil, ttl: nil)
	public static let tokenWithNFTs = Token(name: "Token with NFTS", symbol: "T-NFT", tokenType: .nonfungible, faVersion: .fa2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: "KT1G1cCRNBgQ48mVDjopHjEmTN5Sbtabc123", tokenId: 0, nfts: [
		NFT(fromTzKTBalance: TzKTBalance(balance: "1", token: TzKTBalanceToken(contract: TzKTAddress(alias: nil, address: "KT1G1cCRNBgQ48mVDjopHjEmTN5Sbtabc123"), tokenId: "4", standard: .fa2, totalSupply: "1", metadata: MockConstants.nftMetadata)))
	], mintingTool: nil)
	
	
	public static let xtz_1 = XTZAmount(fromNormalisedAmount: 1)
	public static let token3Decimals_1 = TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 3)
	public static let token10Decimals_1 = TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 10)
	
	
	
	// MARK: - Operations
	
	public static let blockchainHead = BlockchainHead(protocol: "PsFLorenaUUuikDWvMDr6fGBRG8kt3e3D3fHoXK1j1BFRxeSH4i", chainID: "NetXxkAx4woPLyu", hash: "BLEDGNuADAwZfKK7iZ6PHnu7gZFSXuRPVFXe2PhSnb6aMyKn3mK")
	public static let blockchainHeadMinus3 = BlockchainHead(protocol: "PsFLorenaUUuikDWvMDr6fGBRG8kt3e3D3fHoXK1j1BFRxeSH4i", chainID: "NetXxkAx4woPLyu", hash: "BLEDGNuADAwZfKK7iZ6PHnu7gZFSXuRPVFXe2PhSnb6aMyKn3mKMinus3")
	public static let operationMetadata = OperationMetadata(managerKey: "edpktsYtWnwnuiLkHySdNSihWEChdeFzyz9v8Vdb8aAWRibsPH7g7E", counter: 143230, blockchainHead: MockConstants.blockchainHead)
	public static let operationMetadataNoManager = OperationMetadata(managerKey: nil, counter: 143230, blockchainHead: MockConstants.blockchainHead)
	public static let networkConstants = NetworkConstants(minimal_block_delay: "30", hard_gas_limit_per_operation: "10400000", hard_gas_limit_per_block: "10400000", origination_size: 257, cost_per_byte: "250", hard_storage_limit_per_operation: "60000")
	public static var sendOperations = OperationFactory.sendOperation(MockConstants.xtz_1, of: MockConstants.tokenXTZ, from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
	public static var sendOperationWithReveal = [OperationReveal(wallet: MockConstants.defaultHdWallet), OperationTransaction(amount: MockConstants.xtz_1, source: MockConstants.defaultHdWallet.address, destination: MockConstants.defaultLinearWallet.address)]
	public static let sendOperationPayload = OperationFactory.operationPayload(fromMetadata: MockConstants.operationMetadata, andOperations: MockConstants.sendOperations, walletAddress: MockConstants.defaultHdWallet.address, base58EncodedPublicKey: MockConstants.defaultHdWallet.publicKeyBase58encoded())
	public static let sendOperationWithRevealPayload = OperationFactory.operationPayload(fromMetadata: MockConstants.operationMetadata, andOperations: MockConstants.sendOperationWithReveal, walletAddress: MockConstants.defaultHdWallet.address, base58EncodedPublicKey: MockConstants.defaultHdWallet.publicKeyBase58encoded())
	public static let sendOperationForged = "43f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6c00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d00bdac1a80bd3fe0d403e80700005134b25890279835eb946e6369a3d719bc0d617700"
	public static let operationHashToSearch = "ooVTdEf3WVFgubEHRpJGPkwUfidsfNiTESY3D6i5PbaNNisZjZ8"
	
	
	
	
	// MARK: - Functions
	
	static func resetOperations() {
		sendOperations = OperationFactory.sendOperation(MockConstants.xtz_1, of: MockConstants.tokenXTZ, from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
		sendOperationWithReveal = [OperationReveal(wallet: MockConstants.defaultHdWallet), OperationTransaction(amount: MockConstants.xtz_1, source: MockConstants.defaultHdWallet.address, destination: MockConstants.defaultLinearWallet.address)]
	}
	
	static func jsonStub(fromFilename filename: String, ofExtension fileExtension: String = "json", replacing: [String: String] = [:], replacingWithRandom: [String] = []) -> Data {
		guard let path = Bundle.module.url(forResource: filename, withExtension: fileExtension, subdirectory: "Stubs"),
			let stubData = try? Data(contentsOf: path) else {
				fatalError("Can't find or read `\(filename).\(fileExtension)`")
		}
		
		var updatedData = stubData
		if replacing.keys.count > 0 {
			guard let dataString = String(data: stubData, encoding: .utf8) else {
				fatalError("Can't find or read `\(filename).\(fileExtension)`")
			}
			
			var updatedString = dataString
			replacing.keys.forEach { (key) in
				updatedString = updatedString.replacingOccurrences(of: key, with: replacing[key] ?? "")
			}
			
			updatedData = updatedString.data(using: .utf8) ?? Data()
		}
		
		if replacingWithRandom.count > 0 {
			guard let dataString = String(data: updatedData, encoding: .utf8) else {
				fatalError("Can't find or read `\(filename).\(fileExtension)`")
			}
			
			var updatedString = dataString
			replacingWithRandom.forEach { (key) in
				let random = Int.random(in: 0..<10000)
				updatedString = updatedString.replacingOccurrences(of: key, with: "\(random))")
			}
			
			updatedData = updatedString.data(using: .utf8) ?? Data()
		}
		
		return updatedData
	}
}
