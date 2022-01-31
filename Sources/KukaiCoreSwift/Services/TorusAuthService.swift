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
import JWTDecode
import AuthenticationServices
import os.log



// MARK: - Types

/// List of providers currently supported and available on the Tezos network
public enum TorusAuthProvider: String {
	case apple
	case twitter
	case google
	case reddit
	case facebook
}

/// SDK requires information about the verifer that can't be stored inside the verifier, add a wrapper object to allow passing of all the data
public struct SubverifierWrapper {
	public let aggregateVerifierName: String?
	public let subverifier: SubVerifierDetails
	
	var isAggregate: Bool {
		get {
			return aggregateVerifierName != nil
		}
	}
	
	public init(aggregateVerifierName: String?, subverifier: SubVerifierDetails) {
		self.aggregateVerifierName = aggregateVerifierName
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
	
	/// Tezos mainnet or testnet
	private let networkType: TezosNodeClientConfig.NetworkType
	
	/// Shared Network service for a small number of requests
	private let networkSerice: NetworkService
	
	/// Torus relies on the Ethereum network for smart contracts. Need to specify which network it uses
	private let ethereumNetworkType: EthereumNetwork
	
	/// Torus verifier settings used on Testnet
	private let testnetVerifiers: [TorusAuthProvider: SubverifierWrapper]
	
	/// Torus verifier settings used on mainnet
	private let mainnetVerifiers: [TorusAuthProvider: SubverifierWrapper]
	
	/// The Ethereum contract address to use on testnet
	private let testnetProxyAddress = "0x4023d2a0D330bF11426B12C6144Cfb96B7fa6183"
	
	/// The Ethereum contract address to use on mainent
	private let mainnetProxyAddress = "0x638646503746d5456209e33a2ff5e3226d698bea"
	
	/// Shared instance of the Torus SDK object, with a temprary init
	private var torus = TorusSwiftDirectSDK(aggregateVerifierType: .singleLogin, aggregateVerifierName: "", subVerifierDetails: [])
	
	/// Shared instance of the Torus Util object
	private let torusUtils: TorusUtils
	
	/// Shared instance of the Torus object used for fetching details about the Ethereum node, in order to query it for public tz2 addresses
	private let fetchNodeDetails: FetchNodeDetails
	
	/// Stored copy of the Torus NodeDetails object. The fetching of this is forced onto the main thread, blocking the UI. Need to push it onto a background thread and store it for other code to access
	private var nodeDetails: AllNodeDetails? = nil
	
	/// Apple sign in requires a seperate workflow to rest of torus, need to grab the completion and hold onto it for later
	private var createWalletCompletion: ((Result<TorusWallet, ErrorResponse>) -> Void) = {_ in}
	
	private let appleIDProvider = ASAuthorizationAppleIDProvider()
	private var request: ASAuthorizationAppleIDRequest? = nil
	private var authorizationController: ASAuthorizationController? = nil
	
	
	
	// MARK: - Init
	
	/**
	Setup the TorusAuthService verifiers and networking clients for testnet and mainnet, so they can be queried easier.
	- parameter networkType: Testnet or mainnet
	- parameter networkService: A networking service instance used for converting twitter handles into twitter id's
	- parameter nativeRedirectURL: The callback URL fired to reopen your native app, after the social handshake has been completed. Must register the URL scheme with your application before it will work. See: https://docs.tor.us/integration-builder/?b=customauth&lang=iOS&chain=Ethereum
	- parameter googleRedirectURL: Google works differently and requires that you redirect to a google cloud app, which in turn will redirect to the native app. If using Google auth you must supply a valid URL or else it won't function
	- parameter browserRedirectURL: Some services can't return to the native app directly, but instead must go to an intermediary webpage that in turn redirects. This page must be created by you and the URL passed in here
	*/
	public init(networkType: TezosNodeClientConfig.NetworkType, networkService: NetworkService, testnetVerifiers: [TorusAuthProvider: SubverifierWrapper], mainnetVerifiers: [TorusAuthProvider: SubverifierWrapper],
				utils: TorusUtils = TorusUtils(), 			// TODO: workaround as Torus SDK's have no ability to mock anything, or pass anything in
				fetchNodeDetails: FetchNodeDetails? = nil) 	// TODO: workaround as Torus SDK's have no ability to mock anything, or pass anything in
	{
		self.networkType = networkType
		self.networkSerice = networkService
		self.ethereumNetworkType = (networkType == .testnet ? .ROPSTEN : .MAINNET)
		self.torusUtils = utils
		self.testnetVerifiers = testnetVerifiers
		self.mainnetVerifiers = mainnetVerifiers
		
		// TODO: remove when Torus SDK fixed
		if let fetch = fetchNodeDetails {
			self.fetchNodeDetails = fetch
		} else {
			self.fetchNodeDetails = FetchNodeDetails(proxyAddress: (networkType == .testnet ? testnetProxyAddress : mainnetProxyAddress), network: ethereumNetworkType)
		}
	}
	
	
	
	// MARK: - Public functions
	
	/**
	Create a `TorusWallet` insteace from a social media provider
	- parameter from: The `TorusAuthProvider` that you want to invoke
	- parameter displayOver: The `UIViewController` that the webpage will display on top of
	- parameter completion: The callback returned when all the networking and cryptography is complete
	*/
	public func createWallet(from authType: TorusAuthProvider, displayOver: UIViewController?, mockedTorus: TorusSwiftDirectSDK? = nil, completion: @escaping ((Result<TorusWallet, ErrorResponse>) -> Void)) {
		guard let verifierWrapper = self.networkType == .testnet ? testnetVerifiers[authType] : mainnetVerifiers[authType] else {
			completion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.missingVerifier)))
			return
		}
		
		// TODO: remove when Torus SDK fixed
		if let mockTorus = mockedTorus {
			torus = mockTorus
			
		} else if verifierWrapper.isAggregate {
			torus = TorusSwiftDirectSDK(
				aggregateVerifierType: .singleIdVerifier,
				aggregateVerifierName: verifierWrapper.aggregateVerifierName ?? "",
				subVerifierDetails: [verifierWrapper.subverifier],
				factory: TDSDKFactory(),
				network: self.ethereumNetworkType,
				loglevel: .info
			)
		} else {
			torus = TorusSwiftDirectSDK(
				aggregateVerifierType: .singleLogin,
				aggregateVerifierName: verifierWrapper.subverifier.subVerifierId,
				subVerifierDetails: [verifierWrapper.subverifier],
				factory: TDSDKFactory(),
				network: self.ethereumNetworkType,
				loglevel: .info
			)
		}
		
		
		// If requesting a wallet from apple, call apple sign in code and skip rest of function
		guard authType != .apple else {
			createWalletCompletion = completion
			
			request = appleIDProvider.createRequest()
			request?.requestedScopes = [.fullName, .email]
			
			guard let req = request else {
				createWalletCompletion(Result.failure(ErrorResponse.unknownError()))
				return
			}
			
			authorizationController = ASAuthorizationController(authorizationRequests: [req])
			authorizationController?.delegate = self
			authorizationController?.presentationContextProvider = self
			authorizationController?.performRequests()
			
			return
		}
		
		
		// If not apple call torus code
		torus.triggerLogin(controller: displayOver).done { data in
			os_log("Torus returned succesful data", log: .torus, type: .debug)
			
			var username: String? = nil
			var userId: String? = nil
			var profile: String? = nil
			var pk: String? = nil
			
			// Each serach returns required data in a different format. Grab the private key and social profile info needed
			switch authType {
				case .apple, .google:
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
			guard let privateKeyString = pk, let wallet = TorusWallet(authProvider: authType, username: username, userId: userId, profilePicture: profile, torusPrivateKey: privateKeyString) else {
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
	
	/**
	Get a TZ2 address from a social media user name. If Twitter, will first convert the username to a userid and then query
	- parameter from: The `TorusAuthProvider` that you want to invoke
	- parameter for: The social media username to search for
	- parameter completion: The callback returned when all the networking and cryptography is complete
	*/
	public func getAddress(from authType: TorusAuthProvider, for socialUsername: String, completion: @escaping ((Result<String, ErrorResponse>) -> Void)) {
		guard let verifierWrapper = self.networkType == .testnet ? testnetVerifiers[authType] : mainnetVerifiers[authType] else {
			completion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.missingVerifier)))
			return
		}
		
		self.fetchNodeDetails.getAllNodeDetails().done { [weak self] allNodeDetails in
			self?.nodeDetails = allNodeDetails
			
			guard let nd = self?.nodeDetails else {
				completion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.invalidNodeDetails)))
				return
			}
			
			if authType == .twitter {
				self?.twitterLookup(username: socialUsername) { [weak self] twitterResult in
					switch twitterResult {
						case .success(let twitterUserId):
							self?.getPublicAddress(nodeDetails: nd, verifierName: verifierWrapper.subverifier.subVerifierId, socialUserId: "twitter|\(twitterUserId)", completion: completion)
							
						case .failure(let twitterError):
							completion(Result.failure(twitterError))
					}
				}
			} else {
				self?.getPublicAddress(nodeDetails: nd, verifierName: verifierWrapper.subverifier.subVerifierId, socialUserId: socialUsername, completion: completion)
			}
		}.catch { error in
			os_log("Error logging in: %@", log: .torus, type: .error, "\(error)")
			completion(Result.failure(ErrorResponse.internalApplicationError(error: error)))
			return
		}
	}
	
	/// Private wrapper to avoid duplication in the previous function
	private func getPublicAddress(nodeDetails: AllNodeDetails, verifierName: String, socialUserId: String, completion: @escaping ((Result<String, ErrorResponse>) -> Void)) {
		self.torusUtils.getPublicAddress(endpoints: nodeDetails.getTorusNodeEndpoints(), torusNodePubs: nodeDetails.getTorusNodePub(), verifier: verifierName, verifierId: socialUserId, isExtended: true).done { [weak self] data in
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
	
	/**
	Take in a Twitter username and fetch the Twitter userId instead.
	- parameter username: The users username. Can contain an `@` symbol, but will be stripped out by the code as its not required
	- parameter completion: The callback fired when the userId has been found
	*/
	public func twitterLookup(username: String, completion: @escaping ((Result<String, ErrorResponse>) -> Void)) {
		let sanitizedUsername = username.replacingOccurrences(of: "@", with: "")
		
		guard let url = URL(string: "https://api.tezos.help/twitter-lookup/") else {
			completion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.invalidTwitterURL)))
			return
		}
		
		let data = "{\"username\": \"\(sanitizedUsername)\"}".data(using: .utf8)
		networkSerice.request(url: url, isPOST: true, withBody: data, forReturnType: [String: String].self) { result in
			switch result {
				case .success(let dict):
					if let id = dict["id"] {
						completion(Result.success(id))
					} else {
						completion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.noTwiiterUserIdFound)))
					}
					
				case .failure(let error):
					completion(Result.failure(error))
			}
		}
	}
	
	/// Its possible for private keys to be returned inverted. This function provides a quick sanity check, so the key can be flipped if necessary
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

