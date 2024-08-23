//
//  WalletCacheService.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 21/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//
//	Based off: https://github.com/VivoPay/VivoPayEncryption , with extra functionality and some design changes

import Foundation
import LocalAuthentication
import CryptoKit
import os.log



/// Error types that can be returned from `WalletCacheService`
public enum WalletCacheError: String, Error {
	case unableToAccessEnclaveOrKeychain
	case unableToCreatePrivateKey
	case unableToDeleteKey
	case unableToParseAsUTF8Data
	case noPublicKeyFound
	case unableToEncrypt
	case noPrivateKeyFound
	case unableToDecrypt
	case walletAlreadyExists
	case requestedIndexTooHigh
	case unableToEncryptAndWrite
}



/**
 A service class used to store and retrieve `Wallet` objects such as `RegularWallet`, `HDWallet`, `LedgerWallet` and `TorusWallet` from the devices disk.
 This class will use the secure enclave (keychain if not available) to generate a key used to encrypt the contents locally, and retrieve.
 This class will also store non senstiivve "metadata" about wallets, to allow storage of UI related data users might want to add, without cluttering up the wallet objects themselves
*/
public class WalletCacheService {
	
	// MARK: - Properties
	
	/// PublicKey used to encrypt the wallet data locally
	fileprivate var publicKey: SecKey?
	
	/// PrivateKey used to decrypt the wallet data locally
	fileprivate var privateKey: SecKey?
	
	/// The algorithm used by the enclave or keychain
	fileprivate static var encryptionAlgorithm = SecKeyAlgorithm.eciesEncryptionCofactorVariableIVX963SHA256AESGCM
	
	/// The application key used to identify the encryption keys
	fileprivate static let applicationKey = "app.kukai.kukai-core-swift.walletcache.encryption"
	
	/// The filename where the wallet data will be stored, encrypted
	fileprivate static let walletCacheFileName = "kukai-core-wallets.txt"
	
