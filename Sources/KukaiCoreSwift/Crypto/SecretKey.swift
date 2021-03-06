//
//  SecretKey.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 17/08/2020.
//

import Foundation
import WalletCore
import secp256k1
import Sodium


/// A struct representing a PrivateKey for `LinearWallet` classes
public struct SecretKey {
	
	
	// MARK: - Properties
	
	/// The raw bytes of the private key
	public var bytes: [UInt8]
	
	/// The signing curve used by the public key, to generate a wallet address
	public let signingCurve: EllipticalCurve
	
	/// Return a Base58 encoded version of the privateKey
	public var base58CheckRepresentation: String {
		switch signingCurve {
			case .ed25519:
				return Base58.encode(message: bytes, prefix: Prefix.Keys.Ed25519.secret)
			
			case .secp256k1:
				return Base58.encode(message: bytes, prefix: Prefix.Keys.Secp256k1.secret)
		}
	}
	
	
	
	// MARk: - Init
	
	/// Initialize a key with the given hex seed string.
	///
	///  - Parameters:
	///    - seedString a hex encoded seed string.
	///    - signingCurve: The elliptical curve to use for the key. Defaults to ed25519.
	/// - Returns: A representative secret key, or nil if the seed string was in an unexpected format.
	public init?(seedString: String, signingCurve: EllipticalCurve = .ed25519) {
		guard let seed = Sodium.shared.utils.hex2bin(seedString), let keyPair = Sodium.shared.sign.keyPair(seed: seed) else {
			return nil
		}
		
		// Key is 64 bytes long. The first 32 bytes are the private key. Sodium, the ed25519 library expects extended
		// private keys, so pass down the full 64 bytes.
		let secretKeyBytes = keyPair.secretKey
		switch signingCurve {
			case .ed25519:
				self.init(secretKeyBytes, signingCurve: signingCurve)
			
			case .secp256k1:
				let privateKeyBytes = Array(secretKeyBytes[..<32])
				self.init(privateKeyBytes, signingCurve: signingCurve)
		}
		
	}
	
	/// Initialize a secret key with the given base58check encoded string.
	///
	///  - Parameters:
	///    - string: A base58check encoded string.
	///    - signingCurve: The elliptical curve to use for the key. Defaults to ed25519.
	public init?(_ string: String, signingCurve: EllipticalCurve = .ed25519) {
		switch signingCurve {
			case .ed25519:
				guard let bytes = Base58.decode(string: string, prefix: Prefix.Keys.Ed25519.secret) else {
					return nil
				}
				self.init(bytes)
			
			case .secp256k1:
				guard let bytes = Base58.decode(string: string, prefix: Prefix.Keys.Secp256k1.secret) else {
					return nil
				}
				self.init(bytes, signingCurve: .secp256k1)
		}
	}
	
	/// Initialize a key with the given bytes.
	///  - Parameters:
	///    - bytes: Raw bytes of the private key.
	///    - signingCurve: The elliptical curve to use for the key. Defaults to ed25519.
	public init(_ bytes: [UInt8], signingCurve: EllipticalCurve = .ed25519) {
		self.bytes = bytes
		self.signingCurve = signingCurve
	}
	
	/// Sign the given hex encoded string with the given key.
	///
	/// - Parameters:
	///   - hex: The hex string to sign.
	///   - secretKey: The secret key to sign with.
	/// - Returns: A signature from the input.
	public func sign(hex: String) -> [UInt8]? {
		guard let bytes = Sodium.shared.utils.hex2bin(hex) else {
			return nil
		}
		return self.sign(bytes: bytes)
	}
	
	/// Sign the given bytes.
	///
	/// - Parameters:
	///   - bytes: The raw bytes to sign.
	///   - secretKey: The secret key to sign with.
	/// - Returns: A signature from the input.
	public func sign(bytes: [UInt8]) -> [UInt8]? {
		guard let bytesToSign = prepareBytesForSigning(bytes) else {
			return nil
		}
		
		switch signingCurve {
			case .ed25519:
				return Sodium.shared.sign.signature(message: bytesToSign, secretKey: self.bytes)
			
			case .secp256k1:
				let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))!
				defer {
					secp256k1_context_destroy(context)
				}
				
				var signature = secp256k1_ecdsa_signature()
				let signatureLength = 64
				var output = [UInt8](repeating: 0, count: signatureLength)
				guard secp256k1_ecdsa_sign(context, &signature, bytesToSign, self.bytes, nil, nil) != 0, secp256k1_ecdsa_signature_serialize_compact(context, &output, &signature) != 0 else {
					return nil
				}
				
				return output
		}
	}
	
	/// Prepare bytes for signing by applying a watermark and hashing.
	private func prepareBytesForSigning(_ bytes: [UInt8]) -> [UInt8]? {
		let watermarkedOperation = Prefix.Watermark.operation + bytes
		return Sodium.shared.genericHash.hash(message: watermarkedOperation, outputLength: 32)
	}
}

extension SecretKey: CustomStringConvertible {
	
	public var description: String {
		return base58CheckRepresentation
	}
}

extension SecretKey: Equatable {
	
	public static func == (lhs: SecretKey, rhs: SecretKey) -> Bool {
		return lhs.base58CheckRepresentation == rhs.base58CheckRepresentation
	}
}
