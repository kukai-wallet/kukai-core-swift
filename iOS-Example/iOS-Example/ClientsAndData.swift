//
//  ClientsAndData.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 10/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import KukaiCoreSwift

public class ClientsAndData {
	
	public static let shared = ClientsAndData()
	
	// Clients
	var clientConfig: TezosNodeClientConfig
	var tezosNodeClient: TezosNodeClient
	var bcdClient: BetterCallDevClient
	var tzktClient: TzKTClient
	var tezosDomainsClient: TezosDomainsClient
	var torusAuthService: TorusAuthService
	var tezToolsClient: TezToolsClient
	
	
	// Data
	var currentWalletAddress = ""
	var account: Account? = nil
	
	private init() {
		clientConfig = TezosNodeClientConfig(withDefaultsForNetworkType: .testnet)
		tezosNodeClient = TezosNodeClient(config: clientConfig)
		bcdClient = BetterCallDevClient(networkService: tezosNodeClient.networkService, config: clientConfig)
		tzktClient = TzKTClient(networkService: tezosNodeClient.networkService, config: clientConfig, betterCallDevClient: bcdClient)
		tezosDomainsClient = TezosDomainsClient(networkService: tezosNodeClient.networkService, config: clientConfig)
		torusAuthService = TorusAuthService(
			networkType: clientConfig.networkType,
			networkService: tezosNodeClient.networkService,
			nativeRedirectURL: "tdsdk://tdsdk/oauthCallback",
			googleRedirectURL: "com.googleusercontent.apps.238941746713-vfap8uumijal4ump28p9jd3lbe6onqt4:/oauthredirect",
			browserRedirectURL: "https://scripts.toruswallet.io/redirect.html"
		)
		tezToolsClient = TezToolsClient(networkService: tezosNodeClient.networkService, config: clientConfig)
	}
	
	public func updateNetwork(network: TezosNodeClientConfig.NetworkType) {
		clientConfig = TezosNodeClientConfig(withDefaultsForNetworkType: network)
		tezosNodeClient = TezosNodeClient(config: clientConfig)
		bcdClient = BetterCallDevClient(networkService: tezosNodeClient.networkService, config: clientConfig)
		tzktClient = TzKTClient(networkService: tezosNodeClient.networkService, config: clientConfig, betterCallDevClient: bcdClient)
		tezosDomainsClient = TezosDomainsClient(networkService: tezosNodeClient.networkService, config: clientConfig)
		torusAuthService = TorusAuthService(
			networkType: clientConfig.networkType,
			networkService: tezosNodeClient.networkService,
			nativeRedirectURL: "tdsdk://tdsdk/oauthCallback",
			googleRedirectURL: "com.googleusercontent.apps.238941746713-vfap8uumijal4ump28p9jd3lbe6onqt4:/oauthredirect",
			browserRedirectURL: "https://scripts.toruswallet.io/redirect.html"
		)
		tezToolsClient = TezToolsClient(networkService: tezosNodeClient.networkService, config: clientConfig)
	}
}
