//
//  HDWallet.swift
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
 Error types that can be passed by failable inits
 */
public enum HDWalletError: Error {
	case invalidWalletCoreWallet
}

/**
 A Tezos Wallet used for signing transactions before sending to the Tezos network. This object holds the public and private key used to create the contained Tezos address.
 You should **NOT** store a copy of this class in a singleton or gloabl variable of any kind. it should be created as needed and nil'd when not.
 In order to help developers achieve this, use the `WalletCacheService` to store/retreive an encrypted copy of the wallet on disk, and recreate the `Wallet`.
 
 This wallet is a HD wallet, allowing the creation of many child wallets from the one base privateKey. It also follows the Bip39 stnadard for generation via a mnemonic.
 */
public class HDWallet: Wallet {
	
	// MARK: - Properties
	
	/// The underlying wallet type, set to `.hd`
	public let type: WalletType
	
	/// The public TZ1 address of the wallet
	public var address: String
	
	/// An WalletCore object representing the PrivateKey used to generate the wallet
	public var privateKey: PrivateKey
	
	/// An WalletCore object representing the PublicKey  used to generate the wallet address
	public var publicKey: PublicKey
	
	/// The Bip39 mnemonic used to generate the wallet
	public var mnemonic: Mnemonic
	
	/// The Bip44 derivationPath used to create the wallet
	public var derivationPath: String
	
	/// The passphrase used to create the wallet. Not accessible by design, only stored as needed to enable adding child wallets to HD
	private var passphrase: String
	
	
	
	// MARK: - Init
	
	/**
	 Create a `HDWallet` by supplying a mnemonic string and a passphrase (or "" if none).
	 - Parameter withMnemonic: A `Mnemonic` representing a BIP39 menmonic
	 - Parameter passphrase: String contianing a passphrase, or empty string if none
	 - Parameter derivationPath: Optional: use a different derivation path to the default `HDWallet.defaultDerivationPath`
	 */
	public init?(withMnemonic mnemonic: Mnemonic, passphrase: String, derivationPath: String = HD.defaultDerivationPath) {
		guard let keyPair = KeyPair.hd(fromMnemonic: mnemonic, passphrase: passphrase, andDerivationPath: derivationPath) else {
			return nil
		}
		
		self.type = .hd
		self.address = keyPair.publicKey.publicKeyHash ?? ""
		self.privateKey = keyPair.privateKey
		self.publicKey = keyPair.publicKey
		self.mnemonic = mnemonic
		self.derivationPath = derivationPath
		self.passphrase = passphrase
	}
	
	/**
	 Create a `HDWallet` by asking for a mnemonic of a given number of words and a passphrase (or "" if none).
	 - Parameter withMnemonicLength: `Mnemonic.NumberOfWords` the number of words to use when creating a mnemonic
	 - Parameter passphrase: String contianing a passphrase, or empty string if none
	 - Parameter derivationPath: Optional: use a different derivation path to the default `HDWallet.defaultDerivationPath`
	 */
	public convenience init?(withMnemonicLength length: Mnemonic.NumberOfWords, passphrase: String, derivationPath: String = HD.defaultDerivationPath) {
		if let mnemonic = try? Mnemonic(numberOfWords: length) {
			self.init(withMnemonic: mnemonic, passphrase: passphrase, derivationPath: derivationPath)
			
		} else {
			return nil
		}
	}
	
	/// Automatically scrub the memory of any sensitive data
	deinit {
		privateKey.bytes = Array(repeating: 0, count: privateKey.bytes.count)
		publicKey.bytes = Array(repeating: 0, count: publicKey.bytes.count)
		derivationPath = String(repeating: "0", count: derivationPath.count)
		passphrase = String(repeating: "0", count: passphrase.count)
		mnemonic.scrub()
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
			bytesToSign = bytesToSign.addOperationWatermarkAndHash() ?? []
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
	
	/**
	 The default implementation in Ledger is to not give users the option to provide their own derivation path, but instead increment the "account" field by 1 each time.
	 This function will create a new `HDWallet`, by taking the default derivation path and changing the account to the index supplied, and using the same key
	 */
	public func createChild(accountIndex: Int) -> HDWallet? {
		let newDerivationPath = HD.defaultDerivationPath(withAccountIndex: accountIndex)
		
		guard let newWallet = HDWallet(withMnemonic: self.mnemonic, passphrase: self.passphrase, derivationPath: newDerivationPath) else {
			return nil
		}
		
		return newWallet
	}
	
	/**
	 This function will create a new `HDWallet`, by using the same key combined with the supplied derivationPath
	 */
	public func createChild(derivationPath: String) -> HDWallet? {
		guard let newWallet = HDWallet(withMnemonic: self.mnemonic, passphrase: self.passphrase, derivationPath: derivationPath) else {
			return nil
		}
		
		return newWallet
	}
}

extension HDWallet: Equatable {
	
	public static func == (lhs: HDWallet, rhs: HDWallet) -> Bool {
		return lhs.address == rhs.address
	}
}

extension HDWallet: Hashable {
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(address)
	}
}