	/// The filename where the public wallet data and in app metadata will be stored, unencrypted
	fileprivate static let metadataCacheFileName = "kukai-core-wallets-metadata.txt"
	
	
	
	
	
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
	 Securely cache a walelt object, and record a default metadata object
	 - Parameter wallet: An object conforming to `Wallet` to be stored
	 - Parameter childOfIndex: An optional `Int` to denote the index of the HD wallet that this wallet is a child of
	 - Returns: Bool, indicating if the storage was successful or not
	 */
	public func cache<T: Wallet>(wallet: T, childOfIndex: Int?, backedUp: Bool, customDerivationPath: String? = nil) throws {
		guard let existingWallets = readWalletsFromDiskAndDecrypt() else {
			Logger.walletCache.error("cache - Unable to cache wallet, as can't decrypt existing wallets")
			throw WalletCacheError.unableToDecrypt
		}
		
		guard existingWallets[wallet.address] == nil else {
			Logger.walletCache.error("cache - Unable to cache wallet, walelt already exists")
			throw WalletCacheError.walletAlreadyExists
		}
		
		var newWallets = existingWallets
		newWallets[wallet.address] = wallet
		
		let newMetadata = readMetadataFromDiskAndDecrypt()
		var array = metadataArray(forType: wallet.type, fromMeta: newMetadata)
		
		if let index = childOfIndex {
			
			// If child index is present, update the correct sub array to include this new item, checking forst that we have the correct details
			if index >= array.count {
				Logger.walletCache.error("WalletCacheService metadata insertion issue. Requested to add at index \"\(index)\", when there are currently only \"\(array.count)\" items")
				throw WalletCacheError.requestedIndexTooHigh
			}
			
			array[index].children.append(WalletMetadata(address: wallet.address, hdWalletGroupName: nil, walletNickname: nil, socialUsername: nil, type: wallet.type, children: [], isChild: true, isWatchOnly: false, bas58EncodedPublicKey: wallet.publicKeyBase58encoded(), backedUp: backedUp, customDerivationPath: customDerivationPath))
			
		} else if wallet.type == .hd || wallet.type == .ledger {
			
			// If its HD or Ledger (also a HD), these wallets display grouped together with a custom name. Compute the new default name based off existing data and then add
			var groupNameStart = ""
			switch wallet.type {
				case .hd:
					groupNameStart = "HD Wallet "
				case .ledger:
					groupNameStart = "Ledger Wallet "
				case .social, .regular, .regularShifted:
					groupNameStart = ""
			}
			
			var newNumber = 0
			if let lastDefaultName = array.reversed().first(where: { $0.hdWalletGroupName?.prefix(groupNameStart.count) ?? " " == groupNameStart }) {
				let numberOnly = lastDefaultName.hdWalletGroupName?.replacingOccurrences(of: groupNameStart, with: "")
				newNumber = (Int(numberOnly ?? "0") ?? 0) + 1
			}
			
			if newNumber == 0 {
				newNumber = array.count + 1
			}
			
			array.append(WalletMetadata(address: wallet.address, hdWalletGroupName: "\(groupNameStart)\(newNumber)", walletNickname: nil, socialUsername: nil, socialType: nil, type: wallet.type, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: wallet.publicKeyBase58encoded(), backedUp: backedUp, customDerivationPath: customDerivationPath))
			
		} else if let torusWallet = wallet as? TorusWallet {
			
			// If social, cast and fetch special attributes
			array.append(WalletMetadata(address: wallet.address, hdWalletGroupName: nil, walletNickname: nil, socialUsername: torusWallet.socialUsername, socialUserId: torusWallet.socialUserId, socialType: torusWallet.authProvider, type: wallet.type, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: wallet.publicKeyBase58encoded(), backedUp: backedUp, customDerivationPath: customDerivationPath))
			
		} else {
			
			// Else, add basic wallet to the list its supposed to go to
			array.append(WalletMetadata(address: wallet.address, hdWalletGroupName: nil, walletNickname: nil, socialUsername: nil, socialType: nil, type: wallet.type, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: wallet.publicKeyBase58encoded(), backedUp: backedUp, customDerivationPath: customDerivationPath))
		}
		
		// Update wallet metadata array, and then commit to disk
		updateMetadataArray(forType: wallet.type, withNewArray: array, forMeta: newMetadata)
		if encryptAndWriteWalletsToDisk(wallets: newWallets) && encryptAndWriteMetadataToDisk(newMetadata) == false {
			throw WalletCacheError.unableToEncryptAndWrite
		} else {
			removeNewAddressFromWatchListIfExists(wallet.address, list: newMetadata)
		}
	}
	
	/// Helper method to return the appropriate sub array for the type, to reduce code compelxity
	private func metadataArray(forType: WalletType, fromMeta: WalletMetadataList) -> [WalletMetadata] {
		switch forType {
			case .regular:
				return fromMeta.linearWallets
			case .regularShifted:
				return fromMeta.linearWallets
			case .hd:
				return fromMeta.hdWallets
			case .social:
				return fromMeta.socialWallets
			case .ledger:
				return fromMeta.ledgerWallets
		}
	}
	
	/// Helper method to take ina  new sub array and update and existing reference, to reduce code complexity
	private func updateMetadataArray(forType: WalletType, withNewArray: [WalletMetadata], forMeta: WalletMetadataList) {
		switch forType {
			case .regular:
				forMeta.linearWallets = withNewArray
			case .regularShifted:
				forMeta.linearWallets = withNewArray
			case .hd:
				forMeta.hdWallets = withNewArray
			case .social:
				forMeta.socialWallets = withNewArray
			case .ledger:
				forMeta.ledgerWallets = withNewArray
		}
	}
	
	private func removeNewAddressFromWatchListIfExists(_ address: String, list: WalletMetadataList) {
		if let _ = list.watchWallets.first(where: { $0.address == address }) {
			let _ = deleteWatchWallet(address: address)
		}
	}
	
