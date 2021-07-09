//
//  TorusAuthService.swift
//  
//
//  Created by Simon Mcloughlin on 08/07/2021.
//

import Foundation
import UIKit
import TorusSwiftDirectSDK
import os.log

public class TorusAuthService {
	
	public enum TorusAuthProvider: String {
		case twitter
		case google
		case reddit
		case facebook
	}
	
	public enum TorusAuthError: Error {
		case missingVerifier
		case invalidTorusResponse
	}
	
	private let networkType: TezosNodeClientConfig.NetworkType
	private let testnetVerifiers: [TorusAuthProvider: (verifierName: String, verifier: SubVerifierDetails)]
	private let mainnetVerifiers: [TorusAuthProvider: (verifierName: String, verifier: SubVerifierDetails)]
	private var torus = TorusSwiftDirectSDK(aggregateVerifierType: .singleLogin, aggregateVerifierName: "", subVerifierDetails: [])
	
	
	// Sample test torus URLs
	// nativeRedirectURL = "tdsdk://tdsdk/oauthCallback"
	// googleRedirect = "com.googleusercontent.apps.238941746713-vfap8uumijal4ump28p9jd3lbe6onqt4:/oauthredirect",
	// browserRedirect = "https://scripts.toruswallet.io/redirect.html"
	
	// need to borrow instructions from: https://docs.tor.us/integration-builder/?b=customauth&lang=iOS&chain=Ethereum
	
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
	
	public func createWallet(from authType: TorusAuthProvider, displayOver: UIViewController, completion: @escaping ((Result<TorusWallet, ErrorResponse>) -> Void)) {
		guard let verifierTuple = self.networkType == .testnet ? testnetVerifiers[authType] : mainnetVerifiers[authType] else {
			completion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.missingVerifier)))
			return
		}
		
		torus = TorusSwiftDirectSDK(aggregateVerifierType: .singleLogin, aggregateVerifierName: verifierTuple.verifierName, subVerifierDetails: [verifierTuple.verifier], network: .ROPSTEN, loglevel: .none)
		torus.triggerLogin(controller: displayOver).done { data in
			os_log("Torus returned succesful data", log: .torus, type: .debug)
			
			var username: String? = nil
			var userId: String? = nil
			var profile: String? = nil
			var pk: String? = nil
			
			switch authType {
				case .twitter:
					
					if let userInfoDict = data["userInfo"] as? [String: Any] {
						username = userInfoDict["nickname"] as? String
						userId = userInfoDict["sub"] as? String
						profile = userInfoDict["picture"] as? String
					}
					
					pk = data["privateKey"] as? String
					
				case .google:
					print("\n\n\n Unimplemented \nGoogle data: \(data) \n\n\n")
					completion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.invalidTorusResponse)))
					
				case .reddit:
					if let userInfoDict = data["userInfo"] as? [String: Any] {
						username = userInfoDict["name"] as? String
						userId = nil
						profile = userInfoDict["icon_img"] as? String
					}
					
					pk = data["privateKey"] as? String
					
				case .facebook:
					print("\n\n\n Unimplemented \nFacebook data: \(data) \n\n\n")
					completion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.invalidTorusResponse)))
			}
			
			
			// Create wallet with details and return
			guard let privateKeyString = pk, let wallet = TorusWallet(authProvider: .twitter, username: username, userId: userId, profilePicture: profile, torusPrivateKey: privateKeyString) else {
				os_log("Error torus contained no, or invlaid private key", log: .torus, type: .error)
				completion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.invalidTorusResponse)))
				return
			}
			
			completion(Result.success(wallet))
			
		}.catch { error in
			os_log("Error logging in: %@", log: .torus, type: .error, "\(error)")
			completion(Result.failure(ErrorResponse.internalApplicationError(error: error)))
			return
		}
	}
	
	public func getAddress(from authType: TorusAuthProvider, for socialId: String, completion: @escaping ((Result<String, ErrorResponse>) -> Void)) {
		
	}
}
