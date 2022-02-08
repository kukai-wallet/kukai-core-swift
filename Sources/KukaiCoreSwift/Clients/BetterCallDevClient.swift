//
//  BetterCallDevClient.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 27/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import Kingfisher
import os.log

/// BetterCallDev (BCD) is an indexing/smart contract debugging tool, used for the Tezos blockchain.
/// This class allows developers to interact with their API, to fetch data that would otherwise be impossible for a mobile app
public class BetterCallDevClient {
	
	/// Dedicated BCD errors
	public enum BetterCallDevClientError: Error {
		case invalidURL
		case parseError(String)
	}
	
	/// The networking service used to fire requests
	private let networkService: NetworkService
	
	/// The config used for URL's and logging
	private let config: TezosNodeClientConfig
	
	
	
	
	
	// MARK: - Init
	
	/**
	Init a `BetterCallDevClient` with a `NetworkService` and a `TezosNodeClientConfig`.
	- parameter networkService: `NetworkService` used to manage network communication.
	- parameter config: `TezosNodeClientConfig` used to apss in settings.
	*/
	public init(networkService: NetworkService, config: TezosNodeClientConfig) {
		self.networkService = networkService
		self.config = config
	}
	
	
	
	
	
	// MARK: - Errors
	
	/**
	Primarily the `TzKTClient` is used to fetch details on operations. However for more complex calls involving smart contracts, TzKT will only return limited error message info.
	BetterCallDev includles all the details needed to display messages. This function allows developers to query the detailed error message.
	- parameter byHash: The hash String of the operation.
	- parameter completion: Called with the result.
	*/
	public func getMoreDetailedError(byHash hash: String, completion: @escaping ((BetterCallDevOperationError?, ErrorResponse?) -> Void)) {
		var url = config.betterCallDevURL
		url.appendPathComponent("v1/opg/" + hash)
		
		networkService.request(url: url, isPOST: false, withBody: nil, forReturnType: [BetterCallDevOperation].self) { (result) in
			switch result {
				case .success(let operations):
					for op in operations {
						if let moreDetailedError = op.moreDetailedError() {
							completion(moreDetailedError, nil)
							return
						}
					}
					
					completion(nil, nil)
					
				case .failure(let error):
					os_log(.error, log: .kukaiCoreSwift, "Parse error: %@", "\(error)")
					completion(nil, ErrorResponse.unknownParseError(error: error))
			}
		}
	}
}
