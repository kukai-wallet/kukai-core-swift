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

/// Container to store groups of WalletMetadata based on type
public struct WalletMetadataList: Codable, Hashable {
	public var socialWallets: [WalletMetadata]
	public var hdWallets: [WalletMetadata]
	public var linearWallets: [WalletMetadata]
	public var ledgerWallets: [WalletMetadata]
	public var watchWallets: [WalletMetadata]
	
	public init(socialWallets: [WalletMetadata], hdWallets: [WalletMetadata], linearWallets: [WalletMetadata], ledgerWallets: [WalletMetadata], watchWallets: [WalletMetadata]) {
		self.socialWallets = socialWallets
		self.hdWallets = hdWallets
		self.linearWallets = linearWallets
		self.ledgerWallets = ledgerWallets
		self.watchWallets = watchWallets
	}
	
	public func isEmpty() -> Bool {
		return socialWallets.isEmpty && hdWallets.isEmpty && linearWallets.isEmpty && ledgerWallets.isEmpty && watchWallets.isEmpty
	}
	
	public func firstMetadata() -> WalletMetadata? {
		if socialWallets.count > 0 {
			return socialWallets.first
			
		} else if hdWallets.count > 0 {
			return hdWallets.first
			
		} else if linearWallets.count > 0 {
			return linearWallets.first
			
		} else if ledgerWallets.count > 0 {
			return ledgerWallets.first
			
		} else if watchWallets.count > 0 {
			return watchWallets.first
		}
		
		return nil
	}
	
	public func metadata(forAddress address: String) -> WalletMetadata? {
		for metadata in socialWallets {
			if metadata.address == address { return metadata }
		}
		
		for metadata in hdWallets {
			if metadata.address == address { return metadata }
			
			for childMetadata in metadata.children {
				if childMetadata.address == address { return childMetadata }
			}
		}
		
		for metadata in linearWallets {
			if metadata.address == address { return metadata }
		}
		
		for metadata in ledgerWallets {
			if metadata.address == address { return metadata }
		}
		
		for metaData in watchWallets {
			if metaData.address == address { return metaData }
		}
		
		return nil
	}
	
	public mutating func update(address: String, with newMetadata: WalletMetadata) -> Bool {
		for (index, metadata) in socialWallets.enumerated() {
			if metadata.address == address { socialWallets[index] = newMetadata; return true }
		}
		
		for (index, metadata) in hdWallets.enumerated() {
			if metadata.address == address { hdWallets[index] = newMetadata; return true }
			
			for (childIndex, childMetadata) in metadata.children.enumerated() {
				if childMetadata.address == address {  hdWallets[index].children[childIndex] = newMetadata; return true }
			}
		}
		
		for (index, metadata) in linearWallets.enumerated() {
			if metadata.address == address { linearWallets[index] = newMetadata; return true }
		}
		
		for (index, metadata) in ledgerWallets.enumerated() {
			if metadata.address == address { ledgerWallets[index] = newMetadata; return true }
		}
		
		for (index, metadata) in watchWallets.enumerated() {
			if metadata.address == address { watchWallets[index] = newMetadata; return true }
		}
		
		return false
	}
	
	public mutating func set(mainnetDomain: TezosDomainsReverseRecord?, ghostnetDomain: TezosDomainsReverseRecord?, forAddress address: String) -> Bool {
		var meta = metadata(forAddress: address)
		
		if let mainnet = mainnetDomain {
			meta?.mainnetDomains = [mainnet]
		}
		
		if let ghostnet = ghostnetDomain {
			meta?.ghostnetDomains = [ghostnet]
		}
		
		if let meta = meta, update(address: address, with: meta) {
			return true
		}
		
		return false
	}
	
	public mutating func set(nickname: String?, forAddress address: String) -> Bool {
		var meta = metadata(forAddress: address)
		meta?.walletNickname = nickname
		
		if let meta = meta, update(address: address, with: meta) {
			return true
		}
		
		return false
	}
	
	public mutating func set(hdWalletGroupName: String, forAddress address: String) -> Bool {
		var meta = metadata(forAddress: address)
		meta?.hdWalletGroupName = hdWalletGroupName
		
		if let meta = meta, update(address: address, with: meta) {
			return true
		}
		
		return false
	}
	
