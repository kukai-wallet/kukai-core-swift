//
//  TorusWallet.swift
//  
//
//  Created by Simon Mcloughlin on 08/07/2021.
//

import Foundation
import Sodium
import WalletCore
import os.log


public class TorusWallet: LinearWallet {
	
	// MARK: - Properties
	
	public let authProvider: TorusAuthService.TorusAuthProvider
	
	public let socialUsername: String?
	
	public let socialUserId: String?
	
	public let socialProfilePictureURL: URL?
	
	public init?(authProvider: TorusAuthService.TorusAuthProvider, username: String?, userId: String?, profilePicture: String?, torusPrivateKey: String) {
		guard let bytes = Sodium.shared.utils.hex2bin(torusPrivateKey) else {
			os_log("Unable to convert hex to binary", log: .torus, type: .error)
			return nil
		}
		
		let base58encode = Base58.encode(message: bytes, prefix: Prefix.Keys.Secp256k1.secret)
		
		self.authProvider = authProvider
		self.socialUsername = username
		self.socialUserId = userId
		self.socialProfilePictureURL = URL(string: profilePicture ?? "")
		
		super.init(withPrivateKey: base58encode, ellipticalCurve: .secp256k1, type: .torus)
	}
	
	
	
	enum CodingKeys: String, CodingKey {
		case authProvider
		case socialUsername
		case socialUserId
		case socialProfilePictureURL
	}
	
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let authProviderString = try container.decode(String.self, forKey: .authProvider)
		authProvider = TorusAuthService.TorusAuthProvider(rawValue: authProviderString) ?? .twitter
		socialUsername = try container.decodeIfPresent(String.self, forKey: .socialUsername)
		socialUserId = try container.decodeIfPresent(String.self, forKey: .socialUserId)
		socialProfilePictureURL = try container.decodeIfPresent(URL.self, forKey: .socialProfilePictureURL)
		
		try super.init(from: decoder)
	}
	
	public override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(authProvider.rawValue, forKey: .authProvider)
		try container.encode(socialUsername, forKey: .socialUsername)
		try container.encode(socialUserId, forKey: .socialUserId)
		try container.encode(socialProfilePictureURL, forKey: .socialProfilePictureURL)
		
		try super.encode(to: encoder)
	}
}