	/**
	 Cahce a watch wallet metadata obj, only. Metadata cahcing handled via wallet cache method
	 */
	public func cacheWatchWallet(metadata: WalletMetadata) throws {
		let list = readMetadataFromDiskAndDecrypt()
		
		if let _ = list.addresses().first(where: { $0 == metadata.address }) {
			Logger.walletCache.error("cacheWatchWallet - Unable to cache wallet, wallet already exists")
			throw WalletCacheError.walletAlreadyExists
		}
			
		list.watchWallets.append(metadata)
		
		if encryptAndWriteMetadataToDisk(list) == false {
			throw WalletCacheError.unableToEncryptAndWrite
		}
	}
	
	/**
	 Delete both a secure wallet entry and its related metadata object
	 - Parameter withAddress: The address of the wallet
	 - Parameter parentIndex: An optional `Int` to denote the index of the HD wallet that this wallet is a child of
	 - Returns: Bool, indicating if the storage was successful or not
	 */
	public func deleteWallet(withAddress: String, parentIndex: Int?) -> Bool {
		guard let existingWallets = readWalletsFromDiskAndDecrypt() else {
			Logger.walletCache.error("Unable to fetch wallets")
			return false
		}
		
		var newWallets = existingWallets
		let type = existingWallets[withAddress]?.type ?? .hd
		newWallets.removeValue(forKey: withAddress)
		
		let newMetadata = readMetadataFromDiskAndDecrypt()
		var array = metadataArray(forType: type, fromMeta: newMetadata)
		
		if let hdWalletIndex = parentIndex {
			guard hdWalletIndex < array.count, let childIndex = array[hdWalletIndex].children.firstIndex(where: { $0.address == withAddress }) else {
				Logger.walletCache.error("Unable to locate wallet")
				return false
			}
			
			let _ = array[hdWalletIndex].children.remove(at: childIndex)
			
		} else {
			if let index = array.firstIndex(where: { $0.address == withAddress }) {
				
				// Children will be removed from metadata automatically, as they are contained inside the parent, however they won't from the encrypted cache
				// Remove them from encrypted first, then parent from metadata
				let children = array[index].children
				for child in children {
					newWallets.removeValue(forKey: child.address)
				}
				
				let _ = array.remove(at: index)
				
			} else {
				Logger.walletCache.error("Unable to locate wallet")
				return false
			}
		}
		
		updateMetadataArray(forType: type, withNewArray: array, forMeta: newMetadata)
		return encryptAndWriteWalletsToDisk(wallets: newWallets) && encryptAndWriteMetadataToDisk(newMetadata)
	}
	
	/**
	 Clear a watch wallet meatadata obj from the metadata cache only, does not affect actual wallet cache
	 */
	public func deleteWatchWallet(address: String) -> Bool {
		let list = readMetadataFromDiskAndDecrypt()
		list.watchWallets.removeAll(where: { $0.address == address })
		
		return encryptAndWriteMetadataToDisk(list)
	}
	
	/**
	 Find and return the secure object for a given address
	 - Returns: Optional object confirming to `Wallet` protocol
	 */
	public func fetchWallet(forAddress address: String) -> Wallet? {
		guard let cacheItems = readWalletsFromDiskAndDecrypt() else {
			Logger.walletCache.error("Unable to read wallet items")
			return nil
		}
		
		return cacheItems[address]
	}
	
	/**
	 Delete the cached files and the assoicate keys used to encrypt it
	 - Returns: Bool, indicating if the process was successful or not
	 */
	public func deleteAllCacheAndKeys() -> Bool {
		
		if Thread.current.isRunningXCTest {
			self.publicKey = nil
			self.privateKey = nil
			
		} else {
			try? deleteKey()
		}
		
		return DiskService.delete(fileName: WalletCacheService.walletCacheFileName) && DiskService.delete(fileName: WalletCacheService.metadataCacheFileName)
	}
	
	
	
	
	
	// MARK: - Read and Write
	
