//
//  OperationModelTests.swift
//  
//
//  Created by Simon Mcloughlin on 25/06/2021.
//

import XCTest
@testable import KukaiCoreSwift

class OperationModelTests: XCTestCase {

	override func setUpWithError() throws {
		
	}

	override func tearDownWithError() throws {
		
	}
	
	func testActivateAccount() {
		let op = OperationActivateAccount(wallet: MockConstants.defaultHdWallet, andSecret: "supersecret")
		let op2 = OperationActivateAccount(wallet: MockConstants.defaultHdWallet, andSecret: "supersecret2")
		
		XCTAssert(op.publicKey == MockConstants.defaultHdWallet.address, op.publicKey)
		XCTAssert(op.secret == "supersecret", op.secret)
		XCTAssert(op.operationKind == .activate_account)
		XCTAssertFalse(op.isEqual(op2))
		
		let writeResult = DiskService.write(encodable: op, toFileName: "OperationActivateAccount.txt")
		XCTAssert(writeResult)
		
		let readResult = DiskService.read(type: OperationActivateAccount.self, fromFileName: "OperationActivateAccount.txt")
		XCTAssertNotNil(readResult)
		XCTAssert(readResult?.isEqual(op) ?? false)
		
		let _ = DiskService.delete(fileName: "OperationActivateAccount.txt")
	}
	
	func testDelegation() {
		let op = OperationDelegation(source: MockConstants.defaultHdWallet.address, delegate: MockConstants.defaultLinearWallet.address)
		let op2 = OperationDelegation(source: MockConstants.defaultLinearWallet.address, delegate: MockConstants.defaultHdWallet.address)
		
		XCTAssert(op.source == MockConstants.defaultHdWallet.address)
		XCTAssert(op.delegate == MockConstants.defaultLinearWallet.address)
		XCTAssert(op.operationKind == .delegation)
		XCTAssertFalse(op.isEqual(op2))
		
		let writeResult = DiskService.write(encodable: op, toFileName: "OperationDelegation.txt")
		XCTAssert(writeResult)
		
		let readResult = DiskService.read(type: OperationDelegation.self, fromFileName: "OperationDelegation.txt")
		XCTAssertNotNil(readResult)
		XCTAssert(readResult?.isEqual(op) ?? false)
		
		let _ = DiskService.delete(fileName: "OperationDelegation.txt")
	}
	
	func testReveal() {
		let op = OperationReveal(wallet: MockConstants.defaultHdWallet)
		let op2 = OperationReveal(wallet: MockConstants.defaultLinearWallet)
		
		XCTAssert(op.publicKey == MockConstants.defaultHdWallet.publicKeyBase58encoded())
		XCTAssert(op.operationKind == .reveal)
		XCTAssertFalse(op.isEqual(op2))
		
		let writeResult = DiskService.write(encodable: op, toFileName: "OperationReveal.txt")
		XCTAssert(writeResult)
		
		let readResult = DiskService.read(type: OperationReveal.self, fromFileName: "OperationReveal.txt")
		XCTAssertNotNil(readResult)
		XCTAssert(readResult?.isEqual(op) ?? false)
		
		let _ = DiskService.delete(fileName: "OperationReveal.txt")
	}
	
	func testSmartContractInvocation() {
		let entrypoint = OperationTransaction.StandardEntrypoint.transfer.rawValue
		
		let tokenAmountMichelson = MichelsonFactory.createInt(TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 0))
		let destinationMicheslon = MichelsonFactory.createString(MockConstants.defaultLinearWallet.address)
		let innerPair = MichelsonPair(args: [destinationMicheslon, tokenAmountMichelson])
		let sourceMichelson = MichelsonFactory.createString(MockConstants.defaultHdWallet.address)
		let michelson = MichelsonPair(args: [sourceMichelson, innerPair])
		
		let op = OperationTransaction(amount: TokenAmount.zero(), source: MockConstants.defaultHdWallet.address, destination: MockConstants.token3Decimals.tokenContractAddress ?? "", entrypoint: entrypoint, value: michelson)
		let op2 = OperationTransaction(amount: TokenAmount.zero(), source: MockConstants.defaultLinearWallet.address, destination: MockConstants.token10Decimals.tokenContractAddress ?? "", entrypoint: entrypoint, value: michelson)
		
		XCTAssert(op.amount == "0", op.amount)
		XCTAssert(op.destination == MockConstants.token3Decimals.tokenContractAddress, op.destination)
		XCTAssert(op.operationKind == .transaction)
		XCTAssertFalse(op.isEqual(op2))
		
		let writeResult = DiskService.write(encodable: op, toFileName: "OperationSmartContractInvocation.txt")
		XCTAssert(writeResult)
		
