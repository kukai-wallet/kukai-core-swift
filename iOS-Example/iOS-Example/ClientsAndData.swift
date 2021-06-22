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
	let clientConfig: TezosNodeClientConfig
	let tezosNodeClient: TezosNodeClient
	let bcdClient: BetterCallDevClient
	let tzktClient: TzKTClient
	
	
	// Data
	var currentWalletAddress = ""
	var account: Account? = nil
	
	private init() {
		clientConfig = TezosNodeClientConfig(withDefaultsForNetworkType: .testnet)
		tezosNodeClient = TezosNodeClient(config: clientConfig)
		bcdClient = BetterCallDevClient(networkService: tezosNodeClient.networkService, config: clientConfig)
		tzktClient = TzKTClient(networkService: tezosNodeClient.networkService, config: clientConfig, betterCallDevClient: bcdClient)
	}
}