	/**
	 Take a dictionary of `Wallet` objects with their addresses as the key, serialise to JSON, encrypt and then write to disk
	 - Returns: Bool, indicating if the process was successful
	 */
	public func encryptAndWriteWalletsToDisk(wallets: [String: Wallet]) -> Bool {
		do {
			
			/// Because `Wallet` is a generic protocl, `JSONEncoder` can't be called on an array of it.
			/// Instead we must iterate through each item in the array, use its `type` to determine the corresponding class, and encode each one
			/// The only way to encode all of these items individually, without loosing data, is to convert each one to a JSON object, pack in an array and call `JSONSerialization.data`
			/// This results in a JSON blob containing all of the unique properties of each subclass, while allowing the caller to pass in any conforming `Wallet` type
			var jsonDict: [String: Any] = [:]
			var walletData: Data = Data()
			for wallet in wallets.values {
				switch wallet.type {
					case .regular, .regularShifted:
						if let walletObj = wallet as? RegularWallet {
							walletData = try JSONEncoder().encode(walletObj)
						}
						
					case .hd:
						if let walletObj = wallet as? HDWallet {
							walletData = try JSONEncoder().encode(walletObj)
						}
						
					case .social:
						if let walletObj = wallet as? TorusWallet {
							walletData = try JSONEncoder().encode(walletObj)
						}
						
					case .ledger:
						if let walletObj = wallet as? LedgerWallet {
							walletData = try JSONEncoder().encode(walletObj)
						}
				}
				
				let jsonObj = try JSONSerialization.jsonObject(with: walletData, options: .allowFragments)
				jsonDict[wallet.address] = jsonObj
			}
			
			let jsonData = try JSONSerialization.data(withJSONObject: jsonDict, options: .fragmentsAllowed)
			
			
			/// Take the JSON blob, encrypt and store on disk
			guard loadOrCreateKeys(),
				  let plaintext = String(data: jsonData, encoding: .utf8),
				  let ciphertextData = try? encrypt(plaintext),
				  DiskService.write(data: ciphertextData, toFileName: WalletCacheService.walletCacheFileName) else {
				Logger.walletCache.error("encryptAndWriteToDisk - Unable to save wallet items")
				return false
			}
			
			return true
			
		} catch (let error) {
			Logger.walletCache.error("encryptAndWriteToDisk - Unable to save wallet items: \(error)")
			return false
		}
	}
	
	/**
	 Go to the file on disk (if present), decrypt its contents and retrieve a dictionary of `Wallet's with the key being the wallet address
	 - Returns: A dictionary of `Wallet` if present on disk
	 */
	public func readWalletsFromDiskAndDecrypt() -> [String: Wallet]? {
		guard let data = DiskService.readData(fromFileName: WalletCacheService.walletCacheFileName) else {
			Logger.walletCache.info("readWalletsFromDiskAndDecrypt - no cache file found, returning empty")
			return [:] // No such file
		}
		
		guard loadOrCreateKeys(),
			  let plaintext = try? decrypt(data),
			  let plaintextData = plaintext.data(using: .utf8) else {
			Logger.walletCache.error("readWalletsFromDiskAndDecrypt - Unable to read wallet items")
			return nil
		}
		
		do {
			/// Similar to the issue mentioned in `encryptAndWriteToDisk`, we can't ask `JSONEncoder` to encode an array of `Wallet`.
			/// We must read the raw JSON, extract the `type` field and use it to determine the appropriate class
			/// Once we have that, we simply call `JSONDecode` for each obj, with the correct class and put in an array
			var wallets: [String: Wallet] = [:]
			guard let jsonDict = try JSONSerialization.jsonObject(with: plaintextData, options: .allowFragments) as? [String: [String: Any]] else {
				Logger.walletCache.error("readWalletsFromDiskAndDecrypt - JSON did not conform to expected format")
				return [:]
			}
			
			for jsonObj in jsonDict.values {
				guard let type = WalletType(rawValue: (jsonObj["type"] as? String) ?? "") else {
					Logger.walletCache.error("readWalletsFromDiskAndDecrypt - Unable to parse wallet object of type: \((jsonObj["type"] as? String) ?? "")")
					continue
				}
				
				let jsonObjAsData = try JSONSerialization.data(withJSONObject: jsonObj, options: .fragmentsAllowed)
				
				switch type {
					case .regular, .regularShifted:
						let wallet = try JSONDecoder().decode(RegularWallet.self, from: jsonObjAsData)
						wallets[wallet.address] = wallet
						
					case .hd:
						let wallet = try JSONDecoder().decode(HDWallet.self, from: jsonObjAsData)
						wallets[wallet.address] = wallet
						
					case .social:
						let wallet = try JSONDecoder().decode(TorusWallet.self, from: jsonObjAsData)
						wallets[wallet.address] = wallet
						
					case .ledger:
						let wallet = try JSONDecoder().decode(LedgerWallet.self, from: jsonObjAsData)
						wallets[wallet.address] = wallet
				}
			}
			
			return wallets
			
		} catch (let error) {
			Logger.walletCache.error("readWalletsFromDiskAndDecrypt - Unable to read wallet items: \(error)")
			return nil
		}
	}
	
