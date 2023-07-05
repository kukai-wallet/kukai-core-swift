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
		config = TezosNodeClientConfig(withDefaultsForNetworkType: .testnet)
		loggingConfig = LoggingConfig(logNetworkFailures: true, logNetworkSuccesses: true)
		
		let sessionConfig = URLSessionConfiguration.ephemeral // Uses no caching / storage
		sessionConfig.protocolClasses = [MockURLProtocol.self]
		
		mockURLSession = URLSession(configuration: sessionConfig)
		
		// Setup URL mocks
		let baseURL = config.primaryNodeURL
		let bcdURL = config.betterCallDevURL
		let tzktURL = config.tzktURL
		let bakingBadURL = URL(string: "https://api.baking-bad.org/")!
		
		var bcdTokenBalanceURL = bcdURL.appendingPathComponent("v1/account/ithacanet/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/token_balances")
		bcdTokenBalanceURL.appendQueryItem(name: "offset", value: 0)
		bcdTokenBalanceURL.appendQueryItem(name: "size", value: 50)
		bcdTokenBalanceURL.appendQueryItem(name: "hide_empty", value: "true")
		
		var tzktHistoryMainURL = tzktURL.appendingPathComponent("v1/accounts/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/operations")
		tzktHistoryMainURL.appendQueryItem(name: "type", value: "delegation,origination,transaction")
		tzktHistoryMainURL.appendQueryItem(name: "micheline", value: "1")
		tzktHistoryMainURL.appendQueryItem(name: "limit", value: "50")
		
		var tzktHistoryNativeReceiveURL = tzktURL.appendingPathComponent("v1/tokens/transfers")
		tzktHistoryNativeReceiveURL.appendQueryItem(name: "anyof.from.to", value: "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF")
		tzktHistoryNativeReceiveURL.appendQueryItem(name: "limit", value: 50)
		tzktHistoryNativeReceiveURL.appendQueryItem(name: "offset", value: 0)
		tzktHistoryNativeReceiveURL.appendQueryItem(name: "sort.desc", value: "id")
		
		var tzktBigmapUserRewardsURL = tzktURL.appendingPathComponent("v1/bigmaps/1494/keys")
		tzktBigmapUserRewardsURL.appendQueryItem(name: "key", value: "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF")
		
		var tzktBigmapLedgerURL = tzktURL.appendingPathComponent("v1/bigmaps/1493/keys")
		tzktBigmapLedgerURL.appendQueryItem(name: "key", value: "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF")
		
		var tzktBalanceCountURL = tzktURL.appendingPathComponent("v1/tokens/balances/count")
		tzktBalanceCountURL.appendQueryItem(name: "account", value: "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF")
		tzktBalanceCountURL.appendQueryItem(name: "balance.gt", value: 0)
		
		var tzktBalancePageURL = tzktURL.appendingPathComponent("v1/tokens/balances")
		tzktBalancePageURL.appendQueryItem(name: "account", value: "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF")
		tzktBalancePageURL.appendQueryItem(name: "balance.gt", value: 0)
		tzktBalancePageURL.appendQueryItem(name: "offset", value: 0)
		tzktBalancePageURL.appendQueryItem(name: "limit", value: 10000)
		tzktBalancePageURL.appendQueryItem(name: "sort.desc", value: "lastLevel")
		
		var tzktCyclesURL = tzktURL.appendingPathComponent("v1/cycles")
		tzktCyclesURL.appendQueryItem(name: "limit", value: 25)
		
		var tzktDelegatorRewardsURL = tzktURL.appendingPathComponent("v1/rewards/delegators/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF")
		tzktDelegatorRewardsURL.appendQueryItem(name: "limit", value: 25)
		
		var bakingBadConfigURL1 = bakingBadURL.appendingPathComponent("v2/bakers/tz1fwnfJNgiDACshK9avfRfFbMaXrs3ghoJa")
		bakingBadConfigURL1.appendQueryItem(name: "configs", value: "true")
		
		var bakingBadConfigURL2 = bakingBadURL.appendingPathComponent("v2/bakers/tz1ZgkTFmiwddPXGbs4yc6NWdH4gELW7wsnv")
		bakingBadConfigURL2.appendQueryItem(name: "configs", value: "true")
		
		var tzktsuggestURL1 = tzktURL.appendingPathComponent("v1/suggest/accounts/Bake Nug Payouts")
		tzktsuggestURL1.appendQueryItem(name: "limit", value: 1)
		
		var tzktsuggestURL2 = tzktURL.appendingPathComponent("v1/suggest/accounts/The Shire Payouts")
		tzktsuggestURL2.appendQueryItem(name: "limit", value: 1)
		
		var tzktsuggestURL3 = tzktURL.appendingPathComponent("v1/suggest/accounts/The Payouts")
		tzktsuggestURL3.appendQueryItem(name: "limit", value: 1)
		
		var tzktLastBakerRewardURL = tzktURL.appendingPathComponent("v1/accounts/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/operations")
		tzktLastBakerRewardURL.appendQueryItem(name: "limit", value: 1)
		tzktLastBakerRewardURL.appendQueryItem(name: "type", value: "transaction")
		tzktLastBakerRewardURL.appendQueryItem(name: "sender.in", value: "tz1ZgkTFmiwddPXGbs4yc6NWdH4gELW7wsnv,tz1fwnfJNgiDACshK9avfRfFbMaXrs3ghoJa,tz1XWEi47p85eUwRZk2Xsp9VobSwUFq7GYKi,tz1ShireJgwr8ag5dETMY4RNqkXeu1YgyDYC")
		
		var tzktLastBakerRewardURL2 = tzktURL.appendingPathComponent("v1/accounts/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/operations")
		tzktLastBakerRewardURL2.appendQueryItem(name: "limit", value: 1)
		tzktLastBakerRewardURL2.appendQueryItem(name: "type", value: "transaction")
		tzktLastBakerRewardURL2.appendQueryItem(name: "sender.in", value: "tz1ZgkTFmiwddPXGbs4yc6NWdH4gELW7wsnv,tz1fwnfJNgiDACshK9avfRfFbMaXrs3ghoJa,tz1ShireJgwr8ag5dETMY4RNqkXeu1YgyDYC,tz1XWEi47p85eUwRZk2Xsp9VobSwUFq7GYKi")
		
		var tzktLastBakerRewardURL3 = tzktURL.appendingPathComponent("v1/accounts/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/operations")
		tzktLastBakerRewardURL3.appendQueryItem(name: "limit", value: 1)
		tzktLastBakerRewardURL3.appendQueryItem(name: "type", value: "transaction")
		tzktLastBakerRewardURL3.appendQueryItem(name: "sender.in", value: "tz1ZgkTFmiwddPXGbs4yc6NWdH4gELW7wsnv,tz1fwnfJNgiDACshK9avfRfFbMaXrs3ghoJa,tz1XWEi47p85eUwRZk2Xsp9VobSwUFq7GYKi")
		
		
		// Format [ URL: ( Data?, HTTPURLResponse? ) ]
		MockURLProtocol.mockURLs = [
			
			// RPC URLs
			baseURL.appendingPathComponent("version"): (MockConstants.jsonStub(fromFilename: "version"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/constants"): (MockConstants.jsonStub(fromFilename: "constants"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/manager_key"): (MockConstants.jsonStub(fromFilename: "manager_key"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/counter"): (MockConstants.jsonStub(fromFilename: "counter"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head"): (MockConstants.jsonStub(fromFilename: "head"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head~3"): (MockConstants.jsonStub(fromFilename: "head"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/helpers/scripts/run_operation"): (MockConstants.jsonStub(fromFilename: "run_operation"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/helpers/forge/operations"): (MockConstants.jsonStub(fromFilename: "forge"), MockConstants.http200),
			// Parse is handled inside MockURLProtocol due to its special requirements
			baseURL.appendingPathComponent("chains/main/blocks/head/helpers/preapply/operations"): (MockConstants.jsonStub(fromFilename: "preapply"), MockConstants.http200),
			baseURL.appendingPathComponent("injection/operation"): (MockConstants.jsonStub(fromFilename: "inject"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/balance"): (MockConstants.jsonStub(fromFilename: "balance"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/delegate"): (MockConstants.jsonStub(fromFilename: "delegate"), MockConstants.http200),
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
			tzktURL.appendingPathComponent("v1/accounts/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF"): (MockConstants.jsonStub(fromFilename: "tzkt_account"), MockConstants.http200),
			tzktBalancePageURL: (MockConstants.jsonStub(fromFilename: "tzkt_balance-page"), MockConstants.http200),
			tzktCyclesURL: (MockConstants.jsonStub(fromFilename: "tzkt_cycles"), MockConstants.http200),
			tzktDelegatorRewardsURL: (MockConstants.jsonStub(fromFilename: "tzkt_delegator-rewards"), MockConstants.http200),
			bakingBadConfigURL1: (MockConstants.jsonStub(fromFilename: "tzkt_baker-config-tz1fwnfJNgiDACshK9avfRfFbMaXrs3ghoJa"), MockConstants.http200),
			bakingBadConfigURL2: (MockConstants.jsonStub(fromFilename: "tzkt_baker-config-tz1ZgkTFmiwddPXGbs4yc6NWdH4gELW7wsnv"), MockConstants.http200),
			tzktsuggestURL1: (MockConstants.jsonStub(fromFilename: "tzkt_suggest-bake-nug"), MockConstants.http200),
			tzktsuggestURL2: (MockConstants.jsonStub(fromFilename: "tzkt_suggest-the-shire"), MockConstants.http200),
			tzktsuggestURL3: (MockConstants.jsonStub(fromFilename: "tzkt_suggest-the-shire_updated"), MockConstants.http200),
			tzktLastBakerRewardURL: (MockConstants.jsonStub(fromFilename: "tzkt_last-baker-payment"), MockConstants.http200),
			tzktLastBakerRewardURL2: (MockConstants.jsonStub(fromFilename: "tzkt_last-baker-payment"), MockConstants.http200),
			tzktLastBakerRewardURL3: (MockConstants.jsonStub(fromFilename: "tzkt_last-baker-payment_updated"), MockConstants.http200),
			
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
	
	public static let mnemonic = try! Mnemonic(seedPhrase: "remember smile trip tumble era cube worry fuel bracket eight kitten inform")
	public static let passphrase = "superSecurePassphrase"
	public static let messageToSign = "something very interesting that needs to be signed"
	
	public static let defaultLinearWallet = RegularWallet(withMnemonic: MockConstants.mnemonic, passphrase: "")!
	public static let defaultHdWallet = HDWallet(withMnemonic: MockConstants.mnemonic, passphrase: "")!
	
	public struct linearWalletEd255519 {
		public static let address = "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG"
		public static let privateKey = "80d4e52897c8e14fbfad4637373de405fa2cc7f27eb9f890db975948b0e7fdb0cd33a22f74d8e04977f74db15a0b1e92d21a59f351e987b9fd462bf6ef2dc253"
		public static let publicKey = "cd33a22f74d8e04977f74db15a0b1e92d21a59f351e987b9fd462bf6ef2dc253"
		public static let signedData = "c4425645318449e5f49f4923a9d12f2d945ebe1c4d897a27883394af46463ba4f9ca16e3d7ffe6439dc62b054b74af3869c2da7efd0c27039b93de2bf7ea490f"
		public static let base58Encoded = "edpkvCbYCa6d6g9hEcK6tvwgsY9jfB4HDzp3jZSBwfuWNSvxE5T5KR"
	}
	
	public struct linearWalletEd255519_withPassphrase {
		public static let address = "tz1hQ4wkVfNAh3eGeaDpoTBmQ9KjX9ZMzc6q"
		public static let privateKey = "b17877f6b326bf75e8a5bf2bd7e457a03b103d469c869ef4e3b0473d9b9d50b1482c29dcbfc1f94c185e9d8da1ee7e06b16239a5d4e15a64a6f4150c298ab029"
		public static let publicKey = "482c29dcbfc1f94c185e9d8da1ee7e06b16239a5d4e15a64a6f4150c298ab029"
	}
	
	public struct linearWalletSecp256k1 {
		public static let address = "tz2UiZQJwaVAKxRuYxV8Tx5k8a64gZx1ZwYJ"
		public static let privateKey = "80d4e52897c8e14fbfad4637373de405fa2cc7f27eb9f890db975948b0e7fdb0"
		public static let publicKey = "032460b1fb47abc6b64bfa313efdba92eb4313f58b90ac30b68851b4880cc9c819"
	}
	
	public struct hdWallet {
		public static let address = "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF"
		public static let privateKey = "3f54684924468bc4a7044729ee578176aef5933c69ad16ff3340412e4a5ca3961e4291f2501ce283e55ce583d4388ec8d247dd6c72fff3ff2d48b2af84cc9a23"
		public static let publicKey = "1e4291f2501ce283e55ce583d4388ec8d247dd6c72fff3ff2d48b2af84cc9a23"
		public static let signedData = "ac7047164b3e76cde3b1962726206cb82b0f59ae84c6c74b04feaacd3f433c1c2399bf55d044ca61e08832f3f1e91d789ef2cbc83c09ecffec3df0d4b88f320c"
		public static let base58Encoded = "edpktsYtWnwnuiLkHySdNSihWEChdeFzyz9v8Vdb8aAWRibsPH7g7E"
		
		public static let childWalletAddresses = ["tz1UT8i2XoS3c8fosNhJeBQ9fRSYURT7m5gZ", "tz1LbbJKLx3Epu8hNqzRQk82fVT6AEWXMymB", "tz1YWuMAR5r15tqHwgBP5cAQULua3o7ZfiJf"]
	}
	
	public struct hdWallet_withPassphrase {
		public static let address = "tz1dcAi3sVtc5xLyNu53avkEiPvhi9cN2idj"
		public static let privateKey = "f76414eebdfea880ada1dad22186f150335547a124d64a65a10fbda25d70dac19ce8d8d68df863ed6e2c7a8172726f3bd71ddf7e968ba0095bfdf549fea7d67c"
		public static let publicKey = "9ce8d8d68df863ed6e2c7a8172726f3bd71ddf7e968ba0095bfdf549fea7d67c"
	}
	
	public struct hdWallet_non_hardened {
		public static let address = "tz1gr7B9AsXJMMSBg7NugNvDZpGgvcvX4Q8M"
		public static let privateKey = "2cd4e64b16e9bb9fa7c19aa272bd2dba0d9ae3ee3f764e15351ab7ec11fc37ad"
		public static let publicKey = "caa6f27ebb93808caf3ee7ecbff0fc482bbde9e123293bf34d78dbca105e02c2"
		public static let derivationPath = "m/44'/1729'/0/0"
	}
	
	public struct hdWallet_hardened_change {
		public static let address = "tz1iKnE1sKYvB6F42XAKAf9iR6YauEv2ENzZ"
		public static let privateKey = "8ad51941e26afcdd6408ff59d94188449180bdbda71d8529fafd1948eca8af04ace4ba9cc11a961a78324700ed36feb0277ee005d7cb79ccdb821503029bc672"
		public static let publicKey = "ace4ba9cc11a961a78324700ed36feb0277ee005d7cb79ccdb821503029bc672"
		public static let derivationPath = "m/44'/1729'/0'/1'"
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
	public static let tokenWithNFTs = Token(name: "Token with NFTS", symbol: "T-NFT", tokenType: .nonfungible, faVersion: .fa2, balance: TokenAmount.zero(), thumbnailURL: nil, tokenContractAddress: "KT1G1cCRNBgQ48mVDjopHjEmTN5Sbtabc123", tokenId: 0, nfts: [
		NFT(fromTzKTBalance: TzKTBalance(balance: "1", token: TzKTBalanceToken(contract: TzKTAddress(alias: nil, address: "KT1G1cCRNBgQ48mVDjopHjEmTN5Sbtabc123"), tokenId: "4", standard: .fa2, totalSupply: "1", metadata: nil)))
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
