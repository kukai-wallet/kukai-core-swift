//
//  RegularWalletTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class RegularWalletTests: XCTestCase {

    override func setUpWithError() throws {
		
    }

    override func tearDownWithError() throws {
		
    }
	
	func testCreateWithMnemonic() {
		let wallet = RegularWallet(withMnemonic: MockConstants.mnemonic, passphrase: "")
		XCTAssert(wallet?.address == MockConstants.linearWalletEd255519.address, wallet?.address ?? "-")
		XCTAssert(wallet?.privateKey.bytes.toHexString() == MockConstants.linearWalletEd255519.privateKey, wallet?.privateKey.bytes.toHexString() ?? "-")
		XCTAssert(wallet?.publicKey.bytes.toHexString() == MockConstants.linearWalletEd255519.publicKey, wallet?.publicKey.bytes.toHexString() ?? "-")
	}
	
	func testCreateWithShiftedMnemonic() {
		let wallet = RegularWallet(withShiftedMnemonic: MockConstants.shiftedMnemonic, passphrase: "")
		XCTAssert(wallet?.address == MockConstants.shiftedWallet.address, wallet?.address ?? "-")
		XCTAssert(wallet?.privateKey.bytes.toHexString() == MockConstants.shiftedWallet.privateKey, wallet?.privateKey.bytes.toHexString() ?? "-")
		XCTAssert(wallet?.publicKey.bytes.toHexString() == MockConstants.shiftedWallet.publicKey, wallet?.publicKey.bytes.toHexString() ?? "-")
	}
	
	func testCreateWithMnemonicLength() {
		let wallet1 = RegularWallet(withMnemonicLength: .twelve, passphrase: "")
		XCTAssert(wallet1?.mnemonic?.words.count == 12, "\(wallet1?.mnemonic?.words.count ?? -1)")
		
		let wallet2 = RegularWallet(withMnemonicLength: .fifteen, passphrase: "")
		XCTAssert(wallet2?.mnemonic?.words.count == 15, "\(wallet2?.mnemonic?.words.count ?? -1)")
		
		let wallet3 = RegularWallet(withMnemonicLength: .twentyFour, passphrase: "")
		XCTAssert(wallet3?.mnemonic?.words.count == 24, "\(wallet3?.mnemonic?.words.count ?? -1)")
	}
	
	func testPassphrases() {
		let wallet = RegularWallet(withMnemonic: MockConstants.mnemonic, passphrase: MockConstants.passphrase)
		XCTAssert(wallet?.address == MockConstants.linearWalletEd255519_withPassphrase.address, wallet?.address ?? "-")
		XCTAssert(wallet?.privateKey.bytes.toHexString() == MockConstants.linearWalletEd255519_withPassphrase.privateKey, wallet?.privateKey.bytes.toHexString() ?? "-")
		XCTAssert(wallet?.publicKey.bytes.toHexString() == MockConstants.linearWalletEd255519_withPassphrase.publicKey, wallet?.publicKey.bytes.toHexString() ?? "-")
	}
	
	func testCurves() {
		let wallet1 = RegularWallet(withMnemonic: MockConstants.mnemonic, passphrase: "")
		XCTAssert(wallet1?.address == MockConstants.linearWalletEd255519.address, wallet1?.address ?? "-")
		XCTAssert(wallet1?.privateKey.bytes.toHexString() == MockConstants.linearWalletEd255519.privateKey, wallet1?.privateKey.bytes.toHexString() ?? "-")
		XCTAssert(wallet1?.publicKey.bytes.toHexString() == MockConstants.linearWalletEd255519.publicKey, wallet1?.publicKey.bytes.toHexString() ?? "-")
	}
	
	func testSigning() {
		let messageHex = MockConstants.messageToSign.data(using: .utf8)?.toHexString() ?? "-"
		MockConstants.defaultLinearWallet.sign(messageHex, isOperation: false) { result in
			guard let signedData = try? result.get() else {
				XCTFail("No signature: \(result.getFailure())")
				return
			}
			
			XCTAssert(signedData.toHexString() == MockConstants.linearWalletEd255519.signedData, signedData.toHexString())
		}
	}
	
	func testBase58Encoding() {
		let encoded = MockConstants.defaultLinearWallet.publicKeyBase58encoded()
		XCTAssert(encoded == MockConstants.linearWalletEd255519.base58Encoded, encoded)
	}
}
