//
//  TorusVerifier.swift
//  
//
//  Created by Simon Mcloughlin on 04/07/2022.
//

import Foundation

public enum TorusVerifierType: String {
	
	/// Single once off verifiers, not aggregate
	case singleLogin = "single_login"
	
	/// Aggregate vaerifer composed of multiple smaller `.singleLogin`
	case singleIdVerifier = "single_id_verifier"
	
	///
	case andAggregateVerifier =  "and_aggregate_verifier"
	
	///
	case orAggregateVerifier = "or_aggregate_verifier"
}


public struct TorusVerifier: Codable {
	public let type: TorusVerifierType
	public let networkType: TezosNodeClientConfig.NetworkType
	public let name: String
	public let aggregateName: String
	public let clientId: String
	public let id: String
	public let redirectURL: URL
}
