//
//  TorusAuthService.swift
//  
//
//  Created by Simon Mcloughlin on 08/07/2021.
//

import Foundation
import KukaiCryptoSwift
import Sodium
import UIKit
import CustomAuth
import FetchNodeDetails
import TorusUtils
import JWTDecode
import AuthenticationServices
import os.log



// MARK: - Types

/// List of providers currently supported and available on the Tezos network
public enum TorusAuthProvider: String, Codable {
	case apple
	case google
	case facebook
	case twitter
	case reddit
	case discord
	case twitch
	case line
	case github
	case email
}

/// SDK requires information about the verifer that can't be stored inside the verifier, add a wrapper object to allow passing of all the data
public struct SubverifierWrapper {
	
	/// The name of the aggregated verifier
	public let aggregateVerifierName: String?
	
	/// The type to use
	public let verifierType: verifierTypes
	
	/// Unlike seed based wallets, Torus verifiers are bound to a network and generate different addresses. In order to give the same experience on Tezos, we need to supply the network for each verifier
	public let networkType: TezosNodeClientConfig.NetworkType
	
	/// The matching `SubVerifierDetails` object
	public let subverifier: SubVerifierDetails
	
	/// Helper to check if the current verifier is an aggregate or not
	var isAggregate: Bool {
		get {
			return aggregateVerifierName != nil
		}
	}
	
	/// Create an instance of the object with an option string for the aggregate verifier name, and a `SubVerifierDetails` object
	public init(aggregateVerifierName: String?, verifierType: verifierTypes, networkType: TezosNodeClientConfig.NetworkType, subverifier: SubVerifierDetails) {
		self.aggregateVerifierName = aggregateVerifierName
		self.verifierType = verifierType
		self.networkType = networkType
		self.subverifier = subverifier
	}
}

/// Custom TorusAuthService errors that cna be thrown
public enum TorusAuthError: Error {
	case missingVerifier
	case invalidTorusResponse
	case cryptoError
	case invalidNodeDetails
	case invalidTwitterURL
	case noTwiiterUserIdFound
	case invalidAppleResponse
}



/**
TorusAuthService is a wrapper around the SDK provided by: https://tor.us/ to allow the creation of `TorusWallet`'s.
This allows users to create a wallet from their social media accounts without having to use a seed phrase / mnemonic.
TorusAuthService allows Tezos apps to leverage this service for a number of providers, and also has the ability to query the network for someone else's wallet address,
based on their social profile. This allows you to send XTZ or tokens to your friend based on their twitter username for example
*/
public class TorusAuthService: NSObject {
	
	
	// MARK: - Private properties
	
	/// Shared Network service for a small number of requests
	private let networkService: NetworkService
	
	/// Torus verifier settings used by the app
	private let verifiers: [TorusAuthProvider: SubverifierWrapper]
	
	/// The Ethereum contract address to use on testnet
	private let testnetProxyAddress = "0x4023d2a0D330bF11426B12C6144Cfb96B7fa6183"
	
	/// The Ethereum contract address to use on mainent
	private let mainnetProxyAddress = "0x638646503746d5456209e33a2ff5e3226d698bea"
	
	/// Shared instance of the Torus SDK object, with a temprary init
	private var torus = CustomAuth(web3AuthClientId: "", aggregateVerifierType: .singleLogin, aggregateVerifier: "", subVerifierDetails: [], network: .legacy(.MAINNET))
	
	/// Shared instance of the Torus Util object
	private let torusUtils: TorusUtils
	
	/// Shared instance of the Torus object used for fetching details about the Ethereum node, in order to query it for public tz2 addresses
	private var fetchNodeDetails: NodeDetailManager
	
	/// Apple sign in requires a seperate workflow to rest of torus, need to grab the completion and hold onto it for later
	private var createWalletCompletion: ((Result<TorusWallet, KukaiError>) -> Void) = {_ in}
	
	private let appleIDProvider = ASAuthorizationAppleIDProvider()
	private var request: ASAuthorizationAppleIDRequest? = nil
	private var authorizationController: ASAuthorizationController? = nil
	private let web3AuthClientId: String
	
	
	
