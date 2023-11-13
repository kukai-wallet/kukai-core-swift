//
//  RegularWallet.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 18/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import KukaiCryptoSwift
import Sodium
import os.log

/**
 A Tezos Wallet used for signing transactions before sending to the Tezos network. This object holds the public and private key used to create the contained Tezos address.
 You should **NOT** store a copy of this class in a singleton or gloabl variable of any kind. it should be created as needed and nil'd when not.
 In order to help developers achieve this, use the `WalletCacheService` to store/retreive an encrypted copy of the wallet on disk, and recreate the `Wallet`.
 
 This wallet is a non-HD wallet, sometimes referred to as a "legacy" wallet. It follows the Bip39 standard for generation via menmonic.
 */
public class RegularWallet: Wallet {
	
	/// enum used to differientate wallet class types. Needed for applications that allow users to create many different types of wallets
	public let type: WalletType
	
	/// The TZ1 or TZ2 address of the wallet
	public let address: String
	
	/// An object representing the PrivateKey used to generate the wallet
	public var privateKey: PrivateKey
	
	/// An object representing the PublicKey  used to generate the wallet address
	public var publicKey: PublicKey
	
	/// Optional Bip39 mnemonic used to generate the wallet
	public var mnemonic: Mnemonic?
	
	
	
	// MARK: - Init
	
	/**
	 Attempt to create an instance of a `RegularWallet` from an encoded string containing a private key
	 - parameter withBase58String: String containing the Base58 encoded private key, prefixed with the curve's secret
	 - parameter ellipticalCurve: The ellipcatical curve used to create the key
	 - parameter type: WalletType indicating the top most type of wallet
	 */
	public init?(withBase58String: String, ellipticalCurve: EllipticalCurve, type: WalletType) {
		guard let privateKey = PrivateKey(withBase58String, signingCurve: ellipticalCurve),
			  let pubKey = KeyPair.secp256k1PublicKey(fromPrivateKeyBytes: privateKey.bytes),
			  let tempAddress = pubKey.publicKeyHash else {
			os_log("Failed to construct private/public key", log: .kukaiCoreSwift, type: .error)
			return nil
		}
		
		self.type = type
		self.address = tempAddress
		self.privateKey = privateKey
		self.publicKey = pubKey
		self.mnemonic = nil
	}
	
	/**
	 Create a `RegularWallet` by supplying a `Mnemonic` and a passphrase (or "" if none).
	 - Parameter withMnemonic: A `Mnemonic` representing a BIP39 menmonic
	 - Parameter passphrase: String contianing a passphrase, or empty string if none
	 - Parameter ellipticalCurve: Optional: Choose the `EllipticalCurve` used to generate the wallet address
	 */
	public init?(withMnemonic mnemonic: Mnemonic, passphrase: String/*, ellipticalCurve: EllipticalCurve = .ed25519*/) {
		guard let keyPair = KeyPair.regular(fromMnemonic: mnemonic, passphrase: passphrase/*, andSigningCurve: ellipticalCurve*/), let pkh = keyPair.publicKey.publicKeyHash else {
			return nil
		}
		
		self.type = .regular
		self.address = pkh
		self.privateKey = keyPair.privateKey
		self.publicKey = keyPair.publicKey
		self.mnemonic = mnemonic
	}
	
	/**
	 Create a `RegularWallet` by asking for a mnemonic of a given number of words and a passphrase (or "" if none).
	 - Parameter withMnemonicLength: `Mnemonic.NumberOfWords` the number of words to use when creating a mnemonic
	 - Parameter passphrase: String contianing a passphrase, or empty string if none
	 - Parameter ellipticalCurve: Optional: Choose the `EllipticalCurve` used to generate the wallet address
	 */
	public convenience init?(withMnemonicLength length: Mnemonic.NumberOfWords, passphrase: String/*, ellipticalCurve: EllipticalCurve = .ed25519*/) {
		if let mnemonic = try? Mnemonic(numberOfWords: length) {
			self.init(withMnemonic: mnemonic, passphrase: passphrase/*, ellipticalCurve: ellipticalCurve*/)
			
		} else {
			return nil
		}
	}
	
	
	/// Automatically scrub the memory of any sensitive data
	deinit {
		privateKey.bytes = Array(repeating: 0, count: privateKey.bytes.count)
		publicKey.bytes = Array(repeating: 0, count: publicKey.bytes.count)
		mnemonic?.scrub()
	}
	
	
	
	// MARK: - Crypto Functions
	
	/**
	 Sign a hex payload with the private key
	 */
	public func sign(_ hex: String, isOperation: Bool, completion: @escaping ((Result<[UInt8], KukaiError>) -> Void)) {
		guard let bytes = Sodium.shared.utils.hex2bin(hex) else {
			completion(Result.failure(KukaiError.internalApplicationError(error: WalletError.signatureError)))
			return
		}
		
		var bytesToSign: [UInt8] = []
		if isOperation {
			bytesToSign = bytes.addOperationWatermarkAndHash() ?? []
		} else {
			bytesToSign = Sodium.shared.genericHash.hash(message: bytes, outputLength: 32) ?? []
		}
		
		guard let signature = privateKey.sign(bytes: bytesToSign) else {
			completion(Result.failure(KukaiError.internalApplicationError(error: WalletError.signatureError)))
			return
		}
		
		completion(Result.success(signature))
	}
	
	/**
	 Return the curve used to create the key
	 */
	public func privateKeyCurve() -> EllipticalCurve {
		return privateKey.signingCurve
	}
	
	/**
	 Get a Base58 encoded version of the public key, in order to reveal the address on the network
	 */
	public func publicKeyBase58encoded() -> String {
		return publicKey.base58CheckRepresentation
	}
}

extension RegularWallet: Equatable {
	
	public static func == (lhs: RegularWallet, rhs: RegularWallet) -> Bool {
		return lhs.address == rhs.address
	}
}

extension RegularWallet: Hashable {
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(address)
	}
}
