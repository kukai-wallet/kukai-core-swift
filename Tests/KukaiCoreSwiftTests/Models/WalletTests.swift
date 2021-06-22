//
//  WalletTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class WalletTests: XCTestCase {

    override func setUpWithError() throws {
		
    }

    override func tearDownWithError() throws {
		
    }
	
	func testMnemonicValidation() {
		let mnemonic1 = "remember smile trip tumble era cube worry fuel bracket eight kitten inform"
		let mnemonic2 = "remember smile trip tumble era cube worry fuel bracket eight kitten blah57"
		let mnemonic3 = "asd"
		let mnemonic4 = ""
		let mnemonic5 = "-1"
		let mnemonic6 = "remember, smile, trip, tumble, era, cube, worry, fuel, bracket, eight, kitten, inform"
		let mnemonic7 = "1. remember 2. smile 3. trip 4. tumble 5. era 6. cube 7. worry 8. fuel 9. bracket 10. eight 11. kitten 12. inform"
		
		XCTAssert(WalletUtils.isMnemonicValid(mnemonic: mnemonic1) == true)
		XCTAssert(WalletUtils.isMnemonicValid(mnemonic: mnemonic2) == false)
		XCTAssert(WalletUtils.isMnemonicValid(mnemonic: mnemonic3) == false)
		XCTAssert(WalletUtils.isMnemonicValid(mnemonic: mnemonic4) == false)
		XCTAssert(WalletUtils.isMnemonicValid(mnemonic: mnemonic5) == false)
		XCTAssert(WalletUtils.isMnemonicValid(mnemonic: mnemonic6) == false)
		XCTAssert(WalletUtils.isMnemonicValid(mnemonic: mnemonic7) == false)
	}
}