	public func count() -> Int {
		var total = (socialWallets.count + linearWallets.count + ledgerWallets.count + watchWallets.count)
		
		for wallet in hdWallets {
			total += (1 + wallet.children.count)
		}
		
		return total
	}
	
	public func addresses() -> [String] {
		var temp: [String] = []
		
		for metadata in socialWallets {
			temp.append(metadata.address)
		}
		
		for metadata in hdWallets {
			temp.append(metadata.address)
			
			for childMetadata in metadata.children {
				temp.append(childMetadata.address)
			}
		}
		
		for metadata in linearWallets {
			temp.append(metadata.address)
		}
		
		for metadata in ledgerWallets {
			temp.append(metadata.address)
		}
		
		for metadata in watchWallets {
			temp.append(metadata.address)
		}
		
		return temp
	}
	
	public func allMetadata(onlySeedBased: Bool = false) -> [WalletMetadata] {
		var temp: [WalletMetadata] = []
		
		if !onlySeedBased {
			for metadata in socialWallets {
				temp.append(metadata)
			}
		}
		
		for metadata in hdWallets {
			temp.append(metadata)
		}
		
		for metadata in linearWallets {
			temp.append(metadata)
		}
		
		if !onlySeedBased {
			for metadata in ledgerWallets {
				temp.append(metadata)
			}
		}
		
		if !onlySeedBased {
			for metadata in watchWallets {
				temp.append(metadata)
			}
		}
		
		return temp
	}
}

/// Object to store UI related info about wallets, seperated from the wallet object itself to avoid issues merging together
public struct WalletMetadata: Codable, Hashable {
	public var address: String
	public var hdWalletGroupName: String?
	public var walletNickname: String?
	public var socialUsername: String?
	public var mainnetDomains: [TezosDomainsReverseRecord]?
	public var ghostnetDomains: [TezosDomainsReverseRecord]?
	public var socialType: TorusAuthProvider?
	public var type: WalletType
	public var children: [WalletMetadata]
	public var isChild: Bool
	public var isWatchOnly: Bool
	public var bas58EncodedPublicKey: String
	public var backedUp: Bool
	
	public func hasMainnetDomain() -> Bool {
		return (mainnetDomains ?? []).count > 0
	}
	
	public func hasGhostnetDomain() -> Bool {
		return (ghostnetDomains ?? []).count > 0
	}
	
	public func hasDomain(onNetwork network: TezosNodeClientConfig.NetworkType) -> Bool {
		if network == .mainnet {
			return hasMainnetDomain()
		} else {
			return hasGhostnetDomain()
		}
	}
	
	public func primaryMainnetDomain() -> TezosDomainsReverseRecord? {
		if let domains = mainnetDomains {
			return domains.first
		}
		
		return nil
	}
	
	public func primaryGhostnetDomain() -> TezosDomainsReverseRecord? {
		if let domains = ghostnetDomains {
			return domains.first
		}
		
		return nil
	}
	
	public func primaryDomain(onNetwork network: TezosNodeClientConfig.NetworkType) -> TezosDomainsReverseRecord? {
		if network == .mainnet {
			return primaryMainnetDomain()
		} else {
			return primaryGhostnetDomain()
		}
	}
	
	public init(address: String, hdWalletGroupName: String?, walletNickname: String? = nil, socialUsername: String? = nil, mainnetDomains: [TezosDomainsReverseRecord]? = nil, ghostnetDomains: [TezosDomainsReverseRecord]? = nil, socialType: TorusAuthProvider? = nil, type: WalletType, children: [WalletMetadata], isChild: Bool, isWatchOnly: Bool, bas58EncodedPublicKey: String, backedUp: Bool) {
		self.address = address
		self.hdWalletGroupName = hdWalletGroupName
		self.walletNickname = walletNickname
		self.socialUsername = socialUsername
		self.mainnetDomains = mainnetDomains
		self.ghostnetDomains = ghostnetDomains
		self.socialType = socialType
		self.type = type
		self.children = children
		self.isChild = isChild
		self.isWatchOnly = isWatchOnly
		self.bas58EncodedPublicKey = bas58EncodedPublicKey
		self.backedUp = backedUp
	}
	
