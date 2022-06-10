//
//  WalletCacheServiceTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class WalletCacheServiceTests: XCTestCase {
	
	let walletCacheService = WalletCacheService()
	
	
	
    override func setUpWithError() throws {
		
    }

    override func tearDownWithError() throws {
		
    }
	
	// Can't run these tests without a host application, which SPM doesn't support. Need to investigate a workaround
	func testCache() {
		XCTAssert(walletCacheService.deleteCacheAndKeys())
		
		// Check its empty to begin with
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 0)
		
		// Check we can write wallet objects
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultLinearWallet))
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultHdWallet))
		
		// Check it fails if we try add the same wallet a second time
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultHdWallet) == false)
		
		// Check they have been stored
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 2)
		
		// Check they can be parsed
		let wallets = walletCacheService.fetchWallets()
		
		XCTAssert(wallets != nil)
		XCTAssert(wallets?.first?.address == MockConstants.defaultLinearWallet.address, wallets?.first?.address ?? "-")
		XCTAssert(wallets?.last?.address == MockConstants.defaultHdWallet.address, wallets?.first?.address ?? "-")
		
		// Check that the underlying keys were reconstructed correctly
		let linear = (wallets?.first as? RegularWallet)
		let hd = (wallets?.last as? HDWallet)
		
		XCTAssert(linear?.privateKey.bytes.toHexString() == MockConstants.linearWalletEd255519.privateKey, linear?.privateKey.bytes.toHexString() ?? "-")
		XCTAssert(linear?.publicKey.bytes.toHexString() == MockConstants.linearWalletEd255519.publicKey, linear?.publicKey.bytes.toHexString() ?? "-")
		XCTAssert(hd?.privateKey.bytes.hexString == MockConstants.hdWallet.privateKey, hd?.privateKey.bytes.hexString ?? "-")
		XCTAssert(hd?.publicKey.bytes.hexString == MockConstants.hdWallet.publicKey, hd?.publicKey.bytes.hexString ?? "-")
		
		
		// Check they are deleted
		XCTAssert(walletCacheService.deleteCacheAndKeys())
		
		// Check its empty again
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 0)
	}
	
	func testFetch() {
		XCTAssert(walletCacheService.deleteCacheAndKeys())
		
		// Check its empty to begin with
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 0)
		
		// Check we can write wallet objects
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultLinearWallet))
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultHdWallet))
		
		// Check they have been stored
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 2)
		
		// Check they can be parsed
		let wallet = walletCacheService.fetchWallet(address: MockConstants.defaultLinearWallet.address)
		
		XCTAssert(wallet != nil)
		XCTAssert(wallet?.address == MockConstants.defaultLinearWallet.address, wallet?.address ?? "-")
		
		let wallet2 = walletCacheService.fetchWallet(address: MockConstants.defaultHdWallet.address)
		
		XCTAssert(wallet2 != nil)
		XCTAssert(wallet2?.address == MockConstants.defaultHdWallet.address, wallet2?.address ?? "-")
		
		// Clean up
		MockConstants.defaultHdWallet.childWallets = []
		XCTAssert(walletCacheService.deleteCacheAndKeys())
	}
	
	func testRemove() {
		XCTAssert(walletCacheService.deleteCacheAndKeys())
		
		// Check its empty to begin with
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 0)
		
		// Check we can write wallet objects
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultLinearWallet))
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultHdWallet))
		
		// Rmeove Linear
		XCTAssert(walletCacheService.deleteWallet(withAddress: MockConstants.defaultLinearWallet.address, parentHDWallet: nil))
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 1)
		
		// Rmeove HD
		XCTAssert(walletCacheService.deleteWallet(withAddress: MockConstants.defaultHdWallet.address, parentHDWallet: nil))
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 0)
		
		// Add 2 children to the HDWallet and then store
		let _ = MockConstants.defaultHdWallet.addNextChildWallet()
		let _ = MockConstants.defaultHdWallet.addNextChildWallet()
		
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultHdWallet))
		
		// Delete the first child
		XCTAssert(walletCacheService.deleteWallet(withAddress: MockConstants.hdWallet.childWalletAddresses[0], parentHDWallet: MockConstants.defaultHdWallet.address))
		
		let cachedWallet = (walletCacheService.fetchPrimaryWallet() as? HDWallet)
		XCTAssert(cachedWallet?.childWallets.count == 1)
		XCTAssert(cachedWallet?.childWallets[0].address == MockConstants.hdWallet.childWalletAddresses[1])
		
		// Clean up
		MockConstants.defaultHdWallet.childWallets = []
		XCTAssert(walletCacheService.deleteCacheAndKeys())
	}
	
	func testUpdate() {
		XCTAssert(walletCacheService.deleteCacheAndKeys())
		
		// Check its empty to begin with
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 0)
		
		// Check we can write wallet objects
		XCTAssert(walletCacheService.cache(wallet: MockConstants.defaultHdWallet))
		
		// Check what was stored
		let cachedWallet = (walletCacheService.fetchPrimaryWallet() as? HDWallet)
		XCTAssert(cachedWallet?.childWallets.count == 0)
		
		// Update and check again
		if let hdWallet = cachedWallet {
			XCTAssert(hdWallet.addNextChildWallet())
			XCTAssert(walletCacheService.update(hdWallet: hdWallet, atIndex: 0))
		} else {
			XCTFail("Failed to unwrap HDWallet")
		}
		
		let cachedWallet2 = (walletCacheService.fetchPrimaryWallet() as? HDWallet)
		XCTAssert(cachedWallet2?.childWallets.count == 1)
		
		// Clean up
		XCTAssert(walletCacheService.deleteCacheAndKeys())
	}
	
	func testCurves() {
		let wallet = RegularWallet(withMnemonic: MockConstants.mnemonic, passphrase: "", ellipticalCurve: .secp256k1)!
		
		XCTAssert(walletCacheService.cache(wallet: wallet))
		
		
		let wallets = walletCacheService.fetchWallets()
		XCTAssert(wallets != nil)
		XCTAssert(wallets?.first?.address == MockConstants.linearWalletSecp256k1.address, wallets?.first?.address ?? "-")
		XCTAssert(walletCacheService.deleteCacheAndKeys())
	}
	
	func testDerivationPaths() {
		let wallet = HDWallet(withMnemonic: MockConstants.mnemonic, passphrase: MockConstants.passphrase, derivationPath: MockConstants.hdWallet_hardened_change.derivationPath)!
		
		XCTAssert(walletCacheService.cache(wallet: wallet))
		
		let wallets = walletCacheService.fetchWallets()
		let hdWallet = (wallets?.first as? HDWallet)
		
		XCTAssert(wallets != nil)
		XCTAssert(hdWallet?.address == MockConstants.hdWallet_hardened_change.address, hdWallet?.address ?? "-")
		XCTAssert(hdWallet?.derivationPath == MockConstants.hdWallet_hardened_change.derivationPath, hdWallet?.derivationPath ?? "-")
		XCTAssert(walletCacheService.deleteCacheAndKeys())
	}
	
	func testPassphrase() {
		let wallet = RegularWallet(withMnemonic: MockConstants.mnemonic, passphrase: MockConstants.passphrase)!
		
		XCTAssert(walletCacheService.cache(wallet: wallet))
		
		
		let wallets = walletCacheService.fetchWallets()
		XCTAssert(wallets != nil)
		XCTAssert(wallets?.first?.address == MockConstants.linearWalletEd255519_withPassphrase.address, wallets?.first?.address ?? "-")
		XCTAssert(walletCacheService.deleteCacheAndKeys())
	}
}