		let readResult = DiskService.read(type: OperationTransaction.self, fromFileName: "OperationSmartContractInvocation.txt")
		XCTAssertNotNil(readResult)
		XCTAssert(readResult?.isEqual(op) ?? false)
		
		let _ = DiskService.delete(fileName: "OperationSmartContractInvocation.txt")
	}
	
	func testTransaction() {
		let op = OperationTransaction(amount: XTZAmount(fromNormalisedAmount: 1), source: MockConstants.defaultHdWallet.address, destination: MockConstants.defaultLinearWallet.address)
		let op2 = OperationTransaction(amount: XTZAmount(fromNormalisedAmount: 1), source: MockConstants.defaultLinearWallet.address, destination: MockConstants.defaultHdWallet.address)
		
		XCTAssert(op.amount == "1000000", op.amount)
		XCTAssert(op.source == MockConstants.defaultHdWallet.address, op.source ?? "-")
		XCTAssert(op.destination == MockConstants.defaultLinearWallet.address, op.destination)
		XCTAssert(op.operationKind == .transaction)
		XCTAssertFalse(op.isEqual(op2))
		
		let writeResult = DiskService.write(encodable: op, toFileName: "OperationTransaction.txt")
		XCTAssert(writeResult)
		
		let readResult = DiskService.read(type: OperationTransaction.self, fromFileName: "OperationTransaction.txt")
		XCTAssertNotNil(readResult)
		XCTAssert(readResult?.isEqual(op) ?? false)
		
		let _ = DiskService.delete(fileName: "OperationTransaction.txt")
	}
	
	func testOrigination() {
		let op = OperationOrigination(source: MockConstants.defaultHdWallet.address, balance: XTZAmount(fromNormalisedAmount: 1), code: "contract-code", storage: "contract-initial-storage")
		let op2 =  OperationOrigination(source: MockConstants.defaultLinearWallet.address, balance: XTZAmount(fromNormalisedAmount: 2), code: "contract-code2", storage: "contract-initial-storage2")
		
		XCTAssert(op.source == MockConstants.defaultHdWallet.address)
		XCTAssert(op.script == ["code": "contract-code", "storage": "contract-initial-storage"], "\(op.script)")
		XCTAssert(op.operationKind == .origination)
		XCTAssertFalse(op.isEqual(op2))
		
		let writeResult = DiskService.write(encodable: op, toFileName: "OperationOrigination.txt")
		XCTAssert(writeResult)
		
		let readResult = DiskService.read(type: OperationOrigination.self, fromFileName: "OperationOrigination.txt")
		XCTAssertNotNil(readResult)
		XCTAssert(readResult?.isEqual(op) ?? false)
		
		let _ = DiskService.delete(fileName: "OperationOrigination.txt")
	}
	
	func testFees() {
		let fees = OperationFees(transactionFee: XTZAmount(fromNormalisedAmount: 1), networkFees: [[.allocationFee: XTZAmount(fromNormalisedAmount: 2)]], gasLimit: 15000, storageLimit: 3000)
		let fees2 = OperationFees(transactionFee: XTZAmount(fromNormalisedAmount: 2), networkFees: [[.allocationFee: XTZAmount(fromNormalisedAmount: 1)]], gasLimit: 13000, storageLimit: 4000)
		
		XCTAssertFalse(fees == fees2)
		XCTAssert(fees.allFees() == XTZAmount(fromNormalisedAmount: 3), fees.allFees().normalisedRepresentation)
		XCTAssert(fees.allNetworkFees() == XTZAmount(fromNormalisedAmount: 2), fees.allNetworkFees().normalisedRepresentation)
		
		let defaultFees1 = OperationFees.defaultFees(operationKind: .transaction).allFees()
		XCTAssert(defaultFees1 == XTZAmount(fromNormalisedAmount: 0.00141), defaultFees1.normalisedRepresentation)
		
		let defaultFees2 = OperationFees.defaultFees(operationKind: .reveal).allFees()
		XCTAssert(defaultFees2 == XTZAmount(fromNormalisedAmount: 0.001268), defaultFees2.normalisedRepresentation)
		
		let defaultFees3 = OperationFees.defaultFees(operationKind: .origination).allFees()
		XCTAssert(defaultFees3 == XTZAmount(fromNormalisedAmount: 0.001477), defaultFees3.normalisedRepresentation)
		
		let defaultFees4 = OperationFees.defaultFees(operationKind: .delegation).allFees()
		XCTAssert(defaultFees4 == XTZAmount(fromNormalisedAmount: 0.001257), defaultFees4.normalisedRepresentation)
		
		let defaultFees5 = OperationFees.defaultFees(operationKind: .activate_account).allFees()
		XCTAssert(defaultFees5 == XTZAmount(fromNormalisedAmount: 0.001268), defaultFees5.normalisedRepresentation)
	}
}
