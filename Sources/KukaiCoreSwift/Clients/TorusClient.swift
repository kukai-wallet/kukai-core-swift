//
//  TorusClient.swift
//  
//
//  Created by Simon Mcloughlin on 04/07/2022.
//

import Foundation
import KukaiCryptoSwift

public enum TorusAuthProvider: String {
	case apple
	case twitter
	case google
	case reddit
	case facebook
}

public class TorusClient {
	
	public static let mainnetProxyContractAddress = "0xf20336e16B5182637f09821c27BDe29b0AFcfe80"
	public static let testnetProxyContractAddress = "0x6258c9d6c12ed3edda59a1a6527e469517744aa7"
	
	public let urlSession: URLSession
	public let verifiers: [TorusAuthProvider: Verifier]
	
	public init(withSession: URLSession = .shared, verifiers: [TorusAuthProvider: Verifier]) {
		self.urlSession = withSession
		self.verifiers = verifiers
	}
	
	public func keyPair(fromProvider: TorusAuthProvider, completion: @escaping ((Result<KeyPair, KukaiError>) -> Void)) {
		if fromProvider == .apple {
			self.handleNativeApple(completion: completion)
			
		} else {
			self.handleWebBased(completion: completion)
		}
	}
	
	private func handleNativeApple(completion: @escaping ((Result<KeyPair, KukaiError>) -> Void)) {
		
	}
	
	private func handleWebBased(completion: @escaping ((Result<KeyPair, KukaiError>) -> Void)) {
		
	}
	
	
	
	// MARK: - Login
	
	private func handleSingleLogin() {
		
	}
	
	private func handleSignleIdLogin() {
		
	}
	
	private func handleAndAggregateLogin() {
		
	}
	
	private func handleOrAggregateLogin() {
		
	}
}
