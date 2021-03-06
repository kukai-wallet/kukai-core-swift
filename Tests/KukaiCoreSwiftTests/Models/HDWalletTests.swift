//
//  HDWalletTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class HDWalletTests: XCTestCase {

    override func setUpWithError() throws {
		
    }

    override func tearDownWithError() throws {
		
    }

	func testCreateWithMnemonic() {
		let wallet = HDWallet.create(withMnemonic: MockConstants.mnemonic, passphrase: "")
		XCTAssert(wallet?.address == MockConstants.hdWallet.address, wallet?.address ?? "-")
		XCTAssert(wallet?.privateKey.data.toHexString() == MockConstants.hdWallet.privateKey, wallet?.privateKey.data.toHexString() ?? "-")
		XCTAssert(wallet?.publicKey.data.toHexString() == MockConstants.hdWallet.publicKey, wallet?.publicKey.data.toHexString() ?? "-")
	}
	
	func testCreateWithMnemonicLength() {
		let wallet1 = HDWallet.create(withMnemonicLength: .twelve, passphrase: "")
		XCTAssert(wallet1?.mnemonic.components(separatedBy: " ").count == 12, "\(wallet1?.mnemonic.components(separatedBy: " ").count ?? -1)")
		
		let wallet2 = HDWallet.create(withMnemonicLength: .fifteen, passphrase: "")
		XCTAssert(wallet2?.mnemonic.components(separatedBy: " ").count == 15, "\(wallet2?.mnemonic.components(separatedBy: " ").count ?? -1)")
		
		let wallet3 = HDWallet.create(withMnemonicLength: .twentyFour, passphrase: "")
		XCTAssert(wallet3?.mnemonic.components(separatedBy: " ").count == 24, "\(wallet3?.mnemonic.components(separatedBy: " ").count ?? -1)")
	}
	
	func testPassphrases() {
		let wallet = HDWallet.create(withMnemonic: MockConstants.mnemonic, passphrase: MockConstants.passphrase)
		XCTAssert(wallet?.address == MockConstants.hdWallet_withPassphrase.address, wallet?.address ?? "-")
		XCTAssert(wallet?.privateKey.data.toHexString() == MockConstants.hdWallet_withPassphrase.privateKey, wallet?.privateKey.data.toHexString() ?? "-")
		XCTAssert(wallet?.publicKey.data.toHexString() == MockConstants.hdWallet_withPassphrase.publicKey, wallet?.publicKey.data.toHexString() ?? "-")
	}
	
	func testDerivationPaths() {
		let wallet1 = HDWallet.create(withMnemonic: MockConstants.mnemonic, passphrase: "", derivationPath: MockConstants.hdWallet_non_hardened.derivationPath)
		XCTAssert(wallet1?.address == MockConstants.hdWallet_non_hardened.address, wallet1?.address ?? "-")
		XCTAssert(wallet1?.privateKey.data.toHexString() == MockConstants.hdWallet_non_hardened.privateKey, wallet1?.privateKey.data.toHexString() ?? "-")
		XCTAssert(wallet1?.publicKey.data.toHexString() == MockConstants.hdWallet_non_hardened.publicKey, wallet1?.publicKey.data.toHexString() ?? "-")
		
		let wallet2 = HDWallet.create(withMnemonic: MockConstants.mnemonic, passphrase: MockConstants.passphrase, derivationPath: MockConstants.hdWallet_hardened_change.derivationPath)
		XCTAssert(wallet2?.address == MockConstants.hdWallet_hardened_change.address, wallet2?.address ?? "-")
		XCTAssert(wallet2?.privateKey.data.toHexString() == MockConstants.hdWallet_hardened_change.privateKey, wallet2?.privateKey.data.toHexString() ?? "-")
		XCTAssert(wallet2?.publicKey.data.toHexString() == MockConstants.hdWallet_hardened_change.publicKey, wallet2?.publicKey.data.toHexString() ?? "-")
	}
	
	func testSigning() {
		let messageHex = MockConstants.messageToSign.data(using: .utf8)?.toHexString() ?? "-"
		let signedData = MockConstants.defaultHdWallet.sign(messageHex)
		XCTAssert(signedData?.toHexString() == MockConstants.hdWallet.signedData, signedData?.toHexString() ?? "-")
	}
	
	func testBase58Encoding() {
		let encoded = MockConstants.defaultHdWallet.publicKeyBase58encoded()
		XCTAssert(encoded == MockConstants.hdWallet.base58Encoded, encoded)
	}
}