	public static func == (lhs: WalletMetadata, rhs: WalletMetadata) -> Bool {
		return lhs.address == rhs.address
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(address)
	}
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
	fileprivate static var encryptionAlgorithm = SecKeyAlgorithm.eciesEncryptionCofactorX963SHA256AESGCM
	
	/// The application key used to identify the encryption keys
	fileprivate static let applicationKey = "app.kukai.kukai-core-swift.walletcache.encryption"
	
	/// The filename where the wallet data will be stored, encrypted
	fileprivate static let sensitiveCacheFileName = "kukai-core-wallets.txt"
	
	/// The filename where the public wallet data and in app metadata will be stored, unencrypted
	fileprivate static let nonsensitiveCacheFileName = "kukai-core-wallets-metadata.txt"
	
	
	
	
	
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
	public func cache<T: Wallet>(wallet: T, childOfIndex: Int?, backedUp: Bool) -> Bool {
		guard let existingWallets = readFromDiskAndDecrypt(), existingWallets[wallet.address] == nil else {
			os_log(.error, log: .walletCache, "cache - Unable to cache wallet, as can't decrypt existing wallets")
			return false
		}
		
		guard existingWallets[wallet.address] == nil else {
			os_log(.error, log: .walletCache, "cache - Unable to cache wallet, as wallet has no address")
			return false
		}
		
		var newWallets = existingWallets
		newWallets[wallet.address] = wallet
		
		var newMetadata = readNonsensitive()
		if let index = childOfIndex {
			if index >= newMetadata.hdWallets.count {
				os_log(.error, log: .walletCache, "WalletCacheService metadata insertion issue. Requested to add to HDWallet at index \"%@\", when there are currently only \"%@\" items", index, newMetadata.hdWallets.count)
				return false
			}
			
			newMetadata.hdWallets[index].children.append(WalletMetadata(address: wallet.address, hdWalletGroupName: nil, walletNickname: nil, socialUsername: nil, type: wallet.type, children: [], isChild: true, isWatchOnly: false, bas58EncodedPublicKey: wallet.publicKeyBase58encoded(), backedUp: backedUp))
			
		} else if let _ = wallet as? HDWallet {
			
			var newNumber = 0
			if let lastDefaultName = newMetadata.hdWallets.reversed().first(where: { $0.hdWalletGroupName?.prefix(10) == "HD Wallet " }) {
				let numberOnly = lastDefaultName.hdWalletGroupName?.replacingOccurrences(of: "HD Wallet ", with: "")
				newNumber = (Int(numberOnly ?? "0") ?? 0) + 1
			}
			
			if newNumber == 0 {
				newNumber = newMetadata.hdWallets.count + 1
			}
			
			newMetadata.hdWallets.append(WalletMetadata(address: wallet.address, hdWalletGroupName: "HD Wallet \(newNumber)", walletNickname: nil, socialUsername: nil, socialType: nil, type: wallet.type, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: wallet.publicKeyBase58encoded(), backedUp: backedUp))
			
		} else if let torusWallet = wallet as? TorusWallet {
			newMetadata.socialWallets.append(WalletMetadata(address: wallet.address, hdWalletGroupName: nil, walletNickname: nil, socialUsername: torusWallet.socialUserId ?? torusWallet.socialUsername, socialType: torusWallet.authProvider, type: wallet.type, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: wallet.publicKeyBase58encoded(), backedUp: backedUp))
			
		} else if let _ = wallet as? LedgerWallet {
			newMetadata.ledgerWallets.append(WalletMetadata(address: wallet.address, hdWalletGroupName: nil, walletNickname: nil, socialUsername: nil, socialType: nil, type: wallet.type, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: wallet.publicKeyBase58encoded(), backedUp: backedUp))
			
		} else {
			newMetadata.linearWallets.append(WalletMetadata(address: wallet.address, hdWalletGroupName: nil, walletNickname: nil, socialUsername: nil, socialType: nil, type: wallet.type, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: wallet.publicKeyBase58encoded(), backedUp: backedUp))
		}
		
		return encryptAndWriteToDisk(wallets: newWallets) && writeNonsensitive(newMetadata)
	}
	/**
	 Cahce a watch wallet metadata obj, only. Metadata cahcing handled via wallet cache method
	 */
	public func cacheWatchWallet(metadata: WalletMetadata) -> Bool {
		var list = readNonsensitive()
		list.watchWallets.append(metadata)
		
		return writeNonsensitive(list)
	}
	
