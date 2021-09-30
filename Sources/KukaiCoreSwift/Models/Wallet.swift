//
//  Wallet.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 17/08/2020.
//

import Foundation
import WalletCore


// MARK: - Enums

/// Enum to distingush between linear (non-hd) wallets, using the Bip39 standard, and hd wallets using the Bip44 standard.
public enum WalletType: String, Codable {
	case linear
	case hd
	case torus
	case ledger
}

/// Helper enum used to choose the number of words for a mnemonic
public enum MnemonicPhraseLength: Int {
	case twelve = 128
	case fifteen = 160
	case eighteen = 192
	case twentyOne = 224
	case twentyFour = 256
}

/// Distingush between ed25519 (TZ1...) and secp256k1 (TZ2...) curves for creating and using wallet addresses
public enum EllipticalCurve: String, Codable {
	case ed25519
	case secp256k1
}



// MARK: - Protocols

/// Wallet protocol to allow generic handling of all wallets types for signing operations and caching data locally.
public protocol Wallet: Codable {
	
	/// Which underlying `WalletType` is the wallet using
	var type: WalletType { get }
	
	/// The public TZ1 or TZ2 address of the wallet
	var address: String { get }
	
	/// Used to control the order wallets are stored on disk. This can be important to avoid confusing users
	var sortIndex: Int { get set }
	
	
	
	/// Take in a forged operation hex string, and sign it with the private key
	func sign(_ hex: String) -> [UInt8]?
	
	/// Query which curve the given wallet is using
	func privateKeyCurve() -> EllipticalCurve
	
	/// Base58 encoded version of the publicKey, used when performing a reveal operation
	func publicKeyBase58encoded() -> String
}



// MARK: - Objects

/// A collection of utility functions, not unique to any given wallet type
public struct WalletUtils {
	
	/**
	A function to check does a given mnemonic string, match the Bip39 standard.
	- Parameter mnemonic: A String containing a user supplied mnemonic
	- Returns: Bool
	*/
	public static func isMnemonicValid(mnemonic: String) -> Bool {
		return WalletCore.HDWallet.isValid(mnemonic: mnemonic)
	}
}
