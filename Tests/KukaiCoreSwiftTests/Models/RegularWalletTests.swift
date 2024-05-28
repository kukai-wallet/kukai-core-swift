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
	
	func testSecretKeyImport() {
		let tz1UnencryptedSeed = RegularWallet(fromSecretKey: "edsk3KvXD8SVD9GCyU4jbzaFba2HZRad5pQ7ajL79n7rUoc3nfHv5t", passphrase: nil)
		XCTAssert(tz1UnencryptedSeed?.address == "tz1Qvpsq7UZWyQ4yabf9wGpG97testZCjoCH", tz1UnencryptedSeed?.address ?? "-")
		XCTAssert(tz1UnencryptedSeed?.privateKey.signingCurve == .ed25519, tz1UnencryptedSeed?.privateKey.signingCurve.rawValue ?? "-")
		
		let tz1UnencryptedSecret = RegularWallet(fromSecretKey: "edskRgQqEw17KMib89AzChu8DiJjmVeDfGmbCMpp7MpmhgTdNVvZ3TTaLfwNoux4hDDVeLxmEJxKiYE1cYp1Vgj6QATKaJa58L", passphrase: nil)
		XCTAssert(tz1UnencryptedSecret?.address == "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss", tz1UnencryptedSecret?.address ?? "-")
		XCTAssert(tz1UnencryptedSecret?.privateKey.signingCurve == .ed25519, tz1UnencryptedSecret?.privateKey.signingCurve.rawValue ?? "-")
		
		let tz1EncryptedSecret = RegularWallet(fromSecretKey: "edesk1L8uVSYd3aug7jbeynzErQTnBxq6G6hJwmeue3yUBt11wp3ULXvcLwYRzDp4LWWvRFNJXRi3LaN7WGiEGhh", passphrase: "pa55word")
		XCTAssert(tz1EncryptedSecret?.address == "tz1XztestvvcXSQZUbZav5YgVLRQbxC4GuMF", tz1EncryptedSecret?.address ?? "-")
		XCTAssert(tz1EncryptedSecret?.privateKey.signingCurve == .ed25519, tz1EncryptedSecret?.privateKey.signingCurve.rawValue ?? "-")
		
		let tz2UnencryptedSecret = RegularWallet(fromSecretKey: "spsk29hF9oJ6koNnnJMs1rXz4ynBs8hL8FyubTNPCu2tCVP5beGDbw", passphrase: nil)
		XCTAssert(tz2UnencryptedSecret?.address == "tz2RbUirt95UQHa9YyxcLj9GusNctxwn3Xi1", tz2UnencryptedSecret?.address ?? "-")
		XCTAssert(tz2UnencryptedSecret?.privateKey.signingCurve == .secp256k1, tz2UnencryptedSecret?.privateKey.signingCurve.rawValue ?? "-")
		
		let tz2EncryptedSecret = RegularWallet(fromSecretKey: "spesk1S5bMTCyH9z4mHSpnbn6DBY831DD6Rxgq7ANfEKkngoHSwy6B5odh942TKL6DtLbfTkpTHfSTAQu2d72Qd6", passphrase: "pa55word")
		XCTAssert(tz2EncryptedSecret?.address == "tz2C8APAjnQfffdkHssxdFRctkD1iPLGaGEg", tz2EncryptedSecret?.address ?? "-")
		XCTAssert(tz2EncryptedSecret?.privateKey.signingCurve == .secp256k1, tz2EncryptedSecret?.privateKey.signingCurve.rawValue ?? "-")
	}
}