	/**
	 Write an ordered array of `WalletMetadata` to disk, replacing existing file if exists
	 */
	public func encryptAndWriteMetadataToDisk(_ metadata: WalletMetadataList) -> Bool {
		do {
			let jsonData = try JSONEncoder().encode(metadata)
			
			/// Take the JSON blob, encrypt and store on disk
			guard loadOrCreateKeys(),
				  let plaintext = String(data: jsonData, encoding: .utf8),
				  let ciphertextData = try? encrypt(plaintext),
				  DiskService.write(data: ciphertextData, toFileName: WalletCacheService.metadataCacheFileName) else {
				Logger.walletCache.error("encryptAndWriteMetadataToDisk - Unable to save wallet items")
				return false
			}
			
			return true
			
		} catch (let error) {
			Logger.walletCache.error("encryptAndWriteToDisk - Unable to save wallet items: \(error)")
			return false
		}
	}
	
	/**
	 Return an ordered array of `WalletMetadata` if present on disk
	 */
	public func readMetadataFromDiskAndDecrypt() -> WalletMetadataList {
		let emptyWalletList = WalletMetadataList(socialWallets: [], hdWallets: [], linearWallets: [], ledgerWallets: [], watchWallets: [])
		
		guard let data = DiskService.readData(fromFileName: WalletCacheService.metadataCacheFileName) else {
			Logger.walletCache.info("readMetadataFromDiskAndDecrypt - no cache file found, returning empty")
			return emptyWalletList // No such file
		}
		
		guard loadOrCreateKeys(),
			  let plaintext = try? decrypt(data),
			  let plaintextData = plaintext.data(using: .utf8) else {
			Logger.walletCache.error("readMetadataFromDiskAndDecrypt - Unable to read wallet items")
			return emptyWalletList
		}
		
		do {
			let metadata = try JSONDecoder().decode(WalletMetadataList.self, from: plaintextData)
			return metadata
			
		} catch (let error) {
			Logger.walletCache.error("readMetadataFromDiskAndDecrypt - Unable to read wallet items: \(error)")
			return emptyWalletList
		}
	}
}



// MARK: - Encryption

extension WalletCacheService {
	
