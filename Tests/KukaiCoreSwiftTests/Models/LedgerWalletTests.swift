//
//  LedgerWalletTests.swift
//  
//
//  Created by Simon Mcloughlin on 01/10/2021.
//

import XCTest
@testable import KukaiCoreSwift
@testable import KukaiCryptoSwift

class LedgerWalletTests: XCTestCase {

	override func setUpWithError() throws {
		
	}

	override func tearDownWithError() throws {
		
	}
	
	func testCreate() {
		let wallet1 = LedgerWallet(address: MockConstants.hdWallet.address, publicKey: "03" + MockConstants.hdWallet.publicKey, derivationPath: HD.defaultDerivationPath, curve: .ed25519, ledgerUUID: "blah")
		let wallet2 = LedgerWallet(address: MockConstants.hdWallet.address, publicKey: "03" + MockConstants.hdWallet.publicKey, derivationPath: "44'/1729'/0'/1'", curve: .secp256k1, ledgerUUID: "blah2")
		let wallet3 = LedgerWallet(address: MockConstants.hdWallet.address, publicKey: "03", derivationPath: "44'/1729'/0'/1'", curve: .secp256k1, ledgerUUID: "blah")
		
		XCTAssert(wallet1?.address == MockConstants.hdWallet.address, wallet1?.address ?? "")
		XCTAssert(wallet2?.address == MockConstants.hdWallet.address, wallet2?.address ?? "")
		XCTAssert(wallet3 == nil)
		
		XCTAssert(wallet1?.publicKey == MockConstants.hdWallet.publicKey, wallet1?.publicKey ?? "")
		XCTAssert(wallet2?.publicKey == MockConstants.hdWallet.publicKey, wallet2?.publicKey ?? "")
		
		XCTAssert(wallet1?.derivationPath == HD.defaultDerivationPath, wallet1?.derivationPath ?? "")
		XCTAssert(wallet2?.derivationPath == "44'/1729'/0'/1'", wallet2?.derivationPath ?? "")
		
		XCTAssert(wallet1?.curve == .ed25519, wallet1?.curve.rawValue ?? "")
		XCTAssert(wallet2?.curve == .secp256k1, wallet2?.curve.rawValue ?? "")
		
		XCTAssert(wallet1?.ledgerUUID == "blah", wallet1?.ledgerUUID ?? "")
		XCTAssert(wallet2?.ledgerUUID == "blah2", wallet2?.ledgerUUID ?? "")
	}
	
	func testSigning() {
		let wallet1 = LedgerWallet(address: MockConstants.hdWallet.address, publicKey: "03" + MockConstants.hdWallet.publicKey, derivationPath: HD.defaultDerivationPath, curve: .ed25519, ledgerUUID: "blah")
		
		let messageHex = MockConstants.messageToSign.data(using: .utf8)?.toHexString() ?? "-"
		let signedData = wallet1?.sign(messageHex)
		XCTAssert(signedData == nil, signedData?.toHexString() ?? "")
	}
	
	func testBase58Encoding() {
		let wallet1 = LedgerWallet(address: MockConstants.hdWallet.address, publicKey: "03" + MockConstants.hdWallet.publicKey, derivationPath: HD.defaultDerivationPath, curve: .ed25519, ledgerUUID: "blah")
		let encoded = wallet1?.publicKeyBase58encoded()
		
		XCTAssert(encoded == MockConstants.hdWallet.base58Encoded, encoded ?? "")
	}
}
