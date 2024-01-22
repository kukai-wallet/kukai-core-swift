//
//  WalletCacheServiceTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
import KukaiCryptoSwift
@testable import KukaiCoreSwift

class WalletCacheServiceTests: XCTestCase {
	
	let walletCacheService = WalletCacheService()
	
	
	
    override func setUpWithError() throws {
		
    }

    override func tearDownWithError() throws {
		
    }
	
	// Can't run these tests without a host application, which SPM doesn't support. Need to investigate a workaround
	func testCache() {
		XCTAssert(walletCacheService.deleteAllCacheAndKeys())
		
		// Check its empty to begin with
		XCTAssert(walletCacheService.readWalletsFromDiskAndDecrypt()?.count == 0)
		
		// Check we can write wallet objects
		XCTAssert((try? walletCacheService.cache(wallet: MockConstants.defaultLinearWallet, childOfIndex: nil, backedUp: false)) != nil)
		XCTAssert((try? walletCacheService.cache(wallet: MockConstants.defaultHdWallet, childOfIndex: nil, backedUp: false)) != nil)
		
		// Check it fails if we try add the same wallet a second time
		XCTAssert((try? walletCacheService.cache(wallet: MockConstants.defaultHdWallet, childOfIndex: nil, backedUp: false)) == nil)
		
		// Check they have been stored
		XCTAssert(walletCacheService.readWalletsFromDiskAndDecrypt()?.count == 2)
		
		// Check they can be parsed
		let wallet1 = walletCacheService.fetchWallet(forAddress: MockConstants.defaultLinearWallet.address)
		let wallet2 = walletCacheService.fetchWallet(forAddress: MockConstants.defaultHdWallet.address)
		
		XCTAssert(wallet1 != nil)
		XCTAssert(wallet1?.address == MockConstants.defaultLinearWallet.address, wallet1?.address ?? "-")
		XCTAssert(wallet2 != nil)
		XCTAssert(wallet2?.address == MockConstants.defaultHdWallet.address, wallet2?.address ?? "-")
		
		// Check that the underlying keys were reconstructed correctly
		let regular = wallet1 as? RegularWallet
		let hd = wallet2 as? HDWallet
		
		XCTAssert(regular?.privateKey.bytes.toHexString() == MockConstants.linearWalletEd255519.privateKey, regular?.privateKey.bytes.toHexString() ?? "-")
		XCTAssert(regular?.publicKey.bytes.toHexString() == MockConstants.linearWalletEd255519.publicKey, regular?.publicKey.bytes.toHexString() ?? "-")
		XCTAssert(hd?.privateKey.bytes.hexString == MockConstants.hdWallet.privateKey, hd?.privateKey.bytes.hexString ?? "-")
		XCTAssert(hd?.publicKey.bytes.hexString == MockConstants.hdWallet.publicKey, hd?.publicKey.bytes.hexString ?? "-")
		
		
		// Check they are deleted
		XCTAssert(walletCacheService.deleteAllCacheAndKeys())
		
		// Check its empty again
		XCTAssert(walletCacheService.readWalletsFromDiskAndDecrypt()?.count == 0)
	}
	
	func testFetch() {
		XCTAssert(walletCacheService.deleteAllCacheAndKeys())
		
		// Check its empty to begin with
		XCTAssert(walletCacheService.readWalletsFromDiskAndDecrypt()?.count == 0)
		
		// Check we can write wallet objects
		XCTAssert((try? walletCacheService.cache(wallet: MockConstants.defaultLinearWallet, childOfIndex: nil, backedUp: false)) != nil)
		XCTAssert((try? walletCacheService.cache(wallet: MockConstants.defaultHdWallet, childOfIndex: nil, backedUp: false)) != nil)
		
		// Check they have been stored
		XCTAssert(walletCacheService.readWalletsFromDiskAndDecrypt()?.count == 2)
		
		// Check they can be parsed
		let wallet = walletCacheService.fetchWallet(forAddress: MockConstants.defaultLinearWallet.address)
		
		XCTAssert(wallet != nil)
		XCTAssert(wallet?.address == MockConstants.defaultLinearWallet.address, wallet?.address ?? "-")
		
		let wallet2 = walletCacheService.fetchWallet(forAddress: MockConstants.defaultHdWallet.address)
		
		XCTAssert(wallet2 != nil)
		XCTAssert(wallet2?.address == MockConstants.defaultHdWallet.address, wallet2?.address ?? "-")
		
		// Clean up
		XCTAssert(walletCacheService.deleteAllCacheAndKeys())
	}
	
