//
//  LinearWalletTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class LinearWalletTests: XCTestCase {

    override func setUpWithError() throws {
		
    }

    override func tearDownWithError() throws {
		
    }
	
	func testCreateWithMnemonic() {
		let wallet = LinearWallet.create(withMnemonic: MockConstants.mnemonic, passphrase: "")
		XCTAssert(wallet?.address == MockConstants.linearWalletEd255519.address, wallet?.address ?? "-")
		XCTAssert(wallet?.privateKey.bytes.toHexString() == MockConstants.linearWalletEd255519.privateKey, wallet?.privateKey.bytes.toHexString() ?? "-")
		XCTAssert(wallet?.publicKey.bytes.toHexString() == MockConstants.linearWalletEd255519.publicKey, wallet?.publicKey.bytes.toHexString() ?? "-")
	}
	
	func testCreateWithMnemonicLength() {
		let wallet1 = LinearWallet.create(withMnemonicLength: .twelve, passphrase: "")
		XCTAssert(wallet1?.mnemonic.components(separatedBy: " ").count == 12, "\(wallet1?.mnemonic.components(separatedBy: " ").count ?? -1)")
		
		let wallet2 = LinearWallet.create(withMnemonicLength: .fifteen, passphrase: "")
		XCTAssert(wallet2?.mnemonic.components(separatedBy: " ").count == 15, "\(wallet2?.mnemonic.components(separatedBy: " ").count ?? -1)")
		
		let wallet3 = LinearWallet.create(withMnemonicLength: .twentyFour, passphrase: "")
		XCTAssert(wallet3?.mnemonic.components(separatedBy: " ").count == 24, "\(wallet3?.mnemonic.components(separatedBy: " ").count ?? -1)")
	}
	
	func testPassphrases() {
		let wallet = LinearWallet.create(withMnemonic: MockConstants.mnemonic, passphrase: MockConstants.passphrase)
		XCTAssert(wallet?.address == MockConstants.linearWalletEd255519_withPassphrase.address, wallet?.address ?? "-")
		XCTAssert(wallet?.privateKey.bytes.toHexString() == MockConstants.linearWalletEd255519_withPassphrase.privateKey, wallet?.privateKey.bytes.toHexString() ?? "-")
		XCTAssert(wallet?.publicKey.bytes.toHexString() == MockConstants.linearWalletEd255519_withPassphrase.publicKey, wallet?.publicKey.bytes.toHexString() ?? "-")
	}
	
	func testCurves() {
		let wallet1 = LinearWallet.create(withMnemonic: MockConstants.mnemonic, passphrase: "", ellipticalCurve: .ed25519)
		XCTAssert(wallet1?.address == MockConstants.linearWalletEd255519.address, wallet1?.address ?? "-")
		XCTAssert(wallet1?.privateKey.bytes.toHexString() == MockConstants.linearWalletEd255519.privateKey, wallet1?.privateKey.bytes.toHexString() ?? "-")
		XCTAssert(wallet1?.publicKey.bytes.toHexString() == MockConstants.linearWalletEd255519.publicKey, wallet1?.publicKey.bytes.toHexString() ?? "-")
		
		let wallet2 = LinearWallet.create(withMnemonic: MockConstants.mnemonic, passphrase: "", ellipticalCurve: .secp256k1)
		XCTAssert(wallet2?.address == MockConstants.linearWalletSecp256k1.address, wallet2?.address ?? "-")
		XCTAssert(wallet2?.privateKey.bytes.toHexString() == MockConstants.linearWalletSecp256k1.privateKey, wallet2?.privateKey.bytes.toHexString() ?? "-")
		XCTAssert(wallet2?.publicKey.bytes.toHexString() == MockConstants.linearWalletSecp256k1.publicKey, wallet2?.publicKey.bytes.toHexString() ?? "-")
	}
	
	func testSigning() {
		let messageHex = MockConstants.messageToSign.data(using: .utf8)?.toHexString() ?? "-"
		let signedData = MockConstants.defaultLinearWallet.sign(messageHex)
		XCTAssert(signedData?.toHexString() == MockConstants.linearWalletEd255519.signedData, signedData?.toHexString() ?? "-")
	}
	
	func testBase58Encoding() {
		let encoded = MockConstants.defaultLinearWallet.publicKeyBase58encoded()
		XCTAssert(encoded == MockConstants.linearWalletEd255519.base58Encoded, encoded)
	}
}
