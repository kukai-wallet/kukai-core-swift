//
//  PublicKey.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 17/08/2020.
//

import Foundation
import WalletCore
import secp256k1
import Sodium


/// A struct representing a PublicKey for `LinearWallet` classes
public struct PublicKey {
	
	
	// MARK: - Properties
	
	/// The raw bytes of the public key
	public var bytes: [UInt8]
	
	/// The signing curve used by the public key, to generate a wallet address
	public let signingCurve: EllipticalCurve
	
	/// Return a Base58 encoded version of the publicKey
	public var base58CheckRepresentation: String {
		switch signingCurve {
			case .ed25519:
				return Base58.encode(message: bytes, prefix: Prefix.Keys.Ed25519.public)
			
			case .secp256k1:
				return Base58.encode(message: bytes, prefix: Prefix.Keys.Secp256k1.public)
		}
	}
	
	/// Return a hash of the publicKey with the appropriate address prefix
	public var publicKeyHash: String? {
		guard let hash = Sodium.shared.genericHash.hash(message: bytes, outputLength: 20) else {
			return nil
		}
		
		switch signingCurve {
			case .ed25519:
				return Base58.encode(message: hash, prefix: Prefix.Address.tz1)
			
			case .secp256k1:
				return Base58.encode(message: hash, prefix: Prefix.Address.tz2)
		}
	}
	
	
	
	// MARK: - Init
	
	/// Initialize a key with the given bytes and signing curve.
	public init(bytes: [UInt8], signingCurve: EllipticalCurve) {
		self.bytes = bytes
		self.signingCurve = signingCurve
	}
	
	/// Initialize a public key with the given base58check encoded string.
	public init?(string: String, signingCurve: EllipticalCurve) {
		switch signingCurve {
			case .ed25519:
				guard let bytes = Base58.decode(string: string, prefix: Prefix.Keys.Ed25519.public) else {
					return nil
				}
				self.init(bytes: bytes, signingCurve: signingCurve)
				
			case .secp256k1:
				guard let bytes = Base58.decode(string: string, prefix: Prefix.Keys.Secp256k1.public) else {
					return nil
				}
				self.init(bytes: bytes, signingCurve: signingCurve)
		}
	}
	
	/// Initialize a key from the given secret key with the given signing curve.
	public init?(secretKey: SecretKey) {
		switch secretKey.signingCurve {
			case .ed25519:
				self.init(bytes: Array(secretKey.bytes[32...]), signingCurve: .ed25519)
				
			case .secp256k1:
				let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN))
				defer {
					secp256k1_context_destroy(context)
				}
				
				var publicKey = secp256k1_pubkey()
				guard
					secp256k1_ec_pubkey_create(context!, &publicKey, secretKey.bytes) != 0
					else {
						return nil
				}
				
				var outputLength = 33
				var publicKeyBytes = [UInt8](repeating: 0, count: outputLength)
				guard secp256k1_ec_pubkey_serialize(
					context!,
					&publicKeyBytes,
					&outputLength,
					&publicKey,
					UInt32(SECP256K1_EC_COMPRESSED)
					) != 0
					else {
						return nil
				}
				
				self.init(bytes: publicKeyBytes, signingCurve: .secp256k1)
		}
	}
	
	
	
	// MARK: - Crypto functions
	
	/// Verify that the given signature matches the given input hex.
	///
	/// - Parameters:
	///   - hex: The hex to check.
	///   - signature: The proposed signature of the bytes.
	///   - publicKey: The proposed public key.
	/// - Returns: True if the public key and signature match the given bytes.
	public func verify(signature: [UInt8], hex: String) -> Bool {
		guard let bytes = Sodium.shared.utils.hex2bin(hex) else {
			return false
		}
		return verify(signature: signature, bytes: bytes)
	}
	
	/// Verify that the given signature matches the given input bytes.
	///
	/// - Parameters:
	///   - bytes: The bytes to check.
	///   - signature: The proposed signature of the bytes.
	///   - publicKey: The proposed public key.
	/// - Returns: True if the public key and signature match the given bytes.
	public func verify(signature: [UInt8], bytes: [UInt8]) -> Bool {
		guard let bytesToVerify = prepareBytesForVerification(bytes) else {
			return false
		}
		
		switch signingCurve {
			case .ed25519:
				return Sodium.shared.sign.verify(message: bytesToVerify, publicKey: self.bytes, signature: signature)
				
			case .secp256k1:
				let context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_VERIFY))
				defer {
					secp256k1_context_destroy(context)
				}
				
				var cSignature = secp256k1_ecdsa_signature()
				var publicKey = secp256k1_pubkey()
				secp256k1_ecdsa_signature_parse_compact(context!, &cSignature, signature)
				_ = secp256k1_ec_pubkey_parse(context!, &publicKey, self.bytes, self.bytes.count)
				
				return secp256k1_ecdsa_verify(context!, &cSignature, bytesToVerify, &publicKey) == 1
		}
	}
	
	/// Prepare bytes for verification by applying a watermark and hashing.
	private func prepareBytesForVerification(_ bytes: [UInt8]) -> [UInt8]? {
		let watermarkedOperation = Prefix.Watermark.operation + bytes
		return Sodium.shared.genericHash.hash(message: watermarkedOperation, outputLength: 32)
	}
}

extension PublicKey: CustomStringConvertible {
	public var description: String {
		return base58CheckRepresentation
	}
}

extension PublicKey: Equatable {
	public static func == (lhs: PublicKey, rhs: PublicKey) -> Bool {
		return lhs.base58CheckRepresentation == rhs.base58CheckRepresentation
	}
}
