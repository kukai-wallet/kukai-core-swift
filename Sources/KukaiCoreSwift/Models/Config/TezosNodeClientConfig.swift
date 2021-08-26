//
//  TezosNodeClientConfig.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 19/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// A configuration object used to provide settings to the TezosNodeClient
public struct TezosNodeClientConfig {
	
	// MARK: - Types
	
	/// An enum indicating whether the network is mainnet or testnet
	public enum NetworkType: String {
		case mainnet
		case testnet
	}
	
	/// Allow switching between local forging or remote forging+parsing
	public enum ForgingType: String {
		case local
		case remote
	}
	
	
	
	// MARK: - Public Constants
	
	/// Preconfigured struct with all the URL's needed to work with Tezos mainnet
	public struct defaultMainnetURLs {
		
		/// The default mainnet URL to use for `primaryNodeURL`, For more information on the free service, see: https://tezos.giganode.io/
		public static let primaryNodeURL = URL(string: "https://mainnet-tezos.giganode.io/")!
		
		/// The default mainnet URL to use for `parseNodeURL`, For more information on the free service, see: https://nautilus.cloud/
		public static let parseNodeURL = URL(string: "https://tezos-prod.cryptonomic-infra.tech:443/")!
		
		/// The default mainnet URL to use for `tzktURL`, For more information on this service, see: https://api.tzkt.io/
		public static let tzktURL = URL(string: "https://api.tzkt.io/")!
		
		/// The default mainnet URL to use for `betterCallDevURL`, For more information on this service, see: https://api.better-call.dev/v1/docs/index.html
		public static let betterCallDevURL = URL(string: "https://api.better-call.dev/")!
	}
	
	/// Preconfigured struct with all the URL's needed to work with Tezos testnet
	public struct defaultTestnetURLs {
		
		/// The default testnet URL to use for `primaryNodeURL`, For more information on this service, see: https://tezos.giganode.io/
		public static let primaryNodeURL = URL(string: "https://api.tez.ie/rpc/granadanet")! // Doesn't seem to be available on Giganode atm
		
		/// The default testnet URL to use for `parseNodeURL`
		public static let parseNodeURL = URL(string: "https://api.tez.ie/rpc/granadanet")!
		
		/// The default testnet URL to use for `tzktURL`, For more information on this service, see: https://api.tzkt.io/
		public static let tzktURL = URL(string: "https://api.granadanet.tzkt.io/")!
		
		/// The default testnet URL to use for `betterCallDevURL`, For more information on this service, see: https://api.better-call.dev/v1/docs/index.html
		public static let betterCallDevURL = URL(string: "https://api.better-call.dev/")!
	}
	
	
	
	// MARK: - Public Properties
	
	/// The main URL used for remote forging, fetching balances, setting delegates and other forms of queries and operations.
	public let primaryNodeURL: URL
	
	/// When using remote forging, it is essential to use a second server to verify the contents of the remote forge match what the library sent.
	public let parseNodeURL: URL?
	
	/// Controls whether to use local forging or remote forging+parsing
	public let forgingType: ForgingType
	
	/// Which chain to use for inDEXter queries
	public let tezosChainName: TezosChainName
	
	/// The URL to use for `TzKTClient`
	public let tzktURL: URL
	
	/// The URL to use for `BetterCallDevClient`
	public let betterCallDevURL: URL
	
	/// The `URLSession` that will be used for all network communication. If looking to mock this library, users should create their own `URLSessionMock` and pass it in.
	public var urlSession: URLSession
	
	/// The network type of the connected node
	public let networkType: NetworkType
	
	/// Control what gets logged to the console
	public var loggingConfig: LoggingConfig = LoggingConfig()
	
	
	
	// MARK: - Init
	
	/**
	Private Init to prevent users from making mistakes with remote forging settings.
	- parameter primaryNodeURL: The URL of the primary node that will perform the majority of the network operations.
	- parameter parseNodeURL: The URL to use to parse and verify a remote forge.
	- parameter forgeType: Enum to indicate whether to use local or remote forging.
	- parameter tezosChainName: The chain name used by services such as InDEXter and Better call dev when deciding which network to use
	- parameter tzktURL: The URL to use for `TzKTClient`.
	- parameter betterCallDevURL: The URL to use for `BetterCallDevClient`.
	- parameter urlSession: The URLSession object that will perform all the network operations.
	- parameter networkType: Enum indicating the network type.
	*/
	private init(primaryNodeURL: URL, parseNodeURL: URL?, forgingType: ForgingType, tezosChainName: TezosChainName, tzktURL: URL, betterCallDevURL: URL, urlSession: URLSession, networkType: NetworkType) {
		self.primaryNodeURL = primaryNodeURL
		self.parseNodeURL = primaryNodeURL
		self.forgingType = forgingType
		self.tezosChainName = tezosChainName
		self.tzktURL = tzktURL
		self.betterCallDevURL = betterCallDevURL
		self.urlSession = urlSession
		self.networkType = networkType
	}
	
