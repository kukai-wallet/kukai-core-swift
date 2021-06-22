//
//  WalletCacheService.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 21/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//
// Based off: https://github.com/VivoPay/VivoPayEncryption , with some design changes and lowering iOS requirement to iOS 12

import Foundation
import LocalAuthentication
import CryptoKit
import os.log



/// Error types that can be returned from `WalletCacheService`
enum WalletCacheError: Error {
	case unableToAccessEnclaveOrKeychain
	case unableToCreatePrivateKey
	case unableToDeleteKey
	case unableToParseAsUTF8Data
	case noPublicKeyFound
	case unableToEncrypt
	case noPrivateKeyFound
	case unableToDecrypt
}



/**
A service class used to store and retrieve `Wallet` objects such as `LinearWallet` and `HDWallet` from the devices disk.
This class will use the secure enclave (keychain if not available) to generate a key used to encrypt the contents locally, and retrieve.
The class can be used to take the decrypted JSON and convert it back into Wallet classes, ready to be used.
*/
public class WalletCacheService {
	
	// MARK: - Properties
	
	/// PublicKey used to encrypt the wallet data locally
	fileprivate var publicKey: SecKey?
	
	/// PrivateKey used to decrypt the wallet data locally
	fileprivate var privateKey: SecKey?
	
	/// The algorithm used by the enclave or keychain
	fileprivate static let encryptionAlgorithm = SecKeyAlgorithm.eciesEncryptionCofactorX963SHA256AESGCM
	
	/// The application key used to identify the encryption keys
	fileprivate static let applicationKey = "app.kukai.kukai-core-swift.walletcache.encryption"
	
	// The filename where the data will be stored
	fileprivate static let cacheFileName = "wallets.txt"
	
	
	
	// MARK: - Init
	
	/// Empty
	public init() {}
	
	/// Clear the public and private key references
	deinit {
		publicKey = nil
		privateKey = nil
	}
	
	
	
	// MARK: - Storage and Retrieval
	
	/**
	Add a `Wallet` object to the local encrypted storage
	- Parameter wallet: An object conforming to `Wallet` to be stored
	- Parameter andPassphrase: The passphrase the user entered to create the wallet
	- Returns: Bool, indicating if the storage was successful or not
	*/
	public func cache(wallet: Wallet, andPassphrase: String?) -> Bool {
		guard let existingWalletItems = readFromDiskAndDecrypt() else {
			os_log(.error, log: .kukaiCoreSwift, "Unable to cache wallet, as can't decrypt existing wallets")
			return false
		}
		
		var newWallets = existingWalletItems
		var derivationPath: String? = nil
		
		switch wallet.type {
			case .linear:
				derivationPath = nil
				
			case .hd:
				derivationPath = (wallet as? HDWallet)?.derivationPath
		}
		
		newWallets.append(WalletCacheItem(address: wallet.address, mnemonic: wallet.mnemonic, passphrase: andPassphrase, sortIndex: newWallets.count, type: wallet.type, ellipticalCurve: wallet.privateKeyCurve(), derivationPath: derivationPath))
		
		return encryptAndWriteToDisk(walletItems: newWallets)
	}
	
	/**
	Take an array of `WalletCacheItem` serialise to JSON, encrypt and then write to disk
	- Returns: Bool, indicating if the process was successful
	*/
	public func encryptAndWriteToDisk(walletItems: [WalletCacheItem]) -> Bool {
		do {
			let jsonData = try JSONEncoder().encode(walletItems)
			
			guard loadOrCreateKeys(),
				  let plaintext = String(data: jsonData, encoding: .utf8),
				  let ciphertextData = try? encrypt(plaintext),
				  DiskService.write(data: ciphertextData, toFileName: WalletCacheService.cacheFileName) else {
				os_log(.error, log: .kukaiCoreSwift, "Unable to save wallet items")
				return false
			}
			
			return true
			
		} catch (let error) {
			os_log(.error, log: .kukaiCoreSwift, "Unable to save wallet items: %@", "\(error)")
			return false
		}
	}
	
