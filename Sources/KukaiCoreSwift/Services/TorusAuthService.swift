//
//  TorusAuthService.swift
//  
//
//  Created by Simon Mcloughlin on 08/07/2021.
//

import Foundation
import UIKit
import TorusSwiftDirectSDK

public class TorusAuthService {
	
	public enum TorusAuthProvider: String {
		case twitter
		case google
		case reddit
		case facebook
	}
	
	public enum TorusAuthError: Error {
		case missingVerifier
	}
	
	private let networkType: TezosNodeClientConfig.NetworkType
	private let testnetVerifiers: [TorusAuthProvider: (verifierName: String verifier: SubVerifierDetails)]
	private let mainnetVerifiers: [TorusAuthProvider: (verifierName: String verifier: SubVerifierDetails)]
	private var torus = TorusSwiftDirectSDK(aggregateVerifierType: .singleLogin, aggregateVerifierName: "", subVerifierDetails: [])
	
	
	// Sample test torus URLs
	// nativeRedirectURL = "tdsdk://tdsdk/oauthCallback"
	// googleRedirect = "com.googleusercontent.apps.238941746713-vfap8uumijal4ump28p9jd3lbe6onqt4:/oauthredirect",
	// browserRedirect = "https://scripts.toruswallet.io/redirect.html"
	
	
	public init(networkType: TezosNodeClientConfig.NetworkType, nativeRedirectURL: String, googleRedirectURL: String, browserRedirectURL: String) {
		self.networkType = networkType
		
		testnetVerifiers = [
			.twitter: (verifierName: "torus-auth0-twitter-lrc", verifier: SubVerifierDetails(
				loginType: .web,
				loginProvider: .twitter,
				clientId: "A7H8kkcmyFRlusJQ9dZiqBLraG2yWIsO",
				verifierName: "torus-auth0-twitter-lrc",
				redirectURL: nativeRedirectURL,
				jwtParams: ["domain": "torus-test.auth0.com"]
			)),
			.google: (verifierName: "google-lrc", SubVerifierDetails(
				loginType: .web,
				loginProvider: .google,
				clientId: "221898609709-obfn3p63741l5333093430j3qeiinaa8.apps.googleusercontent.com",
				verifierName: "google-lrc",
				redirectURL: googleRedirectURL,
				browserRedirectURL: browserRedirectURL
			)),
			.reddit: (verifierName: "reddit-shubs", SubVerifierDetails(
				loginType: .web,
				loginProvider: .reddit,
				clientId: "rXIp6g2y3h1wqg",
				verifierName: "reddit-shubs",
				redirectURL: nativeRedirectURL
			)),
			.facebook: (verifierName: "facebook-shubs", SubVerifierDetails(
				loginType: .web,
				loginProvider: .facebook,
				clientId: "659561074900150",
				verifierName: "facebook-shubs",
				redirectURL: nativeRedirectURL,
				browserRedirectURL: browserRedirectURL
			))
		]
		
		// Doesn't exist yet
		mainnetVerifiers = testnetVerifiers
	}
	
	public func createWallet(from authType: TorusAuthProvider, displayOver: UIViewController, completion: @escaping ((Result<Wallet, ErrorResponse>) -> Void)) {
		guard let verifierTuple = self.networkType == .testnet ? testnetVerifiers[authType] : mainnetVerifiers[authType] else {
			completion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.missingVerifier)))
			return
		}
		
		torus = TorusSwiftDirectSDK(aggregateVerifierType: .singleLogin, aggregateVerifierName: verifierTuple.verifierName, subVerifierDetails: [verifierTuple.verifier], network: .ROPSTEN, loglevel: .debug)
		torus.triggerLogin(controller: displayOver).done { data in
			
			print("\n\n\n Data: \(data) \n\n\n")
		}
	}
	
	public func getAddress(from authType: TorusAuthProvider, for socialId: String, completion: @escaping ((Result<String, ErrorResponse>) -> Void)) {
		
	}
}
