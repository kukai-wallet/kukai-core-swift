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
	public let type: WalletType
	
	/// The public TZ1 address of the wallet
	public var address: String
	
	/// An WalletCore object representing the PrivateKey used to generate the wallet
	public var privateKey: WalletCore.PrivateKey
	
	/// An WalletCore object representing the PublicKey  used to generate the wallet address
	public var publicKey: WalletCore.PublicKey
	
	/// The Bip39 mnemonic used to generate the wallet
	public var mnemonic: String
	
	/// The Bip44 derivationPath used to create the wallet
	public var derivationPath: String
	
	private var seed: Data
	
	private var passphrase: String?
	
	/// A private instance of TrustWallet's Wallet object, used to generate private and public keys based on menmonic and derivation path
	private let internalTrustWallet: WalletCore.HDWallet
	
	
	
	// MARK: - Init
	
	/**
	Create a `HDWallet` by supplying a mnemonic string and a passphrase (or "" if none).
	- Parameter withMnemonic: String contianing a Bip39 mnemonic
	- Parameter passphrase: String contianing a passphrase, or empty string if none
	- Parameter derivationPath: Optional: use a different derivation path to the default `HDWallet.defaultDerivationPath`
	*/
	public convenience init?(withMnemonic mnemonic: String, passphrase: String, derivationPath: String = HDWallet.defaultDerivationPath) {
		let internalTrustWallet = WalletCore.HDWallet(mnemonic: mnemonic, passphrase: passphrase)
		
		self.init(withInternalTrustWallet: internalTrustWallet, derivationPath: derivationPath, passphrase: passphrase)
	}
	
	/**
	Create a `HDWallet` by asking for a mnemonic of a given number of words and a passphrase (or "" if none).
	- Parameter withMnemonic: String contianing a Bip39 mnemonic
	- Parameter passphrase: String contianing a passphrase, or empty string if none
	- Parameter derivationPath: Optional: use a different derivation path to the default `HDWallet.defaultDerivationPath`
	*/
	public convenience init?(withMnemonicLength length: MnemonicPhraseLength, passphrase: String, derivationPath: String = HDWallet.defaultDerivationPath) {
		let internalTrustWallet = WalletCore.HDWallet(strength: Int32(length.rawValue), passphrase: passphrase)
		
		self.init(withInternalTrustWallet: internalTrustWallet, derivationPath: derivationPath, passphrase: passphrase)
	}
	
	/**
	Create a `HDWallet` from a `WalletCore.HDWallet` and a derivation path
	*/
	private init?(withInternalTrustWallet trustWallet: WalletCore.HDWallet, derivationPath: String, passphrase: String?) {
		let escapedDerivationPath = derivationPath.replacingOccurrences(of: "'", with: "\'")
		
		let key = trustWallet.getKey(coin: .tezos, derivationPath: escapedDerivationPath)
		let tempAddress = CoinType.tezos.deriveAddress(privateKey: key)
		
		self.type = .hd
		self.address = tempAddress
		self.privateKey = key
		self.publicKey = key.getPublicKeyEd25519()
		self.mnemonic = trustWallet.mnemonic
		self.derivationPath = derivationPath
		
		self.seed = trustWallet.seed
		self.passphrase = passphrase
		self.internalTrustWallet = trustWallet
	}
	
	/// Automatically scrub the memory of any sensitive data
	deinit {
		// WalletCore will already clean up private and public key
		mnemonic = String(repeating: "0", count: mnemonic.count)
		derivationPath = String(repeating: "0", count: derivationPath.count)
		seed = Data(repeating: 0, count: seed.count)
		passphrase = String(repeating: "0", count: passphrase?.count ?? 0)
	}
	
	
	
	// MARK: - Codable
	
	/// The Codable CodingKeys
	enum CodingKeys: String, CodingKey {
		case type
		case address
		case mnemonic
		case derivationPath
		case seed
		case passphrase
	}
	
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		let typeString = try container.decode(String.self, forKey: .type)
		type = WalletType(rawValue: typeString) ?? .hd
		
		address = try container.decode(String.self, forKey: .address)
		mnemonic = try container.decode(String.self, forKey: .mnemonic)
		derivationPath = try container.decode(String.self, forKey: .derivationPath)
		seed = try container.decode(Data.self, forKey: .seed)
		passphrase = try container.decodeIfPresent(String.self, forKey: .passphrase)
		
		
		// Rebuild trust wallet object and extract private and public key
		let trustWallet = WalletCore.HDWallet(data: seed, passphrase: passphrase ?? "")
		let key = trustWallet.getKey(coin: .tezos, derivationPath: derivationPath)
		
		privateKey = key
		publicKey = key.getPublicKeyEd25519()
		internalTrustWallet = trustWallet
	}
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(type.rawValue, forKey: .type)
		try container.encode(address, forKey: .address)
		try container.encode(mnemonic, forKey: .mnemonic)
		try container.encode(derivationPath, forKey: .derivationPath)
		try container.encode(seed, forKey: .seed)
		try container.encodeIfPresent(passphrase, forKey: .passphrase)
	}
	
	
	
	
	
	
	
	
	
	
	
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
	
	public func privateKeyCurve() -> EllipticalCurve {
		return EllipticalCurve.ed25519
	}
	
	public func publicKeyBase58encoded() -> String {
		return Base58.encode(message: publicKey.data.bytes, prefix: Prefix.Keys.Ed25519.public)
	}
}
