//
//  LedgerWallet.swift
//  
//
//  Created by Simon Mcloughlin on 28/09/2021.
//

import Foundation
import KukaiCryptoSwift
import Combine
import Sodium
import os.log


/**
A Tezos wallet class, used to cache infomration regarding the paired ledger device used to sign the payload.
This class can only be created by fetching data from a Ledger device and supplying this data to the constructor.

It is not possible to call the async sign function of this class, it will return null. Signing with a ledger is a complicated async process.
Please use the LedgerService class to setup a bluetooth connection, connect to the device and request a payload signing.
*/
public class LedgerWallet: Wallet {
	
	/// The wallet type, hardcoded to always be `WalletType.ledger`
	public var type = WalletType.ledger
	
	/// The TZ address pulled from the Ledger device, cached to avoid complex retrieval when fetching balances etc.
	public var address: String
	
	/// The raw hex public key extracted from the Ledger, needed in order to perform REVEAL operations
	public var publicKey: String
	
	/// The derivation path used to fetch the address and public key
	public var derivationPath: String
	
	/// The elliptical curve used to fetch the address and public key
	public var curve: EllipticalCurve
	
	/// The unique ledger UUID, that corresponds to this wallet address
	public var ledgerUUID: String
	
	/// Combine bag for holding cancellables
	private lazy var bag = Set<AnyCancellable>()
	
	
	
	/**
	Create an instance of a LedgerWallet. Can return nil if invalid public key supplied
	- parameter address: The TZ address pulled from the Ledger device
	- parameter publicKey: The hex string denoting the public key, pulled from the ledger device
	- parameter derivationPath: The derivation path used to fetch the address / publicKey
	- parameter curve: The elliptical curve used to fetch the address / public key
	- parameter ledgerUUID: The unique Ledger UUID to identify the Ledger
	*/
	public init?(address: String, publicKey: String, derivationPath: String, curve: EllipticalCurve, ledgerUUID: String) {
		if publicKey.count < 4 {
			return nil
		}
		
		self.address = address
		
		let startIndex = publicKey.index(publicKey.startIndex, offsetBy: 2)
		let endIndex = publicKey.endIndex
		self.publicKey = String(publicKey[startIndex..<endIndex]) // remove first 2 characters
		
		self.derivationPath = derivationPath
		self.curve = curve
		self.ledgerUUID = ledgerUUID
	}
	
	/**
	 Sign a hex string.
	 If the string starts with "03" and is not 32 characters long, it will be treated as a watermarked operation and Ledger will be asked to parse + display the operation details.
	 Else it will be treated as an unknown operation and will simply display the Blake2b hash.
	 Please be careful when asking the Ledger to parse (passing in an operation), Ledgers have very limited display ability. Keep it to a single operation, not invoking a smart contract
	*/
	public func sign(_ hex: String, isOperation: Bool, completion: @escaping ((Result<[UInt8], KukaiError>) -> Void)) {
		let isWatermarkedOperation = (String(hex.prefix(2)) == "03") && hex.count != 32
		
		LedgerService.shared.connectTo(uuid: ledgerUUID)
			.flatMap { _ -> AnyPublisher<String, KukaiError> in
				return LedgerService.shared.sign(hex: hex, parse: isWatermarkedOperation)
			}
			.sink(onError: { error in
				completion(Result.failure(error))
				
			}, onSuccess: { signature in
				guard let binarySignature = Sodium.shared.utils.hex2bin(signature) else {
					completion(Result.failure(KukaiError.internalApplicationError(error: WalletError.signatureError)))
					return
				}
				
				completion(Result.success(binarySignature))
			})
			.store(in: &bag)
	}
	
	/**
	Function to extract the curve used to create the public key
	*/
	public func privateKeyCurve() -> EllipticalCurve {
		return curve
	}
	
	/**
	Function to convert the public key into a Base58 encoded string
	*/
	public func publicKeyBase58encoded() -> String {
		let publicKeyData = (try? Data(hexString: publicKey)) ?? Data()
		return Base58Check.encode(message: publicKeyData.bytes, prefix: Prefix.Keys.Ed25519.public)
	}
}