	/**
	 Delete both a secure wallet entry and its related metadata object
	 - Parameter withAddress: The address of the wallet
	 - Parameter parentIndex: An optional `Int` to denote the index of the HD wallet that this wallet is a child of
	 - Returns: Bool, indicating if the storage was successful or not
	 */
	public func deleteWallet(withAddress: String, parentIndex: Int?) -> Bool {
		guard let existingWallets = readFromDiskAndDecrypt() else {
			os_log(.error, log: .walletCache, "Unable to fetch wallets")
			return false
		}
		
		var newWallets = existingWallets
		newWallets.removeValue(forKey: withAddress)
		
		var newMetadata = readNonsensitive()
		if let hdWalletIndex = parentIndex {
			guard hdWalletIndex < newMetadata.hdWallets.count, let childIndex = newMetadata.hdWallets[hdWalletIndex].children.firstIndex(where: { $0.address == withAddress }) else {
				os_log(.error, log: .walletCache, "Unable to locate wallet")
				return false
			}
			
			let _ = newMetadata.hdWallets[hdWalletIndex].children.remove(at: childIndex)
			
		} else {
			if let index = newMetadata.hdWallets.firstIndex(where: { $0.address == withAddress }) {
				
				// Children will be removed from metadata automatically, as they are contained inside the parent, however they won't from the encrypted cache
				// Remove them from encrypted first, then parent from metadata
				let children = newMetadata.hdWallets[index].children
				for child in children {
					newWallets.removeValue(forKey: child.address)
				}
				
				let _ = newMetadata.hdWallets.remove(at: index)
				
			} else if let index = newMetadata.socialWallets.firstIndex(where: { $0.address == withAddress }) {
				let _ = newMetadata.socialWallets.remove(at: index)
				
			} else if let index = newMetadata.linearWallets.firstIndex(where: { $0.address == withAddress }) {
				let _ = newMetadata.linearWallets.remove(at: index)
				
			} else if let index = newMetadata.ledgerWallets.firstIndex(where: { $0.address == withAddress }) {
				let _ = newMetadata.ledgerWallets.remove(at: index)
				
			} else {
				os_log(.error, log: .walletCache, "Unable to locate wallet")
				return false
			}
		}
		
		return encryptAndWriteToDisk(wallets: newWallets) && writeNonsensitive(newMetadata)
	}
	
	/**
	 Clear a watch wallet meatadata obj from the metadata cache only, does not affect actual wallet cache
	 */
	public func deleteWatchWallet(address: String) -> Bool {
		var list = readNonsensitive()
		list.watchWallets.removeAll(where: { $0.address == address })
		
		return writeNonsensitive(list)
	}
	
