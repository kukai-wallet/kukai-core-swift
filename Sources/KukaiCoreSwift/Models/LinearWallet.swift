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
	
	public let type: WalletType
	
	public let address: String
	
	
	/// An object representing the PrivateKey used to generate the wallet
	public var privateKey: SecretKey
	
	/// An object representing the PublicKey  used to generate the wallet address
	public var publicKey: PublicKey
	
	/// Optional Bip39 mnemonic used to generate the wallet
	public var mnemonic: String?
	
	
	
	
	
	
	// MARK: - Init
	
	public init?(withPrivateKey: String, ellipticalCurve: EllipticalCurve, type: WalletType) {
		guard let secretKey = SecretKey(withPrivateKey, signingCurve: ellipticalCurve),
			  let pubKey = PublicKey(secretKey: secretKey),
			  let tempAddress = pubKey.publicKeyHash else {
			os_log("Failed to construct private/public key", log: .kukaiCoreSwift, type: .error)
			return nil
		}
		
		self.type = type
		self.address = tempAddress
		self.privateKey = secretKey
		self.publicKey = pubKey
		self.mnemonic = nil
	}
	
	/**
	Create a `LinearWallet` by supplying a mnemonic string and a passphrase (or "" if none).
	- Parameter withMnemonic: String contianing a Bip39 mnemonic
	- Parameter passphrase: String contianing a passphrase, or empty string if none
	- Parameter ellipticalCurve: Optional: Choose the `EllipticalCurve` used to generate the wallet address
	*/
	public convenience init?(withMnemonic mnemonic: String, passphrase: String, ellipticalCurve: EllipticalCurve = .ed25519) {
		let internalTrustWallet = WalletCore.HDWallet(mnemonic: mnemonic, passphrase: passphrase)
		
		self.init(withInternalTrustWallet: internalTrustWallet, ellipticalCurve: ellipticalCurve)
	}
	
	/**
	Create a `LinearWallet` by asking for a mnemonic of a given number of words and a passphrase (or "" if none).
	- Parameter withMnemonicLength: `MnemonicPhraseLength` the number of words to use when creating a mnemonic
	- Parameter passphrase: String contianing a passphrase, or empty string if none
	- Parameter ellipticalCurve: Optional: Choose the `EllipticalCurve` used to generate the wallet address
	*/
	public convenience init?(withMnemonicLength length: MnemonicPhraseLength, passphrase: String, ellipticalCurve: EllipticalCurve = .ed25519) {
		let internalTrustWallet = WalletCore.HDWallet(strength: Int32(length.rawValue), passphrase: passphrase)
		
		self.init(withInternalTrustWallet: internalTrustWallet, ellipticalCurve: ellipticalCurve)
	}
	
	/**
	Create a `LinearWallet` from a `WalletCore.HDWallet` and a chosen `EllipticalCurve`
	*/
	private init?(withInternalTrustWallet trustWallet: WalletCore.HDWallet, ellipticalCurve: EllipticalCurve) {
		let trustSeed = trustWallet.seed.toHexString()
		let shortenedSeed = String(trustSeed[..<trustSeed.index(trustSeed.startIndex, offsetBy: 64)])
		
		guard let secretKey = SecretKey(seedString: shortenedSeed, signingCurve: ellipticalCurve),
			  let pubKey = PublicKey(secretKey: secretKey),
			  let tempAddress = pubKey.publicKeyHash else {
			return nil
		}
		
		self.type = .linear
		self.address = tempAddress
		self.privateKey = secretKey
		self.publicKey = pubKey
		self.mnemonic = trustWallet.mnemonic
	}
	
	/// Automatically scrub the memory of any sensitive data
	deinit {
		privateKey.bytes = Array(repeating: 0, count: privateKey.bytes.count)
		publicKey.bytes = Array(repeating: 0, count: publicKey.bytes.count)
		mnemonic = String(repeating: "0", count: mnemonic?.count ?? 0)
	}
	
	
	
	
	
	
	
	public func sign(_ hex: String) -> [UInt8]? {
		return privateKey.sign(hex: hex)
	}
	
	public func privateKeyCurve() -> EllipticalCurve {
		return privateKey.signingCurve
	}
	
	public func publicKeyBase58encoded() -> String {
		return publicKey.base58CheckRepresentation
	}
}