	/**
	Load the key references from the secure enclave (or keychain), or create them if non exist
	- Returns: Bool, indicating if operation was successful
	*/
	public func loadOrCreateKeys() -> Bool {
		
		/// Can't use the secure enclave when running unit tests in SPM. For now, hacky workaround to just just mock ones
		if Thread.current.isRunningXCTest {
			Logger.walletCache.error("loadOrCreateKeys - loading mocks")
			let keyTuple = loadMockKeys()
			self.publicKey = keyTuple.public
			self.privateKey = keyTuple.private
			
			return true
		}
		
		
		/// Else create the real keys
		do {
			if let key = try loadKey() {
				privateKey = key
				publicKey = SecKeyCopyPublicKey(key)
				Logger.walletCache.info("loadOrCreateKeys - loaded")
				
			} else {
				let keyTuple = try createKeys()
				self.publicKey = keyTuple.public
				self.privateKey = keyTuple.private
				Logger.walletCache.info("loadOrCreateKeys - created")
			}
			
			return true
			
		} catch (let error) {
			Logger.walletCache.error("loadOrCreateKeys - Unable to load or create keys: \(error)")
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
	fileprivate func createKeys() throws -> (public: SecKey, private: SecKey?) {
		var error: Unmanaged<CFError>?
		
		// If not simulator, use secure encalve
		let privateKeyAccessControl: SecAccessControlCreateFlags = !CurrentDevice.isSimulator ?  [.privateKeyUsage] : []
		guard let privateKeyAccess = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, privateKeyAccessControl, &error) else {
			if let err = error {
				Logger.walletCache.error("createKeys - createWithFlags returned error")
				throw err.takeRetainedValue() as Error
				
			} else {
				Logger.walletCache.error("createKeys - createWithFlags failed for unknown reason")
				throw WalletCacheError.unableToAccessEnclaveOrKeychain
			}
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
		
		// If not simulator, use secure encalve
		if !CurrentDevice.isSimulator {
			Logger.walletCache.info("createKeys - Using secure enclave")
			commonKeyAttributes[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
			commonKeyAttributes[kSecPrivateKeyAttrs as String] = privateKeyAttributes
			privateKeyAttributes[kSecAttrAccessControl as String] = privateKeyAccessControl
		} else {
			Logger.walletCache.info("createKeys - unable to use secure enclave")
		}
		
		guard let privateKey = SecKeyCreateRandomKey(commonKeyAttributes as CFDictionary, &error) else {
			if let err = error {
				Logger.walletCache.info("createKeys - createRandom returned error")
				throw err.takeRetainedValue() as Error
				
			} else {
				Logger.walletCache.info("createKeys - createRandom errored for unknown reason")
				throw WalletCacheError.unableToCreatePrivateKey
			}
		}
		
		guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
			Logger.walletCache.info("createKeys - copy public failed")
			throw WalletCacheError.unableToCreatePrivateKey
		}
		
		return (public: publicKey, private: privateKey)
	}
	
	/// Can't use the secure enclave or keychain when running unit tests in SPM, due to no host application. For now, hacky workaround to just use hardcoded keys, and skip the generation, to allow testing over everything else
	fileprivate func loadMockKeys() -> (public: SecKey, private: SecKey?) {
		
		guard let mockPubData = Data.init(base64Encoded: "MIICCgKCAgEAnwNp78w93NLeUOD02O4hIHc+GsWrj+s+zyBCpJi3a754P+DGGfB/8k7PYvS7fYaTiDQ3SpkYfSBYthxLv37/5RW9+6/PBM/zWlHFL2sXk6rSWqs4CJ0q4Lp+PuJIIKtiLv5agrztAZZTIt0TMR5eYJeRO1GrjMfQU5KCpzXMU2h43TOdOQezsV93fxQou4SDBYfkX+MBRTHeV2o6FeoGJCj/D3unrOHJqeBkMTMbECNrho1yUb0PJVp8i3zdOFKmHW4h91Ftk/i6Bq8roR8tKtxlgcYrB691okSyD6ytoVE2agniI83OOPAKUNm7aigbz1ZtYiJ/RORtQD6myyYDcXKN8c2EfK3aqMDRT7289cdDTw58FZgaYoXG0SS6ffl6+xFCGEtI9L/QgCm1tdet/x1N1piVHenNyNz7wDePnIyaP8iJz3YAwoYlaI2n5i7V7b1ocz+r10d/8IRVFE3Sef3v2cN6VeIB/WjKLlvQErHIc5wFmzHaNslcemaAWtSK2bebYqQb53JOy1THyHoREFe5P7or4InEYnTZHT3PYQ1gYYzA7lNK5ytdFh84+qYaY9Q+quR9y6S+ELoRA4bWsDhvnGy6h+3gixKJCewR2AWVU4jbqdxjPlBfUyZ78xTBdXFWqOjQO0KYvi395Y+0bBwEczN0GstxmLLJZc172uUCAwEAAQ=="),
			  
			  let mockPrivData = Data.init(base64Encoded: "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") else {
			fatalError("Can't create data")
		}
		
		WalletCacheService.encryptionAlgorithm = .rsaEncryptionOAEPSHA512AESGCM
		
		let keyDictPublic: [NSObject:NSObject] = [
			kSecAttrKeyType: kSecAttrKeyTypeRSA,
			kSecAttrKeyClass: kSecAttrKeyClassPublic,
			kSecAttrKeySizeInBits: NSNumber(value: 4096),
			kSecReturnPersistentRef: true as NSObject
		]
		
		let keyDictPrivate: [NSObject:NSObject] = [
			kSecAttrKeyType: kSecAttrKeyTypeRSA,
			kSecAttrKeyClass: kSecAttrKeyClassPrivate,
			kSecAttrKeySizeInBits: NSNumber(value: 4096),
			kSecReturnPersistentRef: true as NSObject
		]
		
		guard let mockPubKey = SecKeyCreateWithData(mockPubData as CFData, keyDictPublic as CFDictionary, nil) else {
			fatalError("Can't create public key")
		}
		
		guard let mockPrivKey = SecKeyCreateWithData(mockPrivData as CFData, keyDictPrivate as CFDictionary, nil) else {
			fatalError("Can't create private key")
		}
		
		return (public: mockPubKey, private: mockPrivKey)
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
		
		// If not simulator, use secure encalve
		if !CurrentDevice.isSimulator {
			Logger.walletCache.info("loadKey - Using secure enclave")
			query[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
			
		} else {
			Logger.walletCache.info("loadKey - unable to use secure enclave")
		}
		
		var key: CFTypeRef?
		if SecItemCopyMatching(query as CFDictionary, &key) == errSecSuccess {
			Logger.walletCache.info("loadKey - returning key")
			return (key as! SecKey)
		}
		
		Logger.walletCache.error("loadKey - returning nil")
		return nil
	}
	
	/**
	Delete a key from the secure enclave
	*/
	public func deleteKey() throws {
		let query = [kSecClass: kSecClassKey,kSecAttrApplicationTag: WalletCacheService.applicationKey] as [String: Any]
		let result = SecItemDelete(query as CFDictionary)
		
		if result != errSecSuccess {
			Logger.walletCache.error("Error removing keys. OSSatus - ˘\(result)")
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
			Logger.walletCache.error("encrypt - can't turn string to data")
			throw WalletCacheError.unableToParseAsUTF8Data
		}
		
		guard let pubKey = self.publicKey, SecKeyIsAlgorithmSupported(pubKey, .encrypt, WalletCacheService.encryptionAlgorithm) else {
			Logger.walletCache.error("encrypt - can't find public key")
			throw WalletCacheError.noPublicKeyFound
		}
		
		var error: Unmanaged<CFError>?
		
		//guard let cipherText = SecKeyCreateEncryptedData(pubKey, .rsaEncryptionOAEPSHA512AESGCM, data as CFData, &error) as Data? else {
		guard let cipherText = SecKeyCreateEncryptedData(pubKey, WalletCacheService.encryptionAlgorithm, data as CFData, &error) as Data? else {
			if let err = error {
				Logger.walletCache.error("encrypt - createEncryptedData failed with error")
				throw err.takeRetainedValue() as Error
				
			} else {
				Logger.walletCache.error("encrypt - createEncryptedData failed with unknown error")
				throw WalletCacheError.unableToEncrypt
			}
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
			Logger.walletCache.error("decrypt - can't find key")
			throw WalletCacheError.noPrivateKeyFound
		}
		
		var error: Unmanaged<CFError>?
		guard let clearText = SecKeyCreateDecryptedData(privateKey, WalletCacheService.encryptionAlgorithm, cipherText as CFData, &error) as Data?,
			  let textAsString = String(data: clearText, encoding: .utf8) else {
			if let err = error {
				Logger.walletCache.error("decrypt - decryptData failed with error")
				throw err.takeRetainedValue() as Error
				
			} else {
				Logger.walletCache.error("decrypt - decryptData failed for unknown reason")
				throw WalletCacheError.unableToDecrypt
				
			}
		}
		
		return textAsString
	}
}