	// MARK: - Init
	
	/**
	Setup the TorusAuthService verifiers and networking clients for testnet and mainnet, so they can be queried easier.
	- parameter networkService: A networking service instance used for converting twitter handles into twitter id's
	- parameter verifiers: List of verifiers available to the library for the given app context
	*/
	public init(networkService: NetworkService, verifiers: [TorusAuthProvider: SubverifierWrapper], web3AuthClientId: String) {
		self.networkService = networkService
		self.verifiers = verifiers
		self.web3AuthClientId = web3AuthClientId
		
		self.fetchNodeDetails = NodeDetailManager(network: .legacy(.MAINNET), urlSession: networkService.urlSession)
		self.torusUtils = TorusUtils(loglevel: .error, urlSession: networkService.urlSession, clientId: web3AuthClientId)
	}
	
	
	
	// MARK: - Public functions
	
	/**
	Create a `TorusWallet` insteace from a social media provider
	- parameter from: The `TorusAuthProvider` that you want to invoke
	- parameter displayOver: The `UIViewController` that the webpage will display on top of
	- parameter mockedTorus: To avoid issues attempting to stub aspects of the Torus SDK, a mocked version of the SDK can be supplied instead
	- parameter completion: The callback returned when all the networking and cryptography is complete
	*/
	public func createWallet(from authType: TorusAuthProvider, displayOver: UIViewController?, mockedTorus: CustomAuth? = nil, completion: @escaping ((Result<TorusWallet, KukaiError>) -> Void)) {
		guard let verifierWrapper = verifiers[authType] else {
			completion(Result.failure(KukaiError.internalApplicationError(error: TorusAuthError.missingVerifier)))
			return
		}
		
		if let mockTorus = mockedTorus {
			torus = mockTorus
			
		} else {
			torus = CustomAuth(web3AuthClientId: web3AuthClientId, 
							   aggregateVerifierType: verifierWrapper.verifierType,
							   aggregateVerifier: verifierWrapper.aggregateVerifierName ?? verifierWrapper.subverifier.verifier,
							   subVerifierDetails: [verifierWrapper.subverifier],
							   network: verifierWrapper.networkType == .testnet ? .legacy(.TESTNET) : .legacy(.MAINNET),
							   loglevel: .error,
							   urlSession: self.networkService.urlSession,
							   networkUrl: verifierWrapper.networkType == .testnet ? "https://www.ankr.com/rpc/eth/eth_goerli" : nil)
		}

		
		
		// If requesting a wallet from apple, call apple sign in code and skip rest of function
		guard authType != .apple else {
			createWalletCompletion = completion
			
			request = appleIDProvider.createRequest()
			request?.requestedScopes = [.fullName, .email]
			
			guard let req = request else {
				createWalletCompletion(Result.failure(KukaiError.unknown()))
				return
			}
			
			authorizationController = ASAuthorizationController(authorizationRequests: [req])
			authorizationController?.delegate = self
			authorizationController?.presentationContextProvider = self
			authorizationController?.performRequests()
			
			return
		}
		
		// If not apple call torus code
		triggerLogin(torus: torus, authType: authType, completion: completion)
	}
	