	func testRemove() {
		XCTAssert(walletCacheService.deleteAllCacheAndKeys())
		
		// Check its empty to begin with
		XCTAssert(walletCacheService.readWalletsFromDiskAndDecrypt()?.count == 0)
		
		// Check we can write wallet objects
		XCTAssert((try? walletCacheService.cache(wallet: MockConstants.defaultLinearWallet, childOfIndex: nil, backedUp: false)) != nil)
		XCTAssert((try? walletCacheService.cache(wallet: MockConstants.defaultHdWallet, childOfIndex: nil, backedUp: false)) != nil)
		
		// Rmeove Linear
		XCTAssert(walletCacheService.deleteWallet(withAddress: MockConstants.defaultLinearWallet.address, parentIndex: nil))
		XCTAssert(walletCacheService.readWalletsFromDiskAndDecrypt()?.count == 1)
		
		// Rmeove HD
		XCTAssert(walletCacheService.deleteWallet(withAddress: MockConstants.defaultHdWallet.address, parentIndex: nil))
		XCTAssert(walletCacheService.readWalletsFromDiskAndDecrypt()?.count == 0)
		
		// Add 2 children to the HDWallet
		XCTAssert((try? walletCacheService.cache(wallet: MockConstants.defaultHdWallet, childOfIndex: nil, backedUp: false)) != nil)
		XCTAssert((try? walletCacheService.cache(wallet: MockConstants.defaultHdWallet.createChild(accountIndex: 1) ?? MockConstants.defaultHdWallet, childOfIndex: 0, backedUp: false)) != nil)
		XCTAssert((try? walletCacheService.cache(wallet: MockConstants.defaultHdWallet.createChild(accountIndex: 2) ?? MockConstants.defaultHdWallet, childOfIndex: 0, backedUp: false)) != nil)
		
		// Delete the first child
		XCTAssert(walletCacheService.deleteWallet(withAddress: MockConstants.hdWallet.childWalletAddresses[0], parentIndex: 0))
		
		let walletMetadata = walletCacheService.readMetadataFromDiskAndDecrypt()
		XCTAssert(walletMetadata.hdWallets[0].children.count == 1)
		XCTAssert(walletMetadata.hdWallets[0].children[0].address == MockConstants.hdWallet.childWalletAddresses[1])
		
		// Clean up
		XCTAssert(walletCacheService.deleteAllCacheAndKeys())
	}
	
	func testDerivationPaths() {
		let wallet = HDWallet(withMnemonic: MockConstants.mnemonic, passphrase: MockConstants.passphrase, derivationPath: MockConstants.hdWallet_hardened_change.derivationPath)!
		XCTAssert((try? walletCacheService.cache(wallet: wallet, childOfIndex: nil, backedUp: false)) != nil)
		
		let wallet1 = walletCacheService.fetchWallet(forAddress: wallet.address) as? HDWallet
		XCTAssert(wallet1 != nil)
		XCTAssert(wallet1?.address == MockConstants.hdWallet_hardened_change.address, wallet1?.address ?? "-")
		XCTAssert(wallet1?.derivationPath == MockConstants.hdWallet_hardened_change.derivationPath, wallet1?.derivationPath ?? "-")
		XCTAssert(walletCacheService.deleteAllCacheAndKeys())
	}
	
	func testPassphrase() {
		let wallet = RegularWallet(withMnemonic: MockConstants.mnemonic, passphrase: MockConstants.passphrase)!
		XCTAssert((try? walletCacheService.cache(wallet: wallet, childOfIndex: nil, backedUp: false)) != nil)
		
		let wallet1 = walletCacheService.fetchWallet(forAddress: wallet.address)
		XCTAssert(wallet1 != nil)
		XCTAssert(wallet1?.address == MockConstants.linearWalletEd255519_withPassphrase.address, wallet1?.address ?? "-")
		XCTAssert(walletCacheService.deleteAllCacheAndKeys())
	}
	
