//
//  NetworkVersion.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 26/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// A enum representing the chain name for Tezos nodes, denoting the protocol version being run or mainnet
public enum TezosChainName: String {
	case mainnet
	case alphanet
	case babylonnet
	case carthagenet
	case delphinet
	case edonet = "edo2net"
	case florencenet
	case granadanet
	case hangzhounet
	case ithacanet
	case jakartanet
	case kathmandu
	case unknwon
}

/// The version of the Tezos code being run by the given node
public struct NetworkVersion: Codable {
	
	let network_version: network_version
	
	struct network_version: Codable {
		let chain_name: String
	}
	
	public func chainName() -> TezosChainName {
		let chainComponents = self.network_version.chain_name.components(separatedBy: "_")
		
		guard chainComponents.count > 1 else {
			return .unknwon
		}
		
		let netName = chainComponents[1].lowercased()
		return TezosChainName(rawValue: netName) ?? .unknwon
	}
	
	public func isMainnet() -> Bool {
		return chainName() == .mainnet
	}
}