	private func triggerLogin(torus: CustomAuth, authType: TorusAuthProvider, completion: @escaping ((Result<TorusWallet, KukaiError>) -> Void)) {
		Task { @MainActor in
			do {
				let data = try await torus.triggerLogin()
				Logger.torus.info("Torus returned succesful data")
				
				var username: String? = nil
				var userId: String? = nil
				var profile: String? = nil
				var pk: String? = nil
				
				// Each serach returns required data in a different format. Grab the private key and social profile info needed
				switch authType {
					case .apple, .google:
						if let userInfo = data.userInfo["userInfo"] as? [String: Any] {
							username = userInfo["name"] as? String
							userId = userInfo["email"] as? String
							profile = userInfo["picture"] as? String
						}
						pk = data.torusKey.finalKeyData?.privKey
						
					case .twitter:
						if let userInfo = data.userInfo["userInfo"] as? [String: Any] {
							username = userInfo["nickname"] as? String
							userId = userInfo["sub"] as? String
							profile = userInfo["picture"] as? String
						}
						pk = data.torusKey.finalKeyData?.privKey
						
					case .reddit:
						if let userInfo = data.userInfo["userInfo"] as? [String: Any] {
							username = userInfo["name"] as? String
							userId = nil
							profile = userInfo["icon_img"] as? String
						}
						pk = data.torusKey.finalKeyData?.privKey
						
					case .facebook:
						if let userInfo = data.userInfo["userInfo"] as? [String: Any] {
							username = userInfo["name"] as? String
							userId = userInfo["id"] as? String
							profile = ((userInfo["picture"] as? [String: Any])?["data"] as? [String: Any])?["url"] as? String
						}
						pk = data.torusKey.finalKeyData?.privKey
						
					case .email:
						if let userInfo = data.userInfo["userInfo"] as? [String: Any] {
							username = userInfo["email"] as? String
							userId = userInfo["email"] as? String
							profile = userInfo["picture"] as? String
						}
						pk = data.torusKey.finalKeyData?.privKey
						
					default:
						completion(Result.failure(KukaiError.internalApplicationError(error: TorusAuthError.missingVerifier)))
				}
				
				
				// Twitter API doesn't give us the bloody "@" handle for some reason. Fetch that first and overwrite the username property with the handle, if found
				if authType == .twitter {
					twitterHandleLookup(id: userId ?? "") { [weak self] result in
						switch result {
							case .success(let actualUsername):
								self?.createTorusWalletAndContinue(pk: pk, authType: authType, username: actualUsername, userId: userId, profile: profile, completion: completion)
								
							case .failure(_):
								self?.createTorusWalletAndContinue(pk: pk, authType: authType, username: username, userId: userId, profile: profile, completion: completion)
						}
					}
					
				} else {
					createTorusWalletAndContinue(pk: pk, authType: authType, username: username, userId: userId, profile: profile, completion: completion)
				}
				
			} catch {
				Logger.torus.error("Error logging in: \(error)")
				completion(Result.failure(KukaiError.internalApplicationError(error: error)))
				return
			}
		}
	}
	
	private func createTorusWalletAndContinue(pk: String?, authType: TorusAuthProvider, username: String?, userId: String?, profile: String?, completion: @escaping ((Result<TorusWallet, KukaiError>) -> Void)) {
		guard let privateKeyString = pk, let wallet = TorusWallet(authProvider: authType, username: username, userId: userId, profilePicture: profile, torusPrivateKey: privateKeyString) else {
			Logger.torus.error("Error torus contained no, or invlaid private key")
			completion(Result.failure(KukaiError.internalApplicationError(error: TorusAuthError.invalidTorusResponse)))
			return
		}
		
		completion(Result.success(wallet))
	}
	
	
	
	
	/**
	Get a TZ2 address from a social media user name. If Twitter, will first convert the username to a userid and then query
	- parameter from: The `TorusAuthProvider` that you want to invoke
	- parameter for: The social media username to search for
	- parameter completion: The callback returned when all the networking and cryptography is complete
	*/
	public func getAddress(from authType: TorusAuthProvider, for socialUsername: String, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		guard let verifierWrapper = verifiers[authType] else {
			completion(Result.failure(KukaiError.internalApplicationError(error: TorusAuthError.missingVerifier)))
			return
		}
		
		if authType == .twitter {
			twitterAddressLookup(username: socialUsername) { [weak self] twitterResult in
				switch twitterResult {
					case .success(let twitterUserId):
						self?.getPublicAddress(verifierName: verifierWrapper.aggregateVerifierName ?? verifierWrapper.subverifier.clientId, verifierWrapper: verifierWrapper, socialUserId: "twitter|\(twitterUserId)", completion: completion)
						
					case .failure(let twitterError):
						completion(Result.failure(twitterError))
				}
			}
		} else {
			getPublicAddress(verifierName: verifierWrapper.aggregateVerifierName ?? verifierWrapper.subverifier.clientId, verifierWrapper: verifierWrapper, socialUserId: socialUsername, completion: completion)
		}
	}
	
