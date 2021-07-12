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
		
		// Check they have been stored
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 2)
		
		// Check they can be parsed
		let wallets = walletCacheService.fetchWallets()
		
		XCTAssert(wallets != nil)
		XCTAssert(wallets?.first?.address == MockConstants.defaultLinearWallet.address, wallets?.first?.address ?? "-")
		XCTAssert(wallets?.last?.address == MockConstants.defaultHdWallet.address, wallets?.first?.address ?? "-")
		
		// Check they are deleted
		XCTAssert(walletCacheService.deleteCacheAndKeys())
		
		// Check its empty again
		XCTAssert(walletCacheService.readFromDiskAndDecrypt()?.count == 0)
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
