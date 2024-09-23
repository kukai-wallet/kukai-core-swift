//
//  TzKTTransactionTests.swift
//  
//
//  Created by Simon Mcloughlin on 18/09/2023.
//

import XCTest
@testable import KukaiCoreSwift

final class TzKTTransactionTests: XCTestCase {

	override func setUpWithError() throws {
		
	}
	
	override func tearDownWithError() throws {
		
	}
	
	
	
	func testParameters() {
		let transferTokenParameters = [
			"entrypoint": "transfer",
			"value": "{\"to\": \"tz1eDdsp1d27kortm5LuoRqD6aKrdxmTiTSQ\", \"from\": \"tz1Z8E2gMHLXFcGGzW68B5e1Vk49FpHQd7xc\", \"value\": \"500000000000000000\"}"
		]
		
		var transaction = TzKTTransaction(type: .transaction, id: 123, level: 123, timestamp: "", hash: "", counter: 123, initiater: TzKTAddress(alias: nil, address: "tz1abc"), sender: TzKTAddress(alias: nil, address: "tz1abc"), bakerFee: .zero(), storageFee: .zero(), allocationFee: .zero(), target: TzKTAddress(alias: nil, address: "KT1GG8Zd5rUp1XV8nMPRBY2tSyVn6NR5F4Q1"), prevDelegate: nil, newDelegate: nil, baker: nil, amount: .zero(), parameter: transferTokenParameters, status: .applied, hasInternals: false, tokenTransfersCount: 0, errors: nil, kind: nil)
		transaction.processAdditionalData(withCurrentWalletAddress: "tz1abc")
		
		let token = transaction.getFaTokenTransferData()
		XCTAssert(token?.tokenContractAddress == "KT1GG8Zd5rUp1XV8nMPRBY2tSyVn6NR5F4Q1", token?.tokenContractAddress ?? "-")
		
		let destination = transaction.getTokenTransferDestination()
		XCTAssert(destination == "tz1eDdsp1d27kortm5LuoRqD6aKrdxmTiTSQ", destination ?? "-")
		
		
		
		
		let dictParams = [
			"entrypoint": "transfer",
			"value": "{\"to\": \"tz1eDdsp1d27kortm5LuoRqD6aKrdxmTiTSQ\", \"from\": \"tz1Z8E2gMHLXFcGGzW68B5e1Vk49FpHQd7xc\", \"value\": \"500000000000000000\"}"
		]
		let transaction1 = TzKTTransaction(type: .transaction, id: 1, level: 1, timestamp: "", hash: "", counter: 1, initiater: nil, sender: TzKTAddress(alias: nil, address: "tz1abc"), bakerFee: .zero(), storageFee: .zero(), allocationFee: .zero(), target: TzKTAddress(alias: nil, address: "tz1abc"), prevDelegate: nil, newDelegate: nil, baker: nil, amount: .zero(), parameter: dictParams, status: .confirmed, hasInternals: false, tokenTransfersCount: nil, errors: nil, kind: nil)
		let dict = transaction1.parameterValueAsDict()
		let dictValue1 = dict?["to"] as? String
		XCTAssert(dictValue1 == "tz1eDdsp1d27kortm5LuoRqD6aKrdxmTiTSQ", dictValue1 ?? "-")
		
		
		
		let arrayParams = [
			"entrypoint": "transfer",
			"value": "[\"test\", 123, 14.7]"
		]
		let transaction2 = TzKTTransaction(type: .transaction, id: 1, level: 1, timestamp: "", hash: "", counter: 1, initiater: nil, sender: TzKTAddress(alias: nil, address: "tz1abc"), bakerFee: .zero(), storageFee: .zero(), allocationFee: .zero(), target: TzKTAddress(alias: nil, address: "tz1abc"), prevDelegate: nil, newDelegate: nil, baker: nil, amount: .zero(), parameter: arrayParams, status: .confirmed, hasInternals: false, tokenTransfersCount: nil, errors: nil, kind: nil)
		let array = transaction2.parameterValueAsArray()
		let arrayValue1 = array?[0] as? String
		let arrayValue2 = array?[1] as? Int
		let arrayValue3 = array?[2] as? Double
		XCTAssert(arrayValue1 == "test", arrayValue1 ?? "-")
		XCTAssert(arrayValue2 == 123, arrayValue2?.description ?? "-")
		XCTAssert(arrayValue3 == 14.7, arrayValue3?.description ?? "-")
		
		
		let arrayOfDictParams = [
			"entrypoint": "transfer",
			"value": "[{\"key\": \"value\"}, {\"key\": 123}, {\"key\": 14.7}]"
		]
		let transaction3 = TzKTTransaction(type: .transaction, id: 1, level: 1, timestamp: "", hash: "", counter: 1, initiater: nil, sender: TzKTAddress(alias: nil, address: "tz1abc"), bakerFee: .zero(), storageFee: .zero(), allocationFee: .zero(), target: TzKTAddress(alias: nil, address: "tz1abc"), prevDelegate: nil, newDelegate: nil, baker: nil, amount: .zero(), parameter: arrayOfDictParams, status: .confirmed, hasInternals: false, tokenTransfersCount: nil, errors: nil, kind: nil)
		let arryOfDict = transaction3.parameterValueAsArrayOfDictionary()
		let arryOfDictValue1 = (arryOfDict?[0] as? [String: String])?["key"] as? String
		let arryOfDictValue2 = (arryOfDict?[1] as? [String: Int])?["key"] as? Int
		let arryOfDictValue3 = (arryOfDict?[2] as? [String: Double])?["key"] as? Double
		XCTAssert(arryOfDictValue1 == "value", arryOfDictValue1 ?? "-")
		XCTAssert(arryOfDictValue2 == 123, arryOfDictValue2?.description ?? "-")
		XCTAssert(arryOfDictValue3 == 14.7, arryOfDictValue3?.description ?? "-")
	}
	