	func testHDWalletNaming() {
		XCTAssert(walletCacheService.deleteAllCacheAndKeys())
		
		let mnemonic = try! Mnemonic(numberOfWords: .twentyFour)
		let hdWallet1 = HDWallet(withMnemonic: mnemonic, passphrase: "")!
		let hdWallet2 = HDWallet(withMnemonic: mnemonic, passphrase: "a")!
		let hdWallet3 = HDWallet(withMnemonic: mnemonic, passphrase: "ab")!
		let hdWallet4 = HDWallet(withMnemonic: mnemonic, passphrase: "abc")!
		
		
		// Set 2 wallets
		let _ = try? walletCacheService.cache(wallet: hdWallet1, childOfIndex: nil, backedUp: false)
		var list = walletCacheService.readMetadataFromDiskAndDecrypt()
		let groupName1 = list.metadata(forAddress: hdWallet1.address)?.hdWalletGroupName
		XCTAssert(groupName1 == "HD Wallet 1", groupName1 ?? "-")
		
		let _ = try? walletCacheService.cache(wallet: hdWallet2, childOfIndex: nil, backedUp: false)
		list = walletCacheService.readMetadataFromDiskAndDecrypt()
		let groupName2 = list.metadata(forAddress: hdWallet2.address)?.hdWalletGroupName
		XCTAssert(groupName2 == "HD Wallet 2", groupName2 ?? "-")
		
		
		// Update one and check
		let _ = list.set(hdWalletGroupName: "Blah 2", forAddress: hdWallet2.address)
		let _ = walletCacheService.encryptAndWriteMetadataToDisk(list)
		
		list = walletCacheService.readMetadataFromDiskAndDecrypt()
		let groupName3 = list.metadata(forAddress: hdWallet2.address)?.hdWalletGroupName
		XCTAssert(groupName3 == "Blah 2", groupName3 ?? "-")
		
		
		// Add another to check did it reuse the name "HD Wallet 2"
		let _ = try? walletCacheService.cache(wallet: hdWallet3, childOfIndex: nil, backedUp: false)
		list = walletCacheService.readMetadataFromDiskAndDecrypt()
		let groupName4 = list.metadata(forAddress: hdWallet3.address)?.hdWalletGroupName
		XCTAssert(groupName4 == "HD Wallet 2", groupName4 ?? "-")
		
		
		// Change all names and add 4th
		let _ = list.set(hdWalletGroupName: "Blah 1", forAddress: hdWallet1.address)
		let _ = list.set(hdWalletGroupName: "Blah 3", forAddress: hdWallet3.address)
		let _ = walletCacheService.encryptAndWriteMetadataToDisk(list)
		
		let _ = try? walletCacheService.cache(wallet: hdWallet4, childOfIndex: nil, backedUp: false)
		list = walletCacheService.readMetadataFromDiskAndDecrypt()
		let groupName5 = list.metadata(forAddress: hdWallet4.address)?.hdWalletGroupName
		XCTAssert(groupName5 == "HD Wallet 4", groupName5 ?? "-")
	}
	
	func testMetadata() {
		let mainentDomain = [TezosDomainsReverseRecord(id: "123", address: "tz1abc123", owner: "tz1abc123", expiresAtUtc: nil, domain: TezosDomainsDomain(name: "blah.tez", address: "tz1abc123"))]
		let ghostnetDomain = [TezosDomainsReverseRecord(id: "123", address: "tz1abc123", owner: "tz1abc123", expiresAtUtc: nil, domain: TezosDomainsDomain(name: "blah.gho", address: "tz1abc123"))]
		let metadata1 = WalletMetadata(address: "tz1abc123", hdWalletGroupName: nil, mainnetDomains: mainentDomain, ghostnetDomains: ghostnetDomain, type: .hd, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: "", backedUp: true)
		
		XCTAssert(metadata1.hasMainnetDomain())
		XCTAssert(metadata1.hasGhostnetDomain())
		XCTAssert(metadata1.hasDomain(onNetwork: TezosNodeClientConfig.NetworkType.mainnet))
		XCTAssert(metadata1.hasDomain(onNetwork: TezosNodeClientConfig.NetworkType.testnet))
		XCTAssert(metadata1.mainnetDomains?.first?.domain.name == "blah.tez")
		XCTAssert(metadata1.ghostnetDomains?.first?.domain.name == "blah.gho")
		XCTAssert(metadata1.primaryMainnetDomain()?.domain.name == "blah.tez")
		XCTAssert(metadata1.primaryGhostnetDomain()?.domain.name == "blah.gho")
		XCTAssert(metadata1.primaryDomain(onNetwork: .mainnet)?.domain.name == "blah.tez")
		XCTAssert(metadata1.primaryDomain(onNetwork: .testnet)?.domain.name == "blah.gho")
		
		
		
		let metadata2 = WalletMetadata(address: "tz1def456", hdWalletGroupName: nil, type: .hd, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: "", backedUp: true)
		
		XCTAssert(!metadata2.hasMainnetDomain())
		XCTAssert(!metadata2.hasGhostnetDomain())
	}
	
