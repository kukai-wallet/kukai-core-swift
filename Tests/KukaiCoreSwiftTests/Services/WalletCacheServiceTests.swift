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
		let linear = (wallets?.first as? LinearWallet)
		let hd = (wallets?.last as? HDWallet)
		
		XCTAssert(linear?.privateKey.bytes.toHexString() == MockConstants.linearWalletEd255519.privateKey, linear?.privateKey.bytes.toHexString() ?? "-")
		XCTAssert(linear?.publicKey.bytes.toHexString() == MockConstants.linearWalletEd255519.publicKey, linear?.publicKey.bytes.toHexString() ?? "-")
		XCTAssert(hd?.privateKey.data.toHexString() == MockConstants.hdWallet.privateKey, hd?.privateKey.data.toHexString() ?? "-")
		XCTAssert(hd?.publicKey.data.toHexString() == MockConstants.hdWallet.publicKey, hd?.publicKey.data.toHexString() ?? "-")
		
		
		// Check they are deleted
		XCTAssert(walletCacheService.deleteCacheAndKeys())
		
		// Check its empty again
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 0)
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
	
	func testCurves() {
		let wallet = LinearWallet(withMnemonic: MockConstants.mnemonic, passphrase: "", ellipticalCurve: .secp256k1)!
		
		XCTAssert(walletCacheService.cache(wallet: wallet))
		
		
		let wallets = walletCacheService.fetchWallets()
		XCTAssert(wallets != nil)
		XCTAssert(wallets?.first?.address == MockConstants.linearWalletSecp256k1.address, wallets?.first?.address ?? "-")
		XCTAssert(walletCacheService.deleteCacheAndKeys())
	}
	
	func testDerivationPaths() {
		let wallet = HDWallet(withMnemonic: MockConstants.mnemonic, passphrase: "", derivationPath: MockConstants.hdWallet_non_hardened.derivationPath)!
		
		XCTAssert(walletCacheService.cache(wallet: wallet))
		
		
		let wallets = walletCacheService.fetchWallets()
		let hdWallet = (wallets?.first as? HDWallet)
		
		XCTAssert(wallets != nil)
		XCTAssert(hdWallet?.address == MockConstants.hdWallet_non_hardened.address, hdWallet?.address ?? "-")
		XCTAssert(hdWallet?.derivationPath == MockConstants.hdWallet_non_hardened.derivationPath, hdWallet?.derivationPath ?? "-")
		XCTAssert(walletCacheService.deleteCacheAndKeys())
	}
	
	func testPassphrase() {
		let wallet = LinearWallet(withMnemonic: MockConstants.mnemonic, passphrase: MockConstants.passphrase)!
		
		XCTAssert(walletCacheService.cache(wallet: wallet))
		
		
		let wallets = walletCacheService.fetchWallets()
		XCTAssert(wallets != nil)
		XCTAssert(wallets?.first?.address == MockConstants.linearWalletEd255519_withPassphrase.address, wallets?.first?.address ?? "-")
		XCTAssert(walletCacheService.deleteCacheAndKeys())
	}
}
