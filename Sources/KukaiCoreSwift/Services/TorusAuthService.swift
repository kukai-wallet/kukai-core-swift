//
//  TorusAuthService.swift
//  
//
//  Created by Simon Mcloughlin on 08/07/2021.
//

import Foundation
import UIKit
import TorusSwiftDirectSDK
import FetchNodeDetails
import TorusUtils
import Sodium
import WalletCore
import os.log

public class TorusAuthService {
	
	public enum TorusAuthProvider: String {
		case apple
		case twitter
		case google
		case reddit
		case facebook
	}
	
	public enum TorusAuthError: Error {
		case missingVerifier
		case invalidTorusResponse
		case cryptoError
		case invalidNodeDetails
	}
	
	private let networkType: TezosNodeClientConfig.NetworkType
	private let ethereumNetworkType: EthereumNetwork
	private let testnetVerifiers: [TorusAuthProvider: (verifierName: String, verifier: SubVerifierDetails)]
	private let mainnetVerifiers: [TorusAuthProvider: (verifierName: String, verifier: SubVerifierDetails)]
	private let testnetProxyAddress = "0x4023d2a0D330bF11426B12C6144Cfb96B7fa6183"
	private let mainnetProxyAddress = "0x638646503746d5456209e33a2ff5e3226d698bea"
	private var torus = TorusSwiftDirectSDK(aggregateVerifierType: .singleLogin, aggregateVerifierName: "", subVerifierDetails: [])
	private let torusUtils = TorusUtils()
	private let fetchNodeDetails: FetchNodeDetails
	private var nodeDetails: NodeDetails? = nil
	
	
	
	// need to borrow instructions from: https://docs.tor.us/integration-builder/?b=customauth&lang=iOS&chain=Ethereum
	
	public init(networkType: TezosNodeClientConfig.NetworkType, nativeRedirectURL: String, googleRedirectURL: String, browserRedirectURL: String) {
		self.networkType = networkType
		self.ethereumNetworkType = (networkType == .testnet ? .ROPSTEN : .MAINNET)
		self.fetchNodeDetails = FetchNodeDetails(proxyAddress: (networkType == .testnet ? testnetProxyAddress : mainnetProxyAddress), network: ethereumNetworkType)
		
		testnetVerifiers = [
			.apple: (verifierName: "torus-auth0-apple-lrc", verifier: SubVerifierDetails(
				loginType: .web,
				loginProvider: .apple,
				clientId: "m1Q0gvDfOyZsJCZ3cucSQEe9XMvl9d9L",
				verifierName: "torus-auth0-apple-lrc",
				redirectURL: nativeRedirectURL,
				jwtParams: ["domain": "torus-test.auth0.com"]
			)),
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
		
		torus = TorusSwiftDirectSDK(aggregateVerifierType: .singleLogin, aggregateVerifierName: verifierTuple.verifierName, subVerifierDetails: [verifierTuple.verifier], network: self.ethereumNetworkType, loglevel: .none)
		torus.triggerLogin(controller: displayOver).done { data in
			os_log("Torus returned succesful data", log: .torus, type: .debug)
			
			var username: String? = nil
			var userId: String? = nil
			var profile: String? = nil
			var pk: String? = nil
			
			// Each serach returns required data in a different format. Grab the private key and social profile info needed
			switch authType {
				case .apple:
					if let userInfoDict = data["userInfo"] as? [String: Any] {
						username = userInfoDict["name"] as? String
						userId = userInfoDict["email"] as? String
						profile = userInfoDict["picture"] as? String
					}
					pk = data["privateKey"] as? String
				
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
		guard let verifierTuple = self.networkType == .testnet ? testnetVerifiers[authType] : mainnetVerifiers[authType] else {
			completion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.missingVerifier)))
			return
		}
		
		self.getNodeDetailsOnBackgroundThread { [weak self] in
			guard let nd = self?.nodeDetails else {
				completion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.invalidNodeDetails)))
				return
			}
			
			// TODO: if twitter, get twitter id instead of username
			
			
			self?.torusUtils.getPublicAddress(endpoints: nd.getTorusNodeEndpoints(), torusNodePubs: nd.getTorusNodePub(), verifier: verifierTuple.verifierName, verifierId: socialId, isExtended: true).done { [weak self] data in
				guard let pubX = data["pub_key_X"],
					  let pubY = data["pub_key_Y"],
					  let bytesX = Sodium.shared.utils.hex2bin(pubX),
					  let bytesY = Sodium.shared.utils.hex2bin(pubY) else {
					os_log("Finding address - no valid pub key x and y returned", log: .torus, type: .error)
					completion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.invalidTorusResponse)))
					return
				}
				
				// Compute prefix and pad data to ensure always 32 bytes
				let prefixVal: UInt8 = ((bytesY[bytesY.count - 1] % 2) != 0) ? 3 : 2;
				var pad = [UInt8](repeating: 0, count: 32)
				pad.append(contentsOf: bytesX)
				
				var publicKey = [prefixVal]
				publicKey.append(contentsOf: pad[pad.count-32..<pad.count])
				
				
				// Generate Base58 encoded version of binary data, so we can check for inverted keys
				let pk = Base58.encode(message: publicKey, prefix: Prefix.Keys.Secp256k1.public)
				
				
				// Check results are valid
				if bytesY.count < 32 && prefixVal == 3 && self?.isInvertedPk(pk: pk) == true {
					publicKey = [2]
					publicKey.append(contentsOf: pad[pad.count-32..<pad.count])
				}
				
				
				// Run Blake2b hashing on public key
				guard let hash = Sodium.shared.genericHash.hash(message: publicKey, outputLength: 20) else {
					os_log("Finding address - generating hash failed", log: .torus, type: .error)
					completion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.cryptoError)))
					return
				}
				
				// Create tz2 address and return
				let tz2Address = Base58.encode(message: hash, prefix: Prefix.Address.tz2)
				completion(Result.success(tz2Address))
				
			}.catch { error in
				os_log("Error fetching address: %@", log: .torus, type: .error, "\(error)")
				completion(Result.failure(ErrorResponse.internalApplicationError(error: error)))
				return
			}
		}
	}
	
	private func getNodeDetailsOnBackgroundThread(completion: @escaping (() -> Void)) {
		DispatchQueue.global(qos: .background).async { [weak self] in
			self?.nodeDetails = self?.fetchNodeDetails.getNodeDetails()
			
			DispatchQueue.main.async {
				completion()
			}
		}
	}
	
	private func isInvertedPk(pk: String) -> Bool {
		// Detect keys with flipped sign and correct them.
		let invertedPks = [
		  "sppk7cqh7BbgUMFh4yh95mUwEeg5aBPG1MBK1YHN7b9geyygrUMZByr", // test variable
		  "sppk7bMTva1MwF7cXjrcfoj6XVfcYgjrVaR9JKP3JxvPB121Ji5ftHT",
		  "sppk7bLtXf9CAVZh5jjDACezPnuwHf9CgVoAneNXQFgHknNtCyE5k8A"
		]
		
		return invertedPks.contains(pk);
	}
}
