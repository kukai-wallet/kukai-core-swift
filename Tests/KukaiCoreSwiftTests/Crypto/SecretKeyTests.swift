//
//  SecretKeyTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class SecretKeyTests: XCTestCase {
	
	let seedString = "5cb169574329d2d4d0b1d284aff23aa29b2a6b1ab44427af797d72d84ea75332"
	
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }
	
	func testSecretKey() {
		let secretKey = SecretKey(seedString: seedString)
		XCTAssert(secretKey?.base58CheckRepresentation == "edskRp98rYdEqobQb9QrLGD4ghBF1FkpptJG2W8wVGnRXJ3LNpRu3Nh2yJ3YZMdkj1Lsn8RqiANUGi835nmgQHH7Vgzh7CUCXi", secretKey?.base58CheckRepresentation ?? "-")
		
		let secretKey2 = SecretKey(seedString: seedString, signingCurve: .secp256k1)
		XCTAssert(secretKey2?.base58CheckRepresentation == "spsk28PQ9xce2NjknDEoTeTvcXbzFCNg7z4wfDhGAjkUpkMATc25Xb", secretKey2?.base58CheckRepresentation ?? "-")
		
		
		let publicKey = PublicKey(secretKey: secretKey!)
		XCTAssert(publicKey?.base58CheckRepresentation == "edpkv5UUf5a8UKUvnTUMgX8nsrt7frRBPqYTsznWzU4hFJAJsUH7Y5", publicKey?.base58CheckRepresentation ?? "-")
		XCTAssert(publicKey?.publicKeyHash == "tz1eybfuuE8Uco6VEgDUzdRnsSKcbdKMwfdu", publicKey?.publicKeyHash ?? "-")
		
		let publicKey2 = PublicKey(secretKey: secretKey2!)
		XCTAssert(publicKey2?.publicKeyHash == "tz29nzoG5nkTe3rJzEQx5EoDT5LgKVhxLQXj", publicKey2?.publicKeyHash ?? "-")
		
		
		
		let hexToSign = "123456"
		let signature1 = secretKey?.sign(hex: hexToSign) ?? []
		let signature2 = secretKey2?.sign(hex: hexToSign) ?? []
		
		XCTAssert(publicKey?.verify(signature: signature1, hex: hexToSign) ?? false)
		XCTAssert(publicKey2?.verify(signature: signature2, hex: hexToSign) ?? false)
		
		XCTAssertFalse(publicKey?.verify(signature: signature1, hex: "654321") ?? false)
		XCTAssertFalse(publicKey2?.verify(signature: signature2, hex: "654321") ?? false)
	}
}
