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
		case ghostnet
		case protocolnet
		case nextnet
		case experimental
	}
	
	/// Allow switching between local forging or remote forging+parsing
	public enum ForgingType: String {
		case local
		case remote
	}
	
	
	
	// MARK: - Public Constants
	
	/// Preconfigured struct with all the URL's needed to work with Tezos mainnet
	public struct defaultMainnetURLs {
		
		/// The default mainnet URLs to use for estimating and injecting operations
		public static let nodeURLs = [URL(string: "https://mainnet.smartpy.io")!, URL(string: "https://rpc.tzbeta.net")!]
		
		/// The default mainnet URL to use for `tzktURL`, For more information on this service, see: https://api.tzkt.io/
		public static let tzktURL = URL(string: "https://api.tzkt.io/")!
		
		/// The default mainnet URL to use for `tezosDomainsURL`, For more information on this service, see: https://tezos.domains/
		public static let tezosDomainsURL = URL(string: "https://api.tezos.domains/graphql")!
		
		/// The default mainnet URL to use for `objktApiURL`, For more information on this service, see: https://public-api-v3-20221206.objkt.com/docs/
		public static let objktApiURL = URL(string: "https://data.objkt.com/v3/graphql")!
	}
	
	/// Preconfigured struct with all the URL's needed to work with Tezos testnet
	public struct defaultGhostnetURLs {
		
		/// The default testnet URLs to use for estimating and injecting operations
		public static let nodeURLs = [URL(string: "https://ghostnet.smartpy.io")!, URL(string: "https://rpc.ghostnet.tzboot.net")!]
		
		/// The default testnet URL to use for `tzktURL`, For more information on this service, see: https://api.tzkt.io/
		public static let tzktURL = URL(string: "https://api.ghostnet.tzkt.io/")!
		
		/// The default testnet URL to use for `tezosDomainsURL`, For more information on this service, see: https://tezos.domains/
		public static let tezosDomainsURL = URL(string: "https://ghostnet-api.tezos.domains/graphql")!
		
		/// The default testnet URL to use for `objktApiURL`, For more information on this service, see: https://public-api-v3-20221206.objkt.com/docs/
		public static let objktApiURL = URL(string: "https://data.objkt.com/v3/graphql")!
	}
	
	
	
	// MARK: - Public Properties
	
	/// An array of Node URLs. Default to first, and fallback to rest one by one to attempt to avoid server side issues
	public let nodeURLs: [URL]
	
	/// Controls whether to use local forging or remote forging+parsing
	public let forgingType: ForgingType
	
	/// The URL to use for `TzKTClient`
	public let tzktURL: URL
	
	/// The URL to use for `TezosDomainsClient`
	public let tezosDomainsURL: URL?
	
	/// The URL to use for `TezosDomainsClient`
	public let objktApiURL: URL?
	
	/// The `URLSession` that will be used for all network communication. If looking to mock this library, users should create their own `URLSessionMock` and pass it in.
	public var urlSession: URLSession
	
	/// The network type of the connected node
	public let networkType: NetworkType
	
	/// Control what gets logged to the console
	public var loggingConfig: LoggingConfig = LoggingConfig()
	
	
	
	// MARK: - Init
	
	/**
	Private Init to prevent users from making mistakes with remote forging settings.
	- parameter nodeURLs: An array of URLs to use to estiamte and inject operations. Default to first and fallback to others as needed
	- parameter forgeType: Enum to indicate whether to use local or remote forging.
	- parameter tzktURL: The URL to use for `TzKTClient`.
	- parameter tezosDomainsURL: The URL to use for `TezosDomainsClient`.
	- parameter urlSession: The URLSession object that will perform all the network operations.
	- parameter networkType: Enum indicating the network type.
	*/
	private init(nodeURLs: [URL], forgingType: ForgingType, tzktURL: URL, tezosDomainsURL: URL?, objktApiURL: URL?, urlSession: URLSession, networkType: NetworkType) {
		self.nodeURLs = nodeURLs
		self.forgingType = forgingType
		self.tzktURL = tzktURL
		self.tezosDomainsURL = tezosDomainsURL
		self.objktApiURL = objktApiURL
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
				nodeURLs = TezosNodeClientConfig.defaultMainnetURLs.nodeURLs
				forgingType = .local
				tzktURL = TezosNodeClientConfig.defaultMainnetURLs.tzktURL
				tezosDomainsURL = TezosNodeClientConfig.defaultMainnetURLs.tezosDomainsURL
				objktApiURL = TezosNodeClientConfig.defaultMainnetURLs.objktApiURL
			
			case .ghostnet:
				nodeURLs = TezosNodeClientConfig.defaultGhostnetURLs.nodeURLs
				forgingType = .local
				tzktURL = TezosNodeClientConfig.defaultGhostnetURLs.tzktURL
				tezosDomainsURL = TezosNodeClientConfig.defaultGhostnetURLs.tezosDomainsURL
				objktApiURL = TezosNodeClientConfig.defaultGhostnetURLs.objktApiURL
			
			case .protocolnet:
				fatalError("No defaults for networkType protocolnet. Must be supplied by user")
				
			case .nextnet:
				fatalError("No defaults for networkType nextnet. Must be supplied by user")
				
			case .experimental:
				fatalError("No defaults for networkType experimental. Must be supplied by user")
		}
	}
	
	/**
	Creates an instance of `TezosNodeClientConfig` with only the required properties needed when using local forge.
	- parameter nodeURLs: An array of URLs to use to estiamte and inject operations. Default to first and fallback to others as needed
	- parameter tzktURL: The URL to use for `TzKTClient`.
	- parameter urlSession: The URLSession object that will perform all the network operations.
	- parameter networkType: Enum indicating the network type.
	- returns TezosNodeClientConfig
	*/
	public static func configWithLocalForge(nodeURLs: [URL], tzktURL: URL, tezosDomainsURL: URL, objktApiURL: URL, urlSession: URLSession, networkType: NetworkType) -> TezosNodeClientConfig {
		return TezosNodeClientConfig(
			nodeURLs: nodeURLs,
			forgingType: .local,
			tzktURL: tzktURL,
			tezosDomainsURL: tezosDomainsURL,
			objktApiURL: objktApiURL,
			urlSession: urlSession,
			networkType: networkType)
	}
	
	/**
	Creates an instance of `TezosNodeClientConfig` with the required properties for remote forging. Note: function will casue a `fatalError` if supplied with less than 2 `nodeURLs`
	- parameter nodeURLs: An array of URLs to use to estiamte and inject operations. Default to first and fallback to others as needed
	- parameter tzktURL: The URL to use for `TzKTClient`.
	- parameter urlSession: The URLSession object that will perform all the network operations.
	- parameter networkType: Enum indicating the network type.
	- returns TezosNodeClientConfig
	*/
	public static func configWithRemoteForge(nodeURLs: [URL], parseNodeURL: URL, tzktURL: URL, tezosDomainsURL: URL, objktApiURL: URL, urlSession: URLSession, networkType: NetworkType) -> TezosNodeClientConfig {
		if nodeURLs.count >= 2 {
			fatalError("remote forging requires using different servers to prevent against man in the middle attacks. You must supply at least 2 URLs")
		}
		
		return TezosNodeClientConfig(
			nodeURLs: nodeURLs,
			forgingType: .remote,
			tzktURL: tzktURL,
			tezosDomainsURL: tezosDomainsURL,
			objktApiURL: objktApiURL,
			urlSession: urlSession,
			networkType: networkType)
	}
}