	/**
	Go to the file on disk (if present), decrypt its contents and retrieve an array of `WalletCacheItem`
	- Returns: An array of `WalletCacheItem` if present on disk
	*/
	public func readFromDiskAndDecrypt() -> [WalletCacheItem]? {
		guard let data = DiskService.readData(fromFileName: WalletCacheService.cacheFileName) else {
			return [] // No such file
		}
		
		guard loadOrCreateKeys(),
			  let plaintext = try? decrypt(data),
			  let plaintextData = plaintext.data(using: .utf8) else {
			os_log(.error, log: .kukaiCoreSwift, "Unable to read wallet items")
			return nil
		}
		
		do {
			var cacheItems = try JSONDecoder().decode([WalletCacheItem].self, from: plaintextData)
			cacheItems.sort(by: { $0.sortIndex < $1.sortIndex })
			
			return cacheItems
			
		} catch (let error) {
			os_log(.error, log: .kukaiCoreSwift, "Unable to read wallet items: %@", "\(error)")
			return nil
		}
	}
	
	/**
	Read, decrypt and re-create the `Wallet` objects from the stored cache
	- Returns: An array of `Wallet` objects if present on disk
	*/
	public func fetchWallets() -> [Wallet]? {
		guard let cacheItems = readFromDiskAndDecrypt() else {
			os_log(.error, log: .kukaiCoreSwift, "Unable to read wallet items")
			return nil
		}
		
		return parse(cacheItems: cacheItems)
	}
	
	/**
	A shorthand function to avoid unnecessary processing. It will read, decrypt and re-create the first `Wallet` object present on disk
	- Returns: A `Wallet` object if present on disk
	*/
	public func fetchPrimaryWallet() -> Wallet? {
		guard let cacheItems = readFromDiskAndDecrypt(),
			  let first = cacheItems.first else {
			os_log(.error, log: .kukaiCoreSwift, "Unable to read wallet items")
			return nil
		}
		
		return parse(cacheItems: [first]).first
	}
	
	/**
	Convert an array of `WalletCacheItem`'s to `Wallet`'s by performing the various private / public key operations
	- Returns: An array of `Wallet` objects
	*/
	public func parse(cacheItems: [WalletCacheItem]) -> [Wallet] {
		var wallets: [Wallet] = []
		
		cacheItems.forEach { (walletCacheItem) in
			switch walletCacheItem.type {
				case .linear:
					let wallet = LinearWallet.create(withMnemonic: walletCacheItem.mnemonic, passphrase: walletCacheItem.passphrase ?? "", ellipticalCurve: walletCacheItem.ellipticalCurve)
					wallets.append(wallet!)
					
				case .hd:
					let wallet = HDWallet.create(withMnemonic: walletCacheItem.mnemonic, passphrase: walletCacheItem.passphrase ?? "", derivationPath: walletCacheItem.derivationPath ?? HDWallet.defaultDerivationPath)
					wallets.append(wallet!)
			}
		}
		
		return wallets
	}
	
	/**
	Delete the cached file and the assoicate keys used to encrypt it
	- Returns: Bool, indicating if the process was successful or not
	*/
	public func deleteCacheAndKeys() -> Bool {
		try? deleteKey()
		return DiskService.delete(fileName: WalletCacheService.cacheFileName)
	}
}



// MARK: - Encryption

extension WalletCacheService {
	
	/**
	Load the key references from the secure enclave (or keychain), or create them if non exist
	- Returns: Bool, indicating if operation was successful
	*/
	public func loadOrCreateKeys() -> Bool {
		do {
			if let key = try loadKey() {
				privateKey = key
				publicKey = SecKeyCopyPublicKey(key)
				
			} else {
				let keyTuple = try createKeys()
				self.publicKey = keyTuple.public
				self.privateKey = keyTuple.private
			}
			
			return true
			
		} catch (let error) {
			os_log(.error, log: .keychain, "Unable to load or create keys: %@", "\(error)")
			return false
		}
	}
	
	/**
	Clear the key refrences
	*/
	public func unloadKeys() {
		self.privateKey = nil
		self.publicKey = nil
	}
	
	/**
	Create the public/private keys in the secure enclave (or keychain)
	*/
	fileprivate func createKeys() throws  -> (public: SecKey, private: SecKey?) {
		
		var error: Unmanaged<CFError>?
		
		let privateKeyAccessControl: SecAccessControlCreateFlags = CurrentDevice.hasSecureEnclave ?  [.privateKeyUsage] : []
		guard let privateKeyAccess = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, privateKeyAccessControl, &error) else {
			if let err = error { throw err.takeRetainedValue() as Error }
			else { throw WalletCacheError.unableToAccessEnclaveOrKeychain }
		}
		
