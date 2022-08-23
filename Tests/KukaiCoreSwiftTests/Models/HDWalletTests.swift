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
		let wallet = HDWallet(withMnemonic: MockConstants.mnemonic, passphrase: "")
		XCTAssert(wallet?.address == MockConstants.hdWallet.address, wallet?.address ?? "-")
		XCTAssert(wallet?.privateKey.bytes.hexString == MockConstants.hdWallet.privateKey, wallet?.privateKey.bytes.hexString ?? "-")
		XCTAssert(wallet?.publicKey.bytes.hexString == MockConstants.hdWallet.publicKey, wallet?.publicKey.bytes.hexString ?? "-")
	}
	
	func testCreateWithMnemonicLength() {
		let wallet1 = HDWallet(withMnemonicLength: .twelve, passphrase: "")
		XCTAssert(wallet1?.mnemonic.words.count == 12, "\(wallet1?.mnemonic.words.count ?? -1)")
		
		let wallet2 = HDWallet(withMnemonicLength: .fifteen, passphrase: "")
		XCTAssert(wallet2?.mnemonic.words.count == 15, "\(wallet2?.mnemonic.words.count ?? -1)")
		
		let wallet3 = HDWallet(withMnemonicLength: .twentyFour, passphrase: "")
		XCTAssert(wallet3?.mnemonic.words.count == 24, "\(wallet3?.mnemonic.words.count ?? -1)")
	}
	
	func testPassphrases() {
		let wallet = HDWallet(withMnemonic: MockConstants.mnemonic, passphrase: MockConstants.passphrase)
		XCTAssert(wallet?.address == MockConstants.hdWallet_withPassphrase.address, wallet?.address ?? "-")
		XCTAssert(wallet?.privateKey.bytes.hexString == MockConstants.hdWallet_withPassphrase.privateKey, wallet?.privateKey.bytes.hexString ?? "-")
		XCTAssert(wallet?.publicKey.bytes.hexString == MockConstants.hdWallet_withPassphrase.publicKey, wallet?.publicKey.bytes.hexString ?? "-")
	}
	
	func testDerivationPaths() {
		let wallet1 = HDWallet(withMnemonic: MockConstants.mnemonic, passphrase: MockConstants.passphrase, derivationPath: MockConstants.hdWallet_hardened_change.derivationPath)
		XCTAssert(wallet1?.address == MockConstants.hdWallet_hardened_change.address, wallet1?.address ?? "-")
		XCTAssert(wallet1?.privateKey.bytes.hexString == MockConstants.hdWallet_hardened_change.privateKey, wallet1?.privateKey.bytes.hexString ?? "-")
		XCTAssert(wallet1?.publicKey.bytes.hexString == MockConstants.hdWallet_hardened_change.publicKey, wallet1?.publicKey.bytes.hexString ?? "-")
	}
	
	func testSigning() {
		let messageHex = MockConstants.messageToSign.data(using: .utf8)?.toHexString() ?? "-"
		MockConstants.defaultHdWallet.sign(messageHex) { result in
			guard let signedData = try? result.get() else {
				XCTFail("No signature: \(result.getFailure())")
				return
			}
			
			XCTAssert(signedData.toHexString() == MockConstants.hdWallet.signedData, signedData.toHexString())
		}
	}
	
	func testBase58Encoding() {
		let encoded = MockConstants.defaultHdWallet.publicKeyBase58encoded()
		XCTAssert(encoded == MockConstants.hdWallet.base58Encoded, encoded)
	}
	
	func testChildWallets() {
		let wallet = HDWallet(withMnemonic: MockConstants.mnemonic, passphrase: "")
		XCTAssert(wallet?.address == MockConstants.hdWallet.address, wallet?.address ?? "-")
		
		XCTAssert(wallet?.addNextChildWallet() ?? false)
		XCTAssert(wallet?.childWallets[0].address == MockConstants.hdWallet.childWalletAddresses[0], wallet?.childWallets[0].address ?? "-")
		
		XCTAssert(wallet?.addNextChildWallet() ?? false)
		XCTAssert(wallet?.childWallets[1].address == MockConstants.hdWallet.childWalletAddresses[1], wallet?.childWallets[1].address ?? "-")
		
		XCTAssert(wallet?.addNextChildWallet() ?? false)
		XCTAssert(wallet?.childWallets[2].address == MockConstants.hdWallet.childWalletAddresses[2], wallet?.childWallets[2].address ?? "-")
	}
}
