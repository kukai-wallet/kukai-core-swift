//
//  TorusWallet.swift
//  
//
//  Created by Simon Mcloughlin on 08/07/2021.
//

import Foundation
import KukaiCryptoSwift
import Sodium
import os.log

/**
A Tezos Wallet used for signing transactions before sending to the Tezos network. This object holds the public and private key used to create the contained Tezos address.
You should **NOT** store a copy of this class in a singleton or gloabl variable of any kind. it should be created as needed and nil'd when not.
In order to help developers achieve this, use the `WalletCacheService` to store/retreive an encrypted copy of the wallet on disk, and recreate the `Wallet`.

This wallet is a subclass of `LinearWallet` created by using the Torus network to generate wallets from social media accounts.
This class is equivalent to a LinearWallet producing a TZ2 address via secp256k1, without the use of a mnemonic, and instead including the social profile of the user.
*/
public class TorusWallet: RegularWallet {
	
	// MARK: - Properties
	
	/// The type of service used to generate the provide key
	public let authProvider: TorusAuthProvider
	
	/// The raw social media username displayed on the users account. In the case of Twitter, it will not be prefix with an `@`
	public let socialUsername: String?
	
	/// The unique id the social media platform has assigned to the users account. Used for querying account details
	public let socialUserId: String?
	
	/// A URL to the users profile picture on the given social meida platform
	public let socialProfilePictureURL: URL?
	
	
	
	// MARK: - Init
	
	/**
	Create an instace of the wallet from the data provided by the Torus network, using `TorusAuthService`
	- parameter authProvider: The supported provider used to create the private key
	- parameter username: Optional, the users social profile username
	- parameter userId: Optional, the users social profile unique id
	- parameter profilePicture: Optional, the users social profile display image
	- parameter torusPrivateKey: The hex encoded private key from the Torus network
	*/
	public init?(authProvider: TorusAuthProvider, username: String?, userId: String?, profilePicture: String?, torusPrivateKey: String) {
		guard let bytes = Sodium.shared.utils.hex2bin(torusPrivateKey) else {
			os_log("Unable to convert hex to binary", log: .torus, type: .error)
			return nil
		}
		
		let base58encode = Base58Check.encode(message: bytes, prefix: Prefix.Keys.Secp256k1.secret)
		
		self.authProvider = authProvider
		self.socialUsername = username
		self.socialUserId = userId
		self.socialProfilePictureURL = URL(string: profilePicture ?? "")
		
		super.init(withBase58String: base58encode, ellipticalCurve: .secp256k1, type: .social)
	}
	
	
	
	// MARK: - Codable
	
	/// Codable coding keys
	enum CodingKeys: String, CodingKey {
		case authProvider
		case socialUsername
		case socialUserId
		case socialProfilePictureURL
	}
	
	/// Decodable init
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let authProviderString = try container.decode(String.self, forKey: .authProvider)
		authProvider = TorusAuthProvider(rawValue: authProviderString) ?? .twitter
		socialUsername = try container.decodeIfPresent(String.self, forKey: .socialUsername)
		socialUserId = try container.decodeIfPresent(String.self, forKey: .socialUserId)
		socialProfilePictureURL = try container.decodeIfPresent(URL.self, forKey: .socialProfilePictureURL)
		
		try super.init(from: decoder)
	}
	
	/// Encodable encode func
	public override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(authProvider.rawValue, forKey: .authProvider)
		try container.encode(socialUsername, forKey: .socialUsername)
		try container.encode(socialUserId, forKey: .socialUserId)
		try container.encode(socialProfilePictureURL, forKey: .socialProfilePictureURL)
		
		try super.encode(to: encoder)
	}
}