		let context = LAContext()
		context.interactionNotAllowed = false
		
		var privateKeyAttributes: [String: Any] = [
			kSecAttrApplicationTag as String: WalletCacheService.applicationKey,
			kSecAttrIsPermanent as String: true,
			kSecUseAuthenticationContext as String: context,
			kSecAttrAccessControl as String: privateKeyAccess
		]
		var commonKeyAttributes: [String: Any] = [
			kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
			kSecAttrKeySizeInBits as String: 256,
			kSecPrivateKeyAttrs as String: privateKeyAttributes
		]
		
		if CurrentDevice.hasSecureEnclave {
			os_log(.debug, log: .keychain, "Using secure enclave")
			commonKeyAttributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
			commonKeyAttributes[kSecPrivateKeyAttrs as String] = privateKeyAttributes
			privateKeyAttributes[kSecAttrAccessControl as String] = privateKeyAccessControl
		}
		
		guard let privateKey = SecKeyCreateRandomKey(commonKeyAttributes as CFDictionary, &error) else {
			if let err = error { throw err.takeRetainedValue() as Error }
			else { throw WalletCacheError.unableToCreatePrivateKey }
		}
		
		guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
			throw WalletCacheError.unableToCreatePrivateKey
		}
		
		return (public: publicKey, private: privateKey)
	}
	
	/**
	Load a key reference
	*/
	fileprivate func loadKey() throws -> SecKey? {
		var query: [String: Any] = [
			kSecClass as String: kSecClassKey,
			kSecAttrApplicationTag as String: WalletCacheService.applicationKey,
			kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
			kSecReturnRef as String: true
		]
		
		if CurrentDevice.hasSecureEnclave {
			os_log(.debug, log: .keychain, "Using secure enclave")
			query[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
		}
		
		var key: CFTypeRef?
		if SecItemCopyMatching(query as CFDictionary, &key) == errSecSuccess {
			return (key as! SecKey)
		}
		
		return nil
	}
	
	/**
	Delete a key from the secure enclave
	*/
	public func deleteKey() throws {
		let query = [kSecClass: kSecClassKey,kSecAttrApplicationTag: WalletCacheService.applicationKey] as [String: Any]
		let result = SecItemDelete(query as CFDictionary)
		
		if result != errSecSuccess {
			os_log(.error, log: .keychain, "Error removing keys. OSSatus - %@", "\(result)")
			throw WalletCacheError.unableToDeleteKey
		}
	}
	
	/**
	Encrypts string using the Secure Enclave
	- Parameter string: clear text to be encrypted
	- Throws: CryptoKit error
	- Returns: cipherText encrypted string
	*/
	public func encrypt(_ string: String) throws -> Data {
		guard let data = string.data(using: .utf8) else {
			throw WalletCacheError.unableToParseAsUTF8Data
		}
		
		guard let pubKey = self.publicKey, SecKeyIsAlgorithmSupported(pubKey, .encrypt, WalletCacheService.encryptionAlgorithm) else {
			throw WalletCacheError.noPublicKeyFound
		}
		
		var error: Unmanaged<CFError>?
		guard let cipherText = SecKeyCreateEncryptedData(pubKey, WalletCacheService.encryptionAlgorithm, data as CFData, &error) as Data? else {
			if let err = error { throw err.takeRetainedValue() as Error }
			else { throw WalletCacheError.unableToEncrypt }
		}
		
		return cipherText
	}
	
	/**
	Decrypts cipher text using the Secure Enclave
	- Parameter cipherText: encrypted cipher text
	- Throws: CryptoKit error
	- Returns: cleartext string
	*/
	public func decrypt(_ cipherText: Data) throws -> String {
		
		guard let privateKey = privateKey, SecKeyIsAlgorithmSupported(privateKey, .decrypt, WalletCacheService.encryptionAlgorithm) else {
			throw WalletCacheError.noPrivateKeyFound
		}
		
		var error: Unmanaged<CFError>?
		guard let clearText = SecKeyCreateDecryptedData(privateKey, WalletCacheService.encryptionAlgorithm, cipherText as CFData, &error) as Data?,
			  let textAsString = String(data: clearText, encoding: .utf8) else {
			if let err = error { throw err.takeRetainedValue() as Error }
			else { throw WalletCacheError.unableToDecrypt }
		}
		
		return textAsString
	}
}