extension TorusAuthService: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
	
	public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
		return UIApplication.shared.keyWindow ?? UIWindow()
	}
	
	public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
		guard let error = error as? ASAuthorizationError else {
			return
		}
		
		createWalletCompletion(Result.failure(ErrorResponse.error(string: "Request failed: \(error.code)", errorType: .unknownError)))
	}
	
	public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
		switch authorization.credential {
			case let appleIDCredential as ASAuthorizationAppleIDCredential:
				
				guard let verifierWrapper = self.networkType == .testnet ? testnetVerifiers[.apple] : mainnetVerifiers[.apple] else {
					createWalletCompletion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.missingVerifier)))
					return
				}
				
				guard let identityToken = appleIDCredential.identityToken, let token = String(data: identityToken, encoding: .utf8), let JWT = try? JWTDecode.decode(jwt: token) else {
					createWalletCompletion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.invalidAppleResponse)))
					return
				}
				
				let userIdentifier = appleIDCredential.user
				let displayName = appleIDCredential.fullName?.formatted()
				let claim = JWT.claim(name: "sub")
				let sub = "apple|" + claim.string
				
				let tdsdk = TorusSwiftDirectSDK(aggregateVerifierType: .singleLogin, aggregateVerifierName: verifierWrapper.aggregateVerifierName ?? "", subVerifierDetails: [], network: ethereumNetworkType, loglevel: .info)
				tdsdk.getAggregateTorusKey(verifier: verifierWrapper.aggregateVerifierName ?? "", verifierId: sub ?? "", idToken: token, subVerifierDetails: verifierWrapper.subverifier).done { [weak self] data in
					
					guard let privateKeyString = data["privateKey"] as? String, let wallet = TorusWallet(authProvider: .apple, username: displayName, userId: userIdentifier, profilePicture: nil, torusPrivateKey: privateKeyString) else {
						os_log("Error torus contained no, or invlaid private key", log: .torus, type: .error)
						self?.createWalletCompletion(Result.failure(ErrorResponse.internalApplicationError(error: TorusAuthError.invalidTorusResponse)))
						return
					}
					
					self?.createWalletCompletion(Result.success(wallet))
					
				}.catch { [weak self] error in
					self?.createWalletCompletion(Result.failure(ErrorResponse.internalApplicationError(error: error)))
				}
				
			default:
				break
		}
	}
}