	/// Private wrapper to avoid duplication in the previous function
	private func getPublicAddress(verifierName: String, verifierWrapper: SubverifierWrapper, socialUserId: String, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		let isTestnet = (verifierWrapper.networkType == .testnet)
		self.fetchNodeDetails = NodeDetailManager(network: (isTestnet ? .legacy(.TESTNET) : .legacy(.MAINNET)), urlSession: networkService.urlSession)
		
		Task {
			do {
				let remoteNodeDetails = try await self.fetchNodeDetails.getNodeDetails(verifier: verifierName, verifierID: socialUserId)
				let data = try await self.torusUtils.getPublicAddress(endpoints: remoteNodeDetails.getTorusNodeEndpoints(), torusNodePubs: remoteNodeDetails.getTorusNodePub(), verifier: verifierName, verifierId: socialUserId)
				let pubX = data.finalKeyData?.X.padLeft(toLength: 64, withPad: "0")
				let pubY = data.finalKeyData?.Y.padLeft(toLength: 64, withPad: "0")
				
				guard let x = pubX,
					  let y = pubY,
					  let bytesX = Sodium.shared.utils.hex2bin(x),
					  let bytesY = Sodium.shared.utils.hex2bin(y) else {
					Logger.torus.error("Finding address - no valid pub key x and y returned")
					DispatchQueue.main.async { completion(Result.failure(KukaiError.internalApplicationError(error: TorusAuthError.invalidTorusResponse))) }
					return
				}
				
				// Compute prefix and pad data to ensure always 32 bytes
				let prefixVal: UInt8 = ((bytesY[bytesY.count - 1] % 2) != 0) ? 3 : 2;
				var pad = [UInt8](repeating: 0, count: 32)
				pad.append(contentsOf: bytesX)
				
				var publicKey = [prefixVal]
				publicKey.append(contentsOf: pad[pad.count-32..<pad.count])
				
				
				// Run Blake2b hashing on public key
				guard let hash = Sodium.shared.genericHash.hash(message: publicKey, outputLength: 20) else {
					Logger.torus.error("Finding address - generating hash failed")
					DispatchQueue.main.async { completion(Result.failure(KukaiError.internalApplicationError(error: TorusAuthError.cryptoError))) }
					return
				}
				
				// Create tz2 address and return
				let tz2Address = Base58Check.encode(message: hash, prefix: Prefix.Address.tz2)
				DispatchQueue.main.async { completion(Result.success(tz2Address)) }
				
			} catch {
				Logger.torus.error("Error logging in: \(error)")
				DispatchQueue.main.async { completion(Result.failure(KukaiError.internalApplicationError(error: error))) }
				return
			}
		}
	}
	
	/**
	 Take in a Twitter id and fetch the Twitter username instead.
	 - parameter id: The users ID. Can contain a prefix of "twitter|" or not
	 - parameter completion: The callback fired when the username has been found
	 */
	public func twitterHandleLookup(id: String, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		guard let url = URL(string: "https://backend.kukai.network/twitter-lookup") else {
			completion(Result.failure(KukaiError.unknown(withString: "Unable to setup request to kukai twitter service")))
			return
		}
		let sanitisedId = id.replacingOccurrences(of: "twitter|", with: "")
		let data = "{ \"id\": \"\(sanitisedId)\"}".data(using: .utf8)
		networkService.request(url: url, isPOST: true, withBody: data, forReturnType: [String: String].self) { result in
			switch result {
				case .success(let dict):
					if let username = dict["username"] {
						completion(Result.success("@\(username)"))
					} else {
						completion(Result.failure(KukaiError.internalApplicationError(error: TorusAuthError.noTwiiterUserIdFound)))
					}
					
				case .failure(let error):
					completion(Result.failure(error))
			}
		}
	}
	