	func testMetadataList() {
		let mainentDomain = TezosDomainsReverseRecord(id: "123", address: "tz1abc123", owner: "tz1abc123", expiresAtUtc: nil, domain: TezosDomainsDomain(name: "blah.tez", address: "tz1abc123"))
		let ghostnetDomain = TezosDomainsReverseRecord(id: "123", address: "tz1abc123", owner: "tz1abc123", expiresAtUtc: nil, domain: TezosDomainsDomain(name: "blah.gho", address: "tz1abc123"))
		let child = WalletMetadata(address: "tz1child", hdWalletGroupName: nil, type: .hd, children: [], isChild: true, isWatchOnly: false, bas58EncodedPublicKey: "", backedUp: true)
		let updatedWatch = WalletMetadata(address: "tz1jkl", hdWalletGroupName: nil, mainnetDomains: [], ghostnetDomains: [], type: .hd, children: [], isChild: false, isWatchOnly: true, bas58EncodedPublicKey: "blah", backedUp: true)
		
		let hd: [WalletMetadata] = [
			WalletMetadata(address: "tz1abc123", hdWalletGroupName: nil, mainnetDomains: [], ghostnetDomains: [], type: .hd, children: [child], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: "", backedUp: true)
		]
		let social: [WalletMetadata] = [
			WalletMetadata(address: "tz1def", hdWalletGroupName: nil, socialUsername: "test@gmail.com", socialType: .google, type: .social, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: "", backedUp: true)
		]
		let linear: [WalletMetadata] = [
			WalletMetadata(address: "tz1ghi", hdWalletGroupName: nil, type: .regular, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: "", backedUp: true)
		]
		let watch: [WalletMetadata] = [
			WalletMetadata(address: "tz1jkl", hdWalletGroupName: nil, type: .hd, children: [], isChild: false, isWatchOnly: true, bas58EncodedPublicKey: "", backedUp: true)
		]
		
		var list = WalletMetadataList(socialWallets: social, hdWallets: hd, linearWallets: linear, ledgerWallets: [], watchWallets: watch)
		
		let addresses = list.addresses()
		XCTAssert(addresses == ["tz1def", "tz1abc123", "tz1child", "tz1ghi", "tz1jkl"], addresses.description)
		
		let allMeta = list.allMetadata()
		XCTAssert(allMeta.count == 4, allMeta.count.description)
		
		let allSeedMeta = list.allMetadata(onlySeedBased: true)
		XCTAssert(allSeedMeta.count == 2, allSeedMeta.count.description)
		
		let count = list.count()
		XCTAssert(count == 5, count.description)
		
		let first = list.firstMetadata()
		XCTAssert(first?.address == "tz1def", first?.address ?? "-")
		
		let metaForAddress = list.metadata(forAddress: "tz1jkl")
		XCTAssert(metaForAddress?.address == "tz1jkl", metaForAddress?.address ?? "-")
		
		let _ = list.set(hdWalletGroupName: "Test", forAddress: "tz1abc123")
		let updatedMeta = list.metadata(forAddress: "tz1abc123")
		XCTAssert(updatedMeta?.hdWalletGroupName == "Test", updatedMeta?.hdWalletGroupName ?? "-")
		
		let _ = list.set(nickname: "Testy", forAddress: "tz1abc123")
		let updatedMeta2 = list.metadata(forAddress: "tz1abc123")
		XCTAssert(updatedMeta2?.walletNickname == "Testy", updatedMeta?.walletNickname ?? "-")
		
		let _ = list.set(mainnetDomain: mainentDomain, ghostnetDomain: ghostnetDomain, forAddress: "tz1abc123")
		let updatedMeta3 = list.metadata(forAddress: "tz1abc123")
		XCTAssert(updatedMeta3?.hasMainnetDomain() == true)
		XCTAssert(updatedMeta3?.hasGhostnetDomain() == true)
		
		let _ = list.update(address: "tz1jkl", with: updatedWatch)
		let updatedMeta4 = list.metadata(forAddress: "tz1jkl")
		XCTAssert(updatedMeta4?.bas58EncodedPublicKey == "blah")
	}
	
	func testWatchWallet() {
		XCTAssert(walletCacheService.deleteAllCacheAndKeys())
		
		let watchWallet = WalletMetadata(address: "tz1jkl", hdWalletGroupName: nil, mainnetDomains: [], ghostnetDomains: [], type: .hd, children: [], isChild: false, isWatchOnly: true, bas58EncodedPublicKey: "", backedUp: true)
		XCTAssert(walletCacheService.cacheWatchWallet(metadata: watchWallet))
		
		let list =  walletCacheService.readMetadataFromDiskAndDecrypt()
		let watch = list.watchWallets
		XCTAssert(watch.count == 1, watch.count.description)
	}
}
