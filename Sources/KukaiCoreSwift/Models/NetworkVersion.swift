//
//  NetworkVersion.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 26/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// The version of the Tezos code being run by the given node
public struct NetworkVersion: Codable {
	
	public static let chainName_mainnet = "mainnet"
	public static let chainName_ghostnet = "ghostnet"
	public static let chainName_ithacanet = "ithacanet"
	
	let network_version: network_version
	
	struct network_version: Codable {
		let chain_name: String
	}
	
	public func chainName() -> String {
		let chainComponents = self.network_version.chain_name.components(separatedBy: "_")
		
		guard chainComponents.count > 1 else {
			return "unknown"
		}
		
		let chainName = chainComponents[1].lowercased()
		if chainName == NetworkVersion.chainName_ithacanet {
			// ithacanet is a long long dead network, that ghostnet was spun up from. It doesn't exist anymore but ghostnet still refers to itself as ithacanet
			// Anywhere this is seen, it is now only refering to ghostnet
			return NetworkVersion.chainName_ghostnet
			
		} else {
			return chainComponents[1].lowercased()
		}
	}
	
	public func isMainnet() -> Bool {
		return chainName() == NetworkVersion.chainName_mainnet
	}
}