	/**
	 Take in a Twitter username and fetch the Twitter userId instead.
	 - parameter username: The users username. Can contain an `@` symbol, but will be stripped out by the code as its not required
	 - parameter completion: The callback fired when the userId has been found
	 */
	public func twitterAddressLookup(username: String, completion: @escaping ((Result<String, KukaiError>) -> Void)) {
		guard let url = URL(string: "https://backend.kukai.network/twitter-lookup") else {
			completion(Result.failure(KukaiError.internalApplicationError(error: TorusAuthError.invalidTwitterURL)))
			return
		}
		
		let sanitizedUsername = username.replacingOccurrences(of: "@", with: "")
		let data = "{\"username\": \"\(sanitizedUsername)\"}".data(using: .utf8)
		networkService.request(url: url, isPOST: true, withBody: data, forReturnType: [String: String].self) { result in
			switch result {
				case .success(let dict):
					if let id = dict["id"] {
						completion(Result.success(id))
					} else {
						completion(Result.failure(KukaiError.internalApplicationError(error: TorusAuthError.noTwiiterUserIdFound)))
					}
					
				case .failure(let error):
					completion(Result.failure(error))
			}
		}
	}
}

extension TorusAuthService: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
	
	public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
		return UIApplication.shared.keyWindow ?? UIWindow()
	}
	
	public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
		guard let error = error as? ASAuthorizationError else {
			return
		}
		
		createWalletCompletion(Result.failure(KukaiError.internalApplicationError(error: error)))
	}
	
	public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
		switch authorization.credential {
			case let appleIDCredential as ASAuthorizationAppleIDCredential:
				
				guard let verifierWrapper = verifiers[.apple] else {
					createWalletCompletion(Result.failure(KukaiError.internalApplicationError(error: TorusAuthError.missingVerifier)))
					return
				}
				
				guard let identityToken = appleIDCredential.identityToken, let token = String(data: identityToken, encoding: .utf8), let JWT = try? JWTDecode.decode(jwt: token) else {
					createWalletCompletion(Result.failure(KukaiError.internalApplicationError(error: TorusAuthError.invalidAppleResponse)))
					return
				}
				
				let userIdentifier = appleIDCredential.user
				let displayName = appleIDCredential.fullName?.formatted()
				let claim = JWT.claim(name: "sub")
				let sub = claim.string ?? ""
				
				let tdsdk = CustomAuth(web3AuthClientId: web3AuthClientId,
									   aggregateVerifierType: verifierWrapper.verifierType,
									   aggregateVerifier: verifierWrapper.aggregateVerifierName ?? verifierWrapper.subverifier.verifier,
									   subVerifierDetails: [verifierWrapper.subverifier],
									   network: verifierWrapper.networkType == .testnet ? .legacy(.TESTNET) : .legacy(.MAINNET),
									   loglevel: .error,
									   urlSession: self.networkService.urlSession,
									   networkUrl: verifierWrapper.networkType == .testnet ? "https://www.ankr.com/rpc/eth/eth_goerli" : nil)
				
				Task { @MainActor in
					do {
						let data = try await tdsdk.getAggregateTorusKey(verifier: verifierWrapper.aggregateVerifierName ?? "", verifierId: sub, idToken: token, subVerifierDetails: verifierWrapper.subverifier)
						
						guard let privateKeyString = data.finalKeyData?.privKey, let wallet = TorusWallet(authProvider: .apple, username: displayName, userId: userIdentifier, profilePicture: nil, torusPrivateKey: privateKeyString) else {
							Logger.torus.error("Error torus contained no, or invlaid private key")
							self.createWalletCompletion(Result.failure(KukaiError.internalApplicationError(error: TorusAuthError.invalidTorusResponse)))
							return
						}
						
						self.createWalletCompletion(Result.success(wallet))
						
					} catch {
						self.createWalletCompletion(Result.failure(KukaiError.internalApplicationError(error: error)))
					}
				}
				
				
			default:
				break
		}
	}
}
