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
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 0)
		
		// Check we can write wallet objects
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultLinearWallet, childOfIndex: nil))
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultHdWallet, childOfIndex: nil))
		
		// Check it fails if we try add the same wallet a second time
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultHdWallet, childOfIndex: nil) == false)
		
		// Check they have been stored
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 2)
		
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
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 0)
	}
	
	func testFetch() {
		XCTAssert(walletCacheService.deleteAllCacheAndKeys())
		
		// Check its empty to begin with
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 0)
		
		// Check we can write wallet objects
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultLinearWallet, childOfIndex: nil))
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultHdWallet, childOfIndex: nil))
		
		// Check they have been stored
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 2)
		
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
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 0)
		
		// Check we can write wallet objects
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultLinearWallet, childOfIndex: nil))
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultHdWallet, childOfIndex: nil))
		
		// Rmeove Linear
		XCTAssert(walletCacheService.deleteWallet(withAddress: MockConstants.defaultLinearWallet.address, parentIndex: nil))
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 1)
		
		// Rmeove HD
		XCTAssert(walletCacheService.deleteWallet(withAddress: MockConstants.defaultHdWallet.address, parentIndex: nil))
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 0)
		
		// Add 2 children to the HDWallet
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultHdWallet, childOfIndex: nil))
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultHdWallet.createChild(accountIndex: 1) ?? MockConstants.defaultHdWallet, childOfIndex: 0))
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultHdWallet.createChild(accountIndex: 2) ?? MockConstants.defaultHdWallet, childOfIndex: 0))
		
		// Delete the first child
		XCTAssert(walletCacheService.deleteWallet(withAddress: MockConstants.hdWallet.childWalletAddresses[0], parentIndex: 0))
		
		let walletMetadata = walletCacheService.readNonsensitive()
		XCTAssert(walletMetadata.hdWallets[0].children.count == 1)
		XCTAssert(walletMetadata.hdWallets[0].children[0].address == MockConstants.hdWallet.childWalletAddresses[1])
		
		// Clean up
		XCTAssert(walletCacheService.deleteAllCacheAndKeys())
	}
	
	func testCurves() {
		let wallet = RegularWallet(withMnemonic: MockConstants.mnemonic, passphrase: "", ellipticalCurve: .secp256k1)!
		XCTAssert(walletCacheService.cache(wallet: wallet, childOfIndex: nil))
		
		let wallet1 = walletCacheService.fetchWallet(forAddress: wallet.address)
		XCTAssert(wallet1 != nil)
		XCTAssert(wallet1?.address == MockConstants.linearWalletSecp256k1.address, wallet1?.address ?? "-")
		XCTAssert(walletCacheService.deleteAllCacheAndKeys())
	}
	
	func testDerivationPaths() {
		let wallet = HDWallet(withMnemonic: MockConstants.mnemonic, passphrase: MockConstants.passphrase, derivationPath: MockConstants.hdWallet_hardened_change.derivationPath)!
		XCTAssert(walletCacheService.cache(wallet: wallet, childOfIndex: nil))
		
		let wallet1 = walletCacheService.fetchWallet(forAddress: wallet.address) as? HDWallet
		XCTAssert(wallet1 != nil)
		XCTAssert(wallet1?.address == MockConstants.hdWallet_hardened_change.address, wallet1?.address ?? "-")
		XCTAssert(wallet1?.derivationPath == MockConstants.hdWallet_hardened_change.derivationPath, wallet1?.derivationPath ?? "-")
		XCTAssert(walletCacheService.deleteAllCacheAndKeys())
	}
	
	func testPassphrase() {
		let wallet = RegularWallet(withMnemonic: MockConstants.mnemonic, passphrase: MockConstants.passphrase)!
		XCTAssert(walletCacheService.cache(wallet: wallet, childOfIndex: nil))
		
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
		let _ = walletCacheService.cache(wallet: hdWallet1, childOfIndex: nil)
		var list = walletCacheService.readNonsensitive()
		let groupName1 = list.metadata(forAddress: hdWallet1.address)?.hdWalletGroupName
		XCTAssert(groupName1 == "HD Wallet 1", groupName1 ?? "-")
		
		let _ = walletCacheService.cache(wallet: hdWallet2, childOfIndex: nil)
		list = walletCacheService.readNonsensitive()
		let groupName2 = list.metadata(forAddress: hdWallet2.address)?.hdWalletGroupName
		XCTAssert(groupName2 == "HD Wallet 2", groupName2 ?? "-")
		
		
		// Update one and check
		let _ = list.set(hdWalletGroupName: "Blah 2", forAddress: hdWallet2.address)
		let _ = walletCacheService.writeNonsensitive(list)
		
		list = walletCacheService.readNonsensitive()
		let groupName3 = list.metadata(forAddress: hdWallet2.address)?.hdWalletGroupName
		XCTAssert(groupName3 == "Blah 2", groupName3 ?? "-")
		
		
		// Add another to check did it reuse the name "HD Wallet 2"
		let _ = walletCacheService.cache(wallet: hdWallet3, childOfIndex: nil)
		list = walletCacheService.readNonsensitive()
		let groupName4 = list.metadata(forAddress: hdWallet3.address)?.hdWalletGroupName
		XCTAssert(groupName4 == "HD Wallet 2", groupName4 ?? "-")
		
		
		// Change all names and add 4th
		let _ = list.set(hdWalletGroupName: "Blah 1", forAddress: hdWallet1.address)
		let _ = list.set(hdWalletGroupName: "Blah 3", forAddress: hdWallet3.address)
		let _ = walletCacheService.writeNonsensitive(list)
		
		let _ = walletCacheService.cache(wallet: hdWallet4, childOfIndex: nil)
		list = walletCacheService.readNonsensitive()
		let groupName5 = list.metadata(forAddress: hdWallet4.address)?.hdWalletGroupName
		XCTAssert(groupName5 == "HD Wallet 4", groupName5 ?? "-")
	}
}
