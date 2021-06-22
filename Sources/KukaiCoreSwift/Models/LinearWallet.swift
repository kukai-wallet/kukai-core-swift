//
//  LinearWallet.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 18/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import WalletCore
import os.log

/**
A Tezos Wallet used for signing transactions before sending to the Tezos network. This object holds the public and private key used to create the contained Tezos address.
You should **NOT** store a copy of this class in a singleton or gloabl variable of any kind. it should be created as needed and nil'd when not.
In order to help developers achieve this, use the `WalletCacheService` to store/retreive an encrypted copy of the wallet on disk, and recreate the `Wallet`.

This wallet is a non-HD wallet, sometimes referred to as a "legacy" wallet. It follows the Bip39 standard for generation via menmonic.
*/
public class LinearWallet: Wallet {
	
	
	// MARK: - Properties
	
	/// The underlying wallet type, set to `.linear`
	public let type: WalletType = .linear
	
	/// The cryptographic seed string, used to generate the key pairs
	public var seed: String
	
	/// An object representing the PrivateKey used to generate the wallet
	public var privateKey: SecretKey
	
	/// An object representing the PublicKey  used to generate the wallet address
	public var publicKey: PublicKey
	
	/// The public TZ1 or TZ2 address of the wallet
	public var address: String
	
	/// The Bip39 mnemonic used to generate the wallet
	public var mnemonic: String
	
	/// A private instance of TrustWallet's Wallet object, used to generate the cryptographic seed string, only
	private let internalTrustWallet: WalletCore.HDWallet
	
	
	
	// MARK: - Init
	
	/**
	Create a `LinearWallet` from a `WalletCore.HDWallet` and a chosen `EllipticalCurve`
	*/
	private init?(withInternalTrustWallet trustWallet: WalletCore.HDWallet, ellipticalCurve: EllipticalCurve) {
		self.internalTrustWallet = trustWallet
		
		let trustSeed = internalTrustWallet.seed.toHexString()
		let shortenedSeed = String(trustSeed[..<trustSeed.index(trustSeed.startIndex, offsetBy: 64)])
		
		guard let secretKey = SecretKey(seedString: shortenedSeed, signingCurve: ellipticalCurve),
			  let publicKey = PublicKey(secretKey: secretKey),
			  let tempAddress = publicKey.publicKeyHash else {
			return nil
		}
		
		self.seed = shortenedSeed
		self.privateKey = secretKey
		self.publicKey = publicKey
		self.address = tempAddress
		self.mnemonic = trustWallet.mnemonic
	}
	
	public init(withPrivateKey: String, ellipticalCurve: EllipticalCurve) {
		guard let secretKey = SecretKey(withPrivateKey, signingCurve: .secp256k1),
			  let publicKey = PublicKey(secretKey: secretKey),
			  let tempAddress = publicKey.publicKeyHash else {
			fatalError("can't proceed")
		}
		
		self.internalTrustWallet = WalletCore.HDWallet(strength: Int32(MnemonicPhraseLength.twelve.rawValue), passphrase: "")
		self.seed = ""
		self.privateKey = secretKey
		self.publicKey = publicKey
		self.address = tempAddress
		self.mnemonic = ""
	}
	
	/// Automatically scrub the memory of any sensitive data
	deinit {
		seed = String(repeating: "0", count: seed.count)
		privateKey.bytes = Array(repeating: 0, count: privateKey.bytes.count)
		publicKey.bytes = Array(repeating: 0, count: publicKey.bytes.count)
		address = String(repeating: "0", count: address.count)
		mnemonic = String(repeating: "0", count: mnemonic.count)
	}
	
	/**
	Create a `LinearWallet` by supplying a mnemonic string and a passphrase (or "" if none).
	- Parameter withMnemonic: String contianing a Bip39 mnemonic
	- Parameter passphrase: String contianing a passphrase, or empty string if none
	- Parameter ellipticalCurve: Optional: Choose the `EllipticalCurve` used to generate the wallet address
	*/
	public static func create(withMnemonic mnemonic: String, passphrase: String, ellipticalCurve: EllipticalCurve = .ed25519) -> LinearWallet? {
		let internalTrustWallet = WalletCore.HDWallet(mnemonic: mnemonic, passphrase: passphrase)
		
		return LinearWallet(withInternalTrustWallet: internalTrustWallet, ellipticalCurve: ellipticalCurve)
	}
	
	/**
	Create a `LinearWallet` by asking for a mnemonic of a given number of words and a passphrase (or "" if none).
	- Parameter withMnemonicLength: `MnemonicPhraseLength` the number of words to use when creating a mnemonic
	- Parameter passphrase: String contianing a passphrase, or empty string if none
	- Parameter ellipticalCurve: Optional: Choose the `EllipticalCurve` used to generate the wallet address
	*/
	public static func create(withMnemonicLength length: MnemonicPhraseLength, passphrase: String, ellipticalCurve: EllipticalCurve = .ed25519) -> LinearWallet?  {
		let internalTrustWallet = WalletCore.HDWallet(strength: Int32(length.rawValue), passphrase: passphrase)
		
		return LinearWallet(withInternalTrustWallet: internalTrustWallet, ellipticalCurve: ellipticalCurve)
	}
	
	
	
	// MARK: - Crypto functions
	
	/**
	Takes in a forged operation hex string, and signs it with the underlying privateKey.
	- Returns: An array of `UInt8` bytes
	*/
	public func sign(_ hex: String) -> [UInt8]? {
		return privateKey.sign(hex: hex)
	}
	
	/**
	Return the `EllipticalCurve` used to create the wallet
	- Returns: The given elliptical curve
	*/
	public func privateKeyCurve() -> EllipticalCurve {
		return privateKey.signingCurve
	}
	
	/**
	Get a  Base58 encoded version of the publicKey, used for performing a reveal operation
	- Returns: String contianing a Base58 encoded publicKey
	*/
	public func publicKeyBase58encoded() -> String {
		return publicKey.base58CheckRepresentation
	}
}