	/**
	 Find and return the secure object for a given address
	 - Returns: Optional object confirming to `Wallet` protocol
	 */
	public func fetchWallet(forAddress address: String) -> Wallet? {
		guard let cacheItems = readFromDiskAndDecrypt() else {
			os_log(.error, log: .walletCache, "Unable to read wallet items")
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
		
		return DiskService.delete(fileName: WalletCacheService.sensitiveCacheFileName) && DiskService.delete(fileName: WalletCacheService.nonsensitiveCacheFileName)
	}
	
	
	
	
	
	// MARK: - Read and Write
	
	/**
	 Take a dictionary of `Wallet` objects with their addresses as the key, serialise to JSON, encrypt and then write to disk
	 - Returns: Bool, indicating if the process was successful
	 */
	public func encryptAndWriteToDisk(wallets: [String: Wallet]) -> Bool {
		do {
			
			/// Because `Wallet` is a generic protocl, `JSONEncoder` can't be called on an array of it.
			/// Instead we must iterate through each item in the array, use its `type` to determine the corresponding class, and encode each one
			/// The only way to encode all of these items individually, without loosing data, is to convert each one to a JSON object, pack in an array and call `JSONSerialization.data`
			/// This results in a JSON blob containing all of the unique properties of each subclass, while allowing the caller to pass in any conforming `Wallet` type
			var jsonDict: [String: Any] = [:]
			var walletData: Data = Data()
			for wallet in wallets.values {
				switch wallet.type {
					case .regular:
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
				  DiskService.write(data: ciphertextData, toFileName: WalletCacheService.sensitiveCacheFileName) else {
				os_log(.error, log: .walletCache, "encryptAndWriteToDisk - Unable to save wallet items")
				return false
			}
			
			return true
			
		} catch (let error) {
			os_log(.error, log: .walletCache, "encryptAndWriteToDisk - Unable to save wallet items: %@", "\(error)")
			return false
		}
	}
	
	/**
	 Go to the file on disk (if present), decrypt its contents and retrieve a dictionary of `Wallet's with the key being the wallet address
	 - Returns: A dictionary of `Wallet` if present on disk
	 */
	public func readFromDiskAndDecrypt() -> [String: Wallet]? {
		guard let data = DiskService.readData(fromFileName: WalletCacheService.sensitiveCacheFileName) else {
			os_log(.info, log: .walletCache, "readFromDiskAndDecrypt - no cache file found, returning empty")
			return [:] // No such file
		}
		
		guard loadOrCreateKeys(),
			  let plaintext = try? decrypt(data),
			  let plaintextData = plaintext.data(using: .utf8) else {
			os_log(.error, log: .walletCache, "readFromDiskAndDecrypt - Unable to read wallet items")
			return nil
		}
		
		do {
			/// Similar to the issue mentioned in `encryptAndWriteToDisk`, we can't ask `JSONEncoder` to encode an array of `Wallet`.
			/// We must read the raw JSON, extract the `type` field and use it to determine the appropriate class
			/// Once we have that, we simply call `JSONDecode` for each obj, with the correct class and put in an array
			var wallets: [String: Wallet] = [:]
			guard let jsonDict = try JSONSerialization.jsonObject(with: plaintextData, options: .allowFragments) as? [String: [String: Any]] else {
				os_log(.error, log: .walletCache, "readFromDiskAndDecrypt - JSON did not conform to expected format")
				return [:]
			}
			
			for jsonObj in jsonDict.values {
				guard let type = WalletType(rawValue: (jsonObj["type"] as? String) ?? "") else {
					os_log("readFromDiskAndDecrypt - Unable to parse wallet object of type: %@", log: .walletCache, type: .error, (jsonObj["type"] as? String) ?? "")
					continue
				}
				
				let jsonObjAsData = try JSONSerialization.data(withJSONObject: jsonObj, options: .fragmentsAllowed)
				
				switch type {
					case .regular:
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
			os_log(.error, log: .walletCache, "readFromDiskAndDecrypt - Unable to read wallet items: %@", "\(error)")
			return nil
		}
	}
	
	/**
	 Write an ordered array of `WalletMetadata` to disk, replacing existing file if exists
	 */
	public func writeNonsensitive(_ metadata: WalletMetadataList) -> Bool {
		return DiskService.write(encodable: metadata, toFileName: WalletCacheService.nonsensitiveCacheFileName)
	}
	
	/**
	 Return an ordered array of `WalletMetadata` if present on disk
	 */
	public func readNonsensitive() -> WalletMetadataList {
		return DiskService.read(type: WalletMetadataList.self, fromFileName: WalletCacheService.nonsensitiveCacheFileName) ?? WalletMetadataList(socialWallets: [], hdWallets: [], linearWallets: [], ledgerWallets: [], watchWallets: [])
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
			os_log(.error, log: .walletCache, "loadOrCreateKeys - loading mocks")
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
				os_log(.default, log: .walletCache, "loadOrCreateKeys - loaded")
				
			} else {
				let keyTuple = try createKeys()
				self.publicKey = keyTuple.public
				self.privateKey = keyTuple.private
				os_log(.default, log: .walletCache, "loadOrCreateKeys - created")
			}
			
			return true
			
		} catch (let error) {
			os_log(.error, log: .walletCache, "loadOrCreateKeys - Unable to load or create keys: %@", "\(error)")
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
		
		let privateKeyAccessControl: SecAccessControlCreateFlags = [.privateKeyUsage]
		guard let privateKeyAccess = SecAccessControlCreateWithFlags(kCFAllocatorDefault, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, privateKeyAccessControl, &error) else {
			if let err = error {
				os_log(.error, log: .walletCache, "createKeys - createWithFlags returned error")
				throw err.takeRetainedValue() as Error
				
			} else {
				os_log(.error, log: .walletCache, "createKeys - createWithFlags failed for unknown reason")
				throw WalletCacheError.unableToAccessEnclaveOrKeychain
			}
		}
		
		let context = LAContext()
		context.interactionNotAllowed = false
		
		let privateKeyAttributes: [String: Any] = [
			kSecAttrApplicationTag as String: WalletCacheService.applicationKey,
			kSecAttrIsPermanent as String: true,
			kSecUseAuthenticationContext as String: context,
			kSecAttrAccessControl as String: privateKeyAccessControl
		]
		
		let commonKeyAttributes: [String: Any] = [
			kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
			kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
			kSecAttrKeySizeInBits as String: 256,
			kSecPrivateKeyAttrs as String: privateKeyAttributes
		]
		
		guard let privateKey = SecKeyCreateRandomKey(commonKeyAttributes as CFDictionary, &error) else {
			if let err = error {
				os_log(.default, log: .keychain, "createKeys - createRandom returned error")
				throw err.takeRetainedValue() as Error
				
			} else {
				os_log(.default, log: .keychain, "createKeys - createRandom errored for unknown reason")
				throw WalletCacheError.unableToCreatePrivateKey
			}
		}
		
		guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
			os_log(.default, log: .keychain, "createKeys - copy public failed")
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
			kSecReturnRef as String: true,
			kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave
		]
		
		var key: CFTypeRef?
		if SecItemCopyMatching(query as CFDictionary, &key) == errSecSuccess {
			os_log(.default, log: .walletCache, "loadKey - returning key")
			return (key as! SecKey)
		}
		
		os_log(.error, log: .walletCache, "loadKey - returning nil")
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
			os_log(.error, log: .walletCache, "encrypt - can't turn string to data")
			throw WalletCacheError.unableToParseAsUTF8Data
		}
		
		guard let pubKey = self.publicKey, SecKeyIsAlgorithmSupported(pubKey, .encrypt, WalletCacheService.encryptionAlgorithm) else {
			os_log(.error, log: .walletCache, "encrypt - can't find public key")
			throw WalletCacheError.noPublicKeyFound
		}
		
		var error: Unmanaged<CFError>?
		
		//guard let cipherText = SecKeyCreateEncryptedData(pubKey, .rsaEncryptionOAEPSHA512AESGCM, data as CFData, &error) as Data? else {
		guard let cipherText = SecKeyCreateEncryptedData(pubKey, WalletCacheService.encryptionAlgorithm, data as CFData, &error) as Data? else {
			if let err = error {
				os_log(.error, log: .walletCache, "encrypt - createEncryptedData failed with error")
				throw err.takeRetainedValue() as Error
				
			} else {
				os_log(.error, log: .walletCache, "encrypt - createEncryptedData failed with unknown error")
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
			os_log(.error, log: .walletCache, "decrypt - can't find key")
			throw WalletCacheError.noPrivateKeyFound
		}
		
		var error: Unmanaged<CFError>?
		guard let clearText = SecKeyCreateDecryptedData(privateKey, WalletCacheService.encryptionAlgorithm, cipherText as CFData, &error) as Data?,
			  let textAsString = String(data: clearText, encoding: .utf8) else {
			if let err = error {
				os_log(.error, log: .walletCache, "decrypt - decryptData failed with error")
				throw err.takeRetainedValue() as Error
				
			} else {
				os_log(.error, log: .walletCache, "decrypt - decryptData failed for unknown reason")
				throw WalletCacheError.unableToDecrypt
				
			}
		}
		
		return textAsString
	}
}