	func testPlaceholders() {
		let source = WalletMetadata(address: "tz1abc", derivationPath: nil, hdWalletGroupName: nil, type: .hd, children: [], isChild: false, isWatchOnly: false, bas58EncodedPublicKey: "", backedUp: true)
		let placeholder1 = TzKTTransaction.placeholder(withStatus: .unconfirmed, id: 567, opHash: "abc123", type: .transaction, counter: 0, fromWallet: source, newDelegate: TzKTAddress(alias: "Baking Benjamins", address: "tz1YgDUQV2eXm8pUWNz3S5aWP86iFzNp4jnD"))
		
		let placeholder2 = TzKTTransaction.placeholder(withStatus: .unconfirmed, id: 456, opHash: "def456", type: .transaction, counter: 1, fromWallet: source, destination: TzKTAddress(alias: nil, address: "tz1def"), xtzAmount: .init(fromNormalisedAmount: 4.17, decimalPlaces: 6), parameters: nil, primaryToken: nil, baker: nil, kind: nil)
		
		XCTAssert(placeholder1.newDelegate?.address == "tz1YgDUQV2eXm8pUWNz3S5aWP86iFzNp4jnD", placeholder1.newDelegate?.address ?? "-")
		XCTAssert(placeholder2.amount.description == "4.17", placeholder2.amount.description)
	}
	
	func testEncoding() {
		let transferTokenParameters = [
			"entrypoint": "transfer",
			"value": "{\"to\": \"tz1eDdsp1d27kortm5LuoRqD6aKrdxmTiTSQ\", \"from\": \"tz1Z8E2gMHLXFcGGzW68B5e1Vk49FpHQd7xc\", \"value\": \"500000000000000000\"}"
		]
		
		var transaction = TzKTTransaction(type: .transaction, id: 123, level: 123, timestamp: "", hash: "", counter: 123, initiater: TzKTAddress(alias: nil, address: "tz1abc"), sender: TzKTAddress(alias: nil, address: "tz1abc"), bakerFee: .zero(), storageFee: .zero(), allocationFee: .zero(), target: TzKTAddress(alias: nil, address: "KT1GG8Zd5rUp1XV8nMPRBY2tSyVn6NR5F4Q1"), prevDelegate: nil, newDelegate: nil, baker: nil, amount: .zero(), parameter: transferTokenParameters, status: .applied, hasInternals: false, tokenTransfersCount: 0, errors: nil, kind: nil)
		transaction.processAdditionalData(withCurrentWalletAddress: "tz1abc")
		
		if let json = try? JSONEncoder().encode(transaction), let jsonString = String(data: json, encoding: .utf8) {
			XCTAssert(jsonString.count == 973, jsonString.count.description)
		} else {
			XCTFail()
		}
	}
}
