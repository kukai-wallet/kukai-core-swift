//
//  Wallet.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 17/08/2020.
//

import Foundation
import KukaiCryptoSwift


// MARK: - Enums

/// Enum to distingush between linear (non-hd) wallets, using the Bip39 standard, and hd wallets using the Bip44 standard.
public enum WalletType: String, Codable {
	case regular
	case hd
	case social
	case ledger
}

/**
 Possible error types that can occur when using the LedgerWallet
 */
public enum WalletError: Error {
	case signatureError
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
	
	
	
	/**
	 Sign a hex string with the wallets private key
	 - parameter hex: A hex encoded string, representing a forged operation payload.
	 - parameter completion: A completion block to run with the resulting signature, needs to be done async in order to support usecases such as signing with an external ledger.
	 */
	func sign(_ hex: String, completion: @escaping ((Result<[UInt8], KukaiError>) -> Void))
	
	/// Query which curve the given wallet is using
	func privateKeyCurve() -> EllipticalCurve
	
	/// Base58 encoded version of the publicKey, used when performing a reveal operation
	func publicKeyBase58encoded() -> String
}
