//
//  HDWallet.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 18/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import WalletCore
import Sodium
import os.log

/**
A Tezos Wallet used for signing transactions before sending to the Tezos network. This object holds the public and private key used to create the contained Tezos address.
You should **NOT** store a copy of this class in a singleton or gloabl variable of any kind. it should be created as needed and nil'd when not.
In order to help developers achieve this, use the `WalletCacheService` to store/retreive an encrypted copy of the wallet on disk, and recreate the `Wallet`.

This wallet is a HD wallet, allowing the creation of many child wallets from the one base privateKey. It also follows the Bip39 stnadard for generation via a mnemonic.
*/
public class HDWallet: Wallet {
	
	
	// MARK: - Constants
	
	/// The default derivation path used by this library
	public static let defaultDerivationPath = "m/44'/1729'/0'/0'"
	
	
	
	// MARK: - Properties
	
	/// The underlying wallet type, set to `.hd`
	public let type: WalletType = .hd
	
	/// The cryptographic seed string, used to generate the key pairs
	public var seed: String
	
	/// An WalletCore object representing the PrivateKey used to generate the wallet
	public var privateKey: WalletCore.PrivateKey
	
	/// An WalletCore object representing the PublicKey  used to generate the wallet address
	public var publicKey: WalletCore.PublicKey
	
	/// The public TZ1 address of the wallet
	public var address: String
	
	/// The Bip39 mnemonic used to generate the wallet
	public var mnemonic: String
	
	/// The Bip44 derivationPath used to create the wallet
	public var derivationPath: String
	
	/// A private instance of TrustWallet's Wallet object, used to generate the cryptographic seed string, only
	private let internalTrustWallet: WalletCore.HDWallet
	
	
	
	// MARK: - Init
	
	/**
	Create a `HDWallet` from a `WalletCore.HDWallet` and a derivation path
	*/
	private init?(withInternalTrustWallet trustWallet: WalletCore.HDWallet, derivationPath: String) {
		let escapedDerivationPath = derivationPath.replacingOccurrences(of: "'", with: "\'")
		
		let key = trustWallet.getKey(coin: .tezos, derivationPath: escapedDerivationPath)
		let tempAddress = CoinType.tezos.deriveAddress(privateKey: key)
		
		self.seed = trustWallet.seed.toHexString()
		self.privateKey = key
		self.publicKey = key.getPublicKeyEd25519()
		self.address = tempAddress
		self.mnemonic = trustWallet.mnemonic
		self.derivationPath = derivationPath
		
		self.internalTrustWallet = trustWallet
	}
	
	/// Automatically scrub the memory of any sensitive data
	deinit {
		// WalletCore will already clean up private and publickey
		seed = String(repeating: "0", count: seed.count)
		address = String(repeating: "0", count: address.count)
		mnemonic = String(repeating: "0", count: mnemonic.count)
		derivationPath = String(repeating: "0", count: derivationPath.count)
	}
	
	/**
	Create a `HDWallet` by supplying a mnemonic string and a passphrase (or "" if none).
	- Parameter withMnemonic: String contianing a Bip39 mnemonic
	- Parameter passphrase: String contianing a passphrase, or empty string if none
	- Parameter derivationPath: Optional: use a different derivation path to the default `HDWallet.defaultDerivationPath`
	*/
	public static func create(withMnemonic mnemonic: String, passphrase: String, derivationPath: String = HDWallet.defaultDerivationPath) -> HDWallet? {
		let internalTrustWallet = WalletCore.HDWallet(mnemonic: mnemonic, passphrase: passphrase)
		
		return HDWallet(withInternalTrustWallet: internalTrustWallet, derivationPath: derivationPath)
	}
	
	/**
	Create a `HDWallet` by asking for a mnemonic of a given number of words and a passphrase (or "" if none).
	- Parameter withMnemonic: String contianing a Bip39 mnemonic
	- Parameter passphrase: String contianing a passphrase, or empty string if none
	- Parameter derivationPath: Optional: use a different derivation path to the default `HDWallet.defaultDerivationPath`
	*/
	public static func create(withMnemonicLength length: MnemonicPhraseLength, passphrase: String, derivationPath: String = HDWallet.defaultDerivationPath) -> HDWallet? {
		let internalTrustWallet = WalletCore.HDWallet(strength: Int32(length.rawValue), passphrase: passphrase)
		
		return HDWallet(withInternalTrustWallet: internalTrustWallet, derivationPath: derivationPath)
	}
	
	
	
	// MARK: - Crypto functions
	
	/**
	Takes in a forged operation hex string, and signs it with the underlying privateKey.
	- Returns: An array of `UInt8` bytes
	*/
	public func sign(_ hex: String) -> [UInt8]? {
		guard let data = Data(hexString: hex) else {
			return nil
		}
		
		let watermarkedOperation = Prefix.Watermark.operation + data.bytes
		let watermarkedHashBytes = Sodium.shared.genericHash.hash(message: watermarkedOperation, outputLength: 32) ?? []
		let watermarkedData = Data(bytes: watermarkedHashBytes, count: watermarkedHashBytes.count)
		let signedData = self.privateKey.sign(digest: watermarkedData, curve: .ed25519)
		
		return signedData?.bytes
	}
	
	/**
	Return the `EllipticalCurve` used to create the wallet
	- Returns: The given elliptical curve
	*/
	public func privateKeyCurve() -> EllipticalCurve {
		return EllipticalCurve.ed25519
	}
	
	/**
	Get a  Base58 encoded version of the publicKey, used for performing a reveal operation
	- Returns: String contianing a Base58 encoded publicKey
	*/
	public func publicKeyBase58encoded() -> String {
		return Base58.encode(message: publicKey.data.bytes, prefix: Prefix.Keys.Ed25519.public)
	}
}