	/**
	Init a `TezosNodeClientConfig` with the defaults
	- parameter withDefaultsForNetworkType: Use the default settings for the given network type
	*/
	public init(withDefaultsForNetworkType networkType: NetworkType) {
		
		self.urlSession = URLSession.shared
		self.networkType = networkType
		
		switch networkType {
			case .mainnet:
				primaryNodeURL = TezosNodeClientConfig.defaultMainnetURLs.primaryNodeURL
				parseNodeURL = TezosNodeClientConfig.defaultMainnetURLs.parseNodeURL
				forgingType = .local
				tezosChainName = .mainnet
				tzktURL = TezosNodeClientConfig.defaultMainnetURLs.tzktURL
				betterCallDevURL = TezosNodeClientConfig.defaultMainnetURLs.betterCallDevURL
			
			case .testnet:
				primaryNodeURL = TezosNodeClientConfig.defaultTestnetURLs.primaryNodeURL
				parseNodeURL = TezosNodeClientConfig.defaultTestnetURLs.parseNodeURL
				forgingType = .local
				tezosChainName = .granadanet
				tzktURL = TezosNodeClientConfig.defaultTestnetURLs.tzktURL
				betterCallDevURL = TezosNodeClientConfig.defaultTestnetURLs.betterCallDevURL
		}
	}
	
	/**
	Creates an instance of `TezosNodeClientConfig` with only the required properties needed when using local forge.
	- parameter primaryNodeURL: The URL of the primary node that will perform the majority of the network operations.
	- parameter tezosChainName: The chain name used by services such Better call dev, when deciding which network to use
	- parameter tzktURL: The URL to use for `TzKTClient`.
	- parameter betterCallDevURL: The URL to use for `BetterCallDevClient`.
	- parameter urlSession: The URLSession object that will perform all the network operations.
	- parameter networkType: Enum indicating the network type.
	- returns TezosNodeClientConfig
	*/
	public static func configWithLocalForge(primaryNodeURL: URL, tezosChainName: TezosChainName, tzktURL: URL, betterCallDevURL: URL, urlSession: URLSession, networkType: NetworkType) -> TezosNodeClientConfig {
		return TezosNodeClientConfig(primaryNodeURL: primaryNodeURL, parseNodeURL: nil, forgingType: .local, tezosChainName: tezosChainName, tzktURL: tzktURL, betterCallDevURL: betterCallDevURL, urlSession: urlSession, networkType: networkType)
	}
	
	/**
	Creates an instance of `TezosNodeClientConfig` with the required properties for remote forging. Note: function will casue a `fatalError` is users attempt to set `primaryNodeURL` and  `parseNodeURL` to the same destination
	- parameter primaryNodeURL: The URL of the primary node that will perform the majority of the network operations.
	- parameter parseNodeURL: The URL to use to parse and verify a remote forge. Must be a different server to primary node.
	- parameter tezosChainName: The chain name used by services such Better call dev, when deciding which network to use
	- parameter tzktURL: The URL to use for `TzKTClient`.
	- parameter betterCallDevURL: The URL to use for `BetterCallDevClient`.
	- parameter urlSession: The URLSession object that will perform all the network operations.
	- parameter networkType: Enum indicating the network type.
	- returns TezosNodeClientConfig
	*/
	public static func configWithRemoteForge(primaryNodeURL: URL, parseNodeURL: URL, tezosChainName: TezosChainName, tzktURL: URL, betterCallDevURL: URL, urlSession: URLSession, networkType: NetworkType) -> TezosNodeClientConfig {
		if primaryNodeURL.absoluteString == parseNodeURL.absoluteString {
			fatalError("Setting the `primaryNodeURL` and the `parseNodeURL` to the same server poses a huge security risk, called a 'Blind signature attack'. Doing so is forbidden in this library.")
		}
		
		return TezosNodeClientConfig(primaryNodeURL: primaryNodeURL, parseNodeURL: parseNodeURL, forgingType: .remote, tezosChainName: tezosChainName, tzktURL: tzktURL, betterCallDevURL: betterCallDevURL, urlSession: urlSession, networkType: networkType)
	}
}
