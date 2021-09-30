//
//  File.swift
//  
//
//  Created by Simon Mcloughlin on 28/09/2021.
//

import Foundation
import WalletCore
import os.log

public class LedgerWallet: Wallet {
	
	public var type = WalletType.ledger
	
	public var address: String
	
	public var sortIndex: Int
	
	public var publicKey: String
	
	public var derivationPath: String
	
	public var curve: EllipticalCurve
	
	public var ledgerUUID: String
	
	
	public init(address: String, publicKey: String, derivationPath: String, curve: EllipticalCurve, ledgerUUID: String) {
		self.sortIndex = 0
		self.address = address
		self.publicKey = String(publicKey[2..<publicKey.count]) // remove first 2 characters
		self.derivationPath = derivationPath
		self.curve = curve
		self.ledgerUUID = ledgerUUID
	}
	
	public func sign(_ hex: String) -> [UInt8]? {
		os_log("Must use LedgerService to sign, can't be done in sync code", log: .kukaiCoreSwift, type: .error)
		return []
	}
	
	public func privateKeyCurve() -> EllipticalCurve {
		return curve
	}
	
	public func publicKeyBase58encoded() -> String {
		let publicKeyData = Data(hexString: publicKey) ?? Data()
		return Base58.encode(message: publicKeyData.bytes, prefix: Prefix.Keys.Ed25519.public)
	}
}
