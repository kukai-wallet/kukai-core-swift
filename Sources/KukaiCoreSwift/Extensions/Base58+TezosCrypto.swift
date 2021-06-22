//
//  Base58+TezosCrypto.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 17/08/2020.
//

import Foundation
import WalletCore

/// Extension to `WalletCore`'s Base58 code to add some helper methods
extension Base58 {
	
	/**
	Base58 encode an array of bytes and add the appropriate prefix base on the ellipticalCurve
	*/
	public static func encode(message: [UInt8], ellipticalCurve: EllipticalCurve) -> String {
		var prefix: [UInt8] = []
		
		
		switch ellipticalCurve {
			case .ed25519:
				prefix = Prefix.Keys.Ed25519.signature
				
			case .secp256k1:
				prefix = Prefix.Keys.Secp256k1.signature
		}
		
		return Base58.encode(message: message, prefix: prefix)
	}
	
	/**
	Base58 encode an array of bytes and add the supplied prefix
	*/
	public static func encode(message: [UInt8], prefix: [UInt8]) -> String {
		let messageBytes = prefix + message
		let asData = Data(bytes: messageBytes, count: messageBytes.count)
		
		return Base58.encode(data: asData)
	}
	
	/**
	Base58 decode a message, removing the supplied prefix
	*/
	public static func decode(string: String, prefix: [UInt8]) -> [UInt8]? {
		guard let bytes = Base58.decode(string: string), bytes.prefix(prefix.count).elementsEqual(prefix)else {
			return nil
		}
		
		return Array(bytes.suffix(from: prefix.count))
	}
}
