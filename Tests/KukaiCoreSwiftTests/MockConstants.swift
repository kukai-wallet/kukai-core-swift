//
//  MockConstants.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
@testable import KukaiCoreSwift

public struct MockConstants {
	
	static let shared = MockConstants()
	
	public let mockURLSession: URLSession
	
	// MARK: - Config / Services
	
	public var config: TezosNodeClientConfig
	public let loggingConfig: LoggingConfig
	public let networkService: NetworkService
	public let tezosNodeClient: TezosNodeClient
	public let betterCallDevClient: BetterCallDevClient
	
	
	public static let http200 = HTTPURLResponse(url: URL(string: "http://google.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
	public static let http500 = HTTPURLResponse(url: URL(string: "http://google.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
	
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
		
		var bcdTokenBalanceURL = bcdURL.appendingPathComponent("v1/account/florencenet/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/token_balances")
		bcdTokenBalanceURL.appendQueryItem(name: "offset", value: 0)
		bcdTokenBalanceURL.appendQueryItem(name: "size", value: 10)
		bcdTokenBalanceURL.appendQueryItem(name: "sort_by", value: "balance")
		
		// Format [ URL: ( Data?, HTTPURLResponse? ) ]
		MockURLProtocol.mockURLs = [
			
			// RPC URLs
			baseURL.appendingPathComponent("version"): (MockConstants.jsonStub(fromFilename: "version"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/constants"): (MockConstants.jsonStub(fromFilename: "constants"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/manager_key"): (MockConstants.jsonStub(fromFilename: "manager_key"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/counter"): (MockConstants.jsonStub(fromFilename: "counter"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head"): (MockConstants.jsonStub(fromFilename: "head"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/helpers/scripts/run_operation"): (MockConstants.jsonStub(fromFilename: "run_operation"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/BLEDGNuADAwZfKK7iZ6PHnu7gZFSXuRPVFXe2PhSnb6aMyKn3mK/helpers/forge/operations"): (MockConstants.jsonStub(fromFilename: "forge"), MockConstants.http200),
			// Parse is handled inside MockURLProtocol due to its special requirements
			baseURL.appendingPathComponent("chains/main/blocks/BLEDGNuADAwZfKK7iZ6PHnu7gZFSXuRPVFXe2PhSnb6aMyKn3mK/helpers/preapply/operations"): (MockConstants.jsonStub(fromFilename: "preapply"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/BMLWVn1nEWeEzf6pxn3VYx7YcQ3zPay7HQtQ3rBMxuc7bXCG8BB/helpers/preapply/operations"): (MockConstants.jsonStub(fromFilename: "preapply"), MockConstants.http200),
			baseURL.appendingPathComponent("injection/operation"): (MockConstants.jsonStub(fromFilename: "inject"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/balance"): (MockConstants.jsonStub(fromFilename: "balance"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/delegate"): (MockConstants.jsonStub(fromFilename: "delegate"), MockConstants.http200),
			baseURL.appendingPathComponent("chains/main/blocks/head/context/contracts/KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8/storage"): (MockConstants.jsonStub(fromFilename: "contract_storage"), MockConstants.http200),
			
			// BCD URLs
			bcdURL.appendingPathComponent("v1/account/florencenet/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF"): (MockConstants.jsonStub(fromFilename: "bcd_account"), MockConstants.http200),
			bcdURL.appendingPathComponent("v1/account/florencenet/tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF/count"): (MockConstants.jsonStub(fromFilename: "bcd_token-count"), MockConstants.http200),
			bcdTokenBalanceURL: (MockConstants.jsonStub(fromFilename: "bcd_token-balances"), MockConstants.http200),
			bcdURL.appendingPathComponent("v1/contract/florencenet/KT198WVepFnjQtx9HUhuKc2x8gUt9z2fvyv6"): (MockConstants.jsonStub(fromFilename: "bcd_contract-metadata"), MockConstants.http200),
			bcdURL.appendingPathComponent("v1/contract/florencenet/KT1BVwiXfDdaXsvcmvSmBkpZt4vbGVhLmhBh"): (MockConstants.jsonStub(fromFilename: "bcd_contract-metadata"), MockConstants.http200),
			bcdURL.appendingPathComponent("v1/contract/florencenet/KT1CMbwrQodEYFpdJmk8pzN8SzieupG6ZrZE"): (MockConstants.jsonStub(fromFilename: "bcd_contract-metadata"), MockConstants.http200),
			bcdURL.appendingPathComponent("v1/contract/florencenet/KT1DEJEcfiMUWYjn1ZCTbbLokRcP26sx2pTH"): (MockConstants.jsonStub(fromFilename: "bcd_contract-metadata"), MockConstants.http200),
			bcdURL.appendingPathComponent("v1/contract/florencenet/KT1DaKxkR1LdnXW1tr7yozdwEAiSQDpCLUBj"): (MockConstants.jsonStub(fromFilename: "bcd_contract-metadata"), MockConstants.http200),
			bcdURL.appendingPathComponent("v1/contract/florencenet/KT1FXDTQb1o7Q7HecuxaWQ18XyHTsRrzuaZs"): (MockConstants.jsonStub(fromFilename: "bcd_contract-metadata"), MockConstants.http200),
			bcdURL.appendingPathComponent("v1/contract/florencenet/KT1P3RGEAa78XLTs3Hkpd1VWtryQRLDjiXqF"): (MockConstants.jsonStub(fromFilename: "bcd_contract-metadata"), MockConstants.http200),
			bcdURL.appendingPathComponent("v1/contract/florencenet/KT1VCczKAoRQJKco7NiSaB93PMkYCbL2z1K7"): (MockConstants.jsonStub(fromFilename: "bcd_contract-metadata"), MockConstants.http200),
			bcdURL.appendingPathComponent("v1/contract/florencenet/KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8"): (MockConstants.jsonStub(fromFilename: "bcd_contract-metadata"), MockConstants.http200),
			MockConstants.bcdTokenMetadataURL(config: config, contract: "KT198WVepFnjQtx9HUhuKc2x8gUt9z2fvyv6"): (MockConstants.jsonStub(fromFilename: "bcd_token-metadata"), MockConstants.http200),
			MockConstants.bcdTokenMetadataURL(config: config, contract: "KT1BVwiXfDdaXsvcmvSmBkpZt4vbGVhLmhBh"): (MockConstants.jsonStub(fromFilename: "bcd_token-metadata"), MockConstants.http200),
			MockConstants.bcdTokenMetadataURL(config: config, contract: "KT1CMbwrQodEYFpdJmk8pzN8SzieupG6ZrZE"): (MockConstants.jsonStub(fromFilename: "bcd_token-metadata"), MockConstants.http200),
			MockConstants.bcdTokenMetadataURL(config: config, contract: "KT1DEJEcfiMUWYjn1ZCTbbLokRcP26sx2pTH"): (MockConstants.jsonStub(fromFilename: "bcd_token-metadata-nft"), MockConstants.http200),
			MockConstants.bcdTokenMetadataURL(config: config, contract: "KT1DaKxkR1LdnXW1tr7yozdwEAiSQDpCLUBj"): (MockConstants.jsonStub(fromFilename: "bcd_token-metadata"), MockConstants.http200),
			MockConstants.bcdTokenMetadataURL(config: config, contract: "KT1FXDTQb1o7Q7HecuxaWQ18XyHTsRrzuaZs"): (MockConstants.jsonStub(fromFilename: "bcd_token-metadata"), MockConstants.http200),
			MockConstants.bcdTokenMetadataURL(config: config, contract: "KT1P3RGEAa78XLTs3Hkpd1VWtryQRLDjiXqF"): (MockConstants.jsonStub(fromFilename: "bcd_token-metadata"), MockConstants.http200),
			MockConstants.bcdTokenMetadataURL(config: config, contract: "KT1VCczKAoRQJKco7NiSaB93PMkYCbL2z1K7"): (MockConstants.jsonStub(fromFilename: "bcd_token-metadata"), MockConstants.http200),
			MockConstants.bcdTokenMetadataURL(config: config, contract: "KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8"): (MockConstants.jsonStub(fromFilename: "bcd_token-metadata"), MockConstants.http200),
			bcdURL.appendingPathComponent("v1/opg/ooVTdEf3WVFgubEHRpJGPkwUfidsfNiTESY3D6i5PbaNNisZjZ8"): (MockConstants.jsonStub(fromFilename: "bcd_more-detailed-error"), MockConstants.http200),
		]
		
		config.urlSession = mockURLSession
		networkService = NetworkService(urlSession: mockURLSession, loggingConfig: loggingConfig)
		tezosNodeClient = TezosNodeClient(config: config)
		tezosNodeClient.networkService = networkService
		
		let opService = OperationService(config: config, networkService: networkService)
		tezosNodeClient.operationService = opService
		tezosNodeClient.feeEstimatorService = FeeEstimatorService(config: config, operationService: opService, networkService: networkService)
		betterCallDevClient = BetterCallDevClient(networkService: networkService, config: config)
	}
	
	public static func bcdTokenMetadataURL(config: TezosNodeClientConfig, contract: String) -> URL {
		var bcdURL = config.betterCallDevURL.appendingPathComponent("v1/tokens/florencenet/metadata")
		bcdURL.appendQueryItem(name: "contract", value: contract)
		
		return bcdURL
	}
	
	
	
	// MARK: - Wallets
	
	public static let mnemonic = "remember smile trip tumble era cube worry fuel bracket eight kitten inform"
	public static let passphrase = "superSecurePassphrase"
	public static let messageToSign = "something very interesting that needs to be signed"
	
	public static let defaultLinearWallet = LinearWallet.create(withMnemonic: MockConstants.mnemonic, passphrase: "")!
	public static let defaultHdWallet = HDWallet.create(withMnemonic: MockConstants.mnemonic, passphrase: "")!
	
	public struct linearWalletEd255519 {
		public static let address = "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG"
		public static let privateKey = "80d4e52897c8e14fbfad4637373de405fa2cc7f27eb9f890db975948b0e7fdb0cd33a22f74d8e04977f74db15a0b1e92d21a59f351e987b9fd462bf6ef2dc253"
		public static let publicKey = "cd33a22f74d8e04977f74db15a0b1e92d21a59f351e987b9fd462bf6ef2dc253"
		public static let signedData = "c4d20c77d627d8c07e3f26ddc2e8ab9324471c65f9abd412de70a81c21ddc153dcfad1b31ab777a83c4e8a5dc021ea30d84da107dea4a192fc2ca9da9b3ede00"
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
		public static let privateKey = "3f54684924468bc4a7044729ee578176aef5933c69ad16ff3340412e4a5ca396"
		public static let publicKey = "1e4291f2501ce283e55ce583d4388ec8d247dd6c72fff3ff2d48b2af84cc9a23"
		public static let signedData = "3882ed4ec04ca29e12f3aecea23f50297f8c569c21092dfcef3196eff55ac39a637c2da93d348935a88110f30b177c052f17c432d888a06c9eba434cc3707601"
		public static let base58Encoded = "edpktsYtWnwnuiLkHySdNSihWEChdeFzyz9v8Vdb8aAWRibsPH7g7E"
	}
	
	public struct hdWallet_withPassphrase {
		public static let address = "tz1dcAi3sVtc5xLyNu53avkEiPvhi9cN2idj"
		public static let privateKey = "f76414eebdfea880ada1dad22186f150335547a124d64a65a10fbda25d70dac1"
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
		public static let privateKey = "8ad51941e26afcdd6408ff59d94188449180bdbda71d8529fafd1948eca8af04"
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
	public static let token3Decimals = Token(icon: nil, name: "Token 3 decimals", symbol: "TK3", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount.zero(), tokenContractAddress: "KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8", nfts: nil)
	public static let token10Decimals = Token(icon: nil, name: "Token 10 decimals", symbol: "TK10", tokenType: .fungible, faVersion: .fa2, balance: TokenAmount.zero(), tokenContractAddress: "KT1G1cCRNBgQ48mVDjopHjEmTN5Sbtar8nn9", nfts: nil)
	
	public static let xtz_1 = XTZAmount(fromNormalisedAmount: 1)
	public static let token3Decimals_1 = TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 3)
	public static let token10Decimals_1 = TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 10)
	
	
	
	// MARK: - Operations
	
	public static let blockchainHead = BlockchainHead(protocol: "PsFLorenaUUuikDWvMDr6fGBRG8kt3e3D3fHoXK1j1BFRxeSH4i", chainID: "NetXxkAx4woPLyu", hash: "BLEDGNuADAwZfKK7iZ6PHnu7gZFSXuRPVFXe2PhSnb6aMyKn3mK")
	public static let operationMetadata = OperationMetadata(managerKey: "edpktsYtWnwnuiLkHySdNSihWEChdeFzyz9v8Vdb8aAWRibsPH7g7E", counter: 143230, blockchainHead: MockConstants.blockchainHead)
	public static let networkConstants = NetworkConstants(time_between_blocks: ["30", "20"], hard_gas_limit_per_operation: "10400000", hard_gas_limit_per_block: "10400000", origination_size: 257, cost_per_byte: "250", hard_storage_limit_per_operation: "60000")
	public static let sendOperations = OperationFactory.sendOperation(MockConstants.xtz_1, of: MockConstants.tokenXTZ, from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address)
	public static let sendOperationWithReveal = [OperationReveal(wallet: MockConstants.defaultHdWallet), OperationTransaction(amount: MockConstants.xtz_1, source: MockConstants.defaultHdWallet.address, destination: MockConstants.defaultLinearWallet.address)]
	public static let sendOperationPayload = OperationFactory.operationPayload(fromMetadata: MockConstants.operationMetadata, andOperations: MockConstants.sendOperations, withWallet: MockConstants.defaultHdWallet)
	public static let sendOperationForged = "43f597d84037e88354ed041cc6356f737cc6638691979bb64415451b58b4af2c6c00ad00bb6cbcfc497bffbaf54c23511c74dbeafb2d00bdac1a80bd3fe0d403e80700005134b25890279835eb946e6369a3d719bc0d617700"
	public static let operationHashToSearch = "ooVTdEf3WVFgubEHRpJGPkwUfidsfNiTESY3D6i5PbaNNisZjZ8"
	
	
	
	
	// MARK: - Functions
	
	static func jsonStub(fromFilename filename: String, ofExtension fileExtension: String = "json", replacing: [String: String] = [:]) -> Data {
		guard let path = Bundle.module.url(forResource: filename, withExtension: fileExtension, subdirectory: "Stubs"),
			let stubData = try? Data(contentsOf: path) else {
				fatalError("Can't find or read `\(filename).\(fileExtension)`")
		}
		
		if replacing.keys.count > 0 {
			guard let dataString = String(data: stubData, encoding: .utf8) else {
				fatalError("Can't find or read `\(filename).\(fileExtension)`")
			}
			
			var updatedString = dataString
			replacing.keys.forEach { (key) in
				updatedString = updatedString.replacingOccurrences(of: key, with: replacing[key] ?? "")
			}
			
			return updatedString.data(using: .utf8) ?? Data()
		}
		
		return stubData
	}
}
