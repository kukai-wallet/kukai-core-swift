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
		let params: [String: Any] = [
			"entrypoint": OperationTransaction.StandardEntrypoint.transfer.rawValue,
			"value": ["prim":"Pair","args":[["string":MockConstants.defaultHdWallet.address] as [String : Any], ["prim":"Pair","args":[["string":MockConstants.defaultLinearWallet.address], ["int":"1"]]]]] as [String : Any]
		]
		
		let op = OperationTransaction(amount: TokenAmount.zero(), source: MockConstants.defaultHdWallet.address, destination: MockConstants.token3Decimals.tokenContractAddress ?? "", parameters: params)
		let op2 = OperationTransaction(amount: TokenAmount.zero(), source: MockConstants.defaultLinearWallet.address, destination: MockConstants.token10Decimals.tokenContractAddress ?? "", parameters: params)
		
		XCTAssert(op.amount == "0", op.amount)
		XCTAssert(op.destination == MockConstants.token3Decimals.tokenContractAddress, op.destination)
		XCTAssert(op.operationKind == .transaction)
		XCTAssertFalse(op.isEqual(op2))
		
		let writeResult = DiskService.write(encodable: op, toFileName: "OperationSmartContractInvocation.txt")
		XCTAssert(writeResult)
		
		let readResult = DiskService.read(type: OperationTransaction.self, fromFileName: "OperationSmartContractInvocation.txt")
		XCTAssertNotNil(readResult)
		
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
		
		let rawReadResult = DiskService.readData(fromFileName: "OperationTransaction.txt")
		let rawReadResultString = String(data: rawReadResult ?? Data(), encoding: .utf8)
		let containsNullParameter = rawReadResultString?.contains("\"parameters\":null")
		XCTAssert(containsNullParameter != true)
		
		let _ = DiskService.delete(fileName: "OperationTransaction.txt")
	}
	
	func testTransactionNFT() {
		guard let op = OperationFactory.sendOperation(1, ofNft: (MockConstants.tokenWithNFTs.nfts ?? [])[0], from: MockConstants.defaultHdWallet.address, to: MockConstants.defaultLinearWallet.address).first as? OperationTransaction else {
				  XCTFail("Couldn't create ops")
				  return
			  }
		
		XCTAssert(op.amount == "0", op.amount)
		XCTAssert(op.source == MockConstants.defaultHdWallet.address, op.source ?? "-")
		XCTAssert(op.destination == "KT1G1cCRNBgQ48mVDjopHjEmTN5Sbtabc123", op.destination)
		XCTAssert(op.operationKind == .transaction)
		
		let writeResult = DiskService.write(encodable: op, toFileName: "OperationTransactionNFT.txt")
		XCTAssert(writeResult)
		
		let readResult = DiskService.read(type: OperationTransaction.self, fromFileName: "OperationTransactionNFT.txt")
		XCTAssertNotNil(readResult)
		XCTAssert(readResult?.isEqual(op) ?? false)
		
		if let parameters = readResult?.parameters?.michelsonValueArray()?[0] {
			let address = parameters.michelsonArgsUnknownArray()?.michelsonString(atIndex: 0)
			let destination = parameters.michelsonArgsUnknownArray()?.michelsonArray(atIndex: 1)?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonString(atIndex: 0)
			let tokenId = parameters.michelsonArgsUnknownArray()?.michelsonArray(atIndex: 1)?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 0)
			let amount = parameters.michelsonArgsUnknownArray()?.michelsonArray(atIndex: 1)?.michelsonPair(atIndex: 0)?.michelsonArgsArray()?.michelsonPair(atIndex: 1)?.michelsonArgsArray()?.michelsonInt(atIndex: 1)
			
			XCTAssert(address == "tz1Ue76bLW7boAcJEZf2kSGcamdBKVi4Kpss", address ?? "-")
			XCTAssert(destination == "tz1iQpiBTKtzfbVgogjyhPiGrrV5zAKUKNvy", destination ?? "-")
			XCTAssert(tokenId == "4", tokenId ?? "-")
			XCTAssert(amount == "1", amount ?? "-")
			
		} else {
			XCTFail("No parameters found")
		}
		
		let _ = DiskService.delete(fileName: "OperationTransactionNFT.txt")
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
	
	func testEndorsement() {
		let op = OperationEndorsement(wallet: MockConstants.defaultHdWallet, level: 4)
		let op2 = OperationEndorsement(wallet: MockConstants.defaultHdWallet, level: 5)
		
		XCTAssert(op.level == 4, "\(op.level)")
		XCTAssertFalse(op.isEqual(op2))
		
		let writeResult = DiskService.write(encodable: op, toFileName: "OperationEndorsement.txt")
		XCTAssert(writeResult)
		
		let readResult = DiskService.read(type: OperationEndorsement.self, fromFileName: "OperationEndorsement.txt")
		XCTAssertNotNil(readResult)
		XCTAssert(readResult?.isEqual(op) ?? false)
		
		let _ = DiskService.delete(fileName: "OperationEndorsement.txt")
	}
	
	func testSeedNonceReveal() {
		let op = OperationSeedNonceRevelation(wallet: MockConstants.defaultHdWallet, level: 2, nonce: "abc123")
		let op2 = OperationSeedNonceRevelation(wallet: MockConstants.defaultHdWallet, level: 3, nonce: "abc1234")
		
		XCTAssert(op.level == 2, "\(op.level)")
		XCTAssert(op.nonce == "abc123", op.nonce)
		XCTAssertFalse(op.isEqual(op2))
		
		let writeResult = DiskService.write(encodable: op, toFileName: "OperationSeedNonceRevelation.txt")
		XCTAssert(writeResult)
		
		let readResult = DiskService.read(type: OperationSeedNonceRevelation.self, fromFileName: "OperationSeedNonceRevelation.txt")
		XCTAssertNotNil(readResult)
		XCTAssert(readResult?.isEqual(op) ?? false)
		
		let _ = DiskService.delete(fileName: "OperationSeedNonceRevelation.txt")
	}
	
	func testDoubleEndorsementEvidence() {
		let opInlined = OperationDoubleEndorsementEvidence.InlinedEndorsement(branch: "abc123", operations: OperationDoubleEndorsementEvidence.InlinedEndorsement.Content(kind: .transaction, level: 3), signature: "abc123")
		let opInlined2 = OperationDoubleEndorsementEvidence.InlinedEndorsement(branch: "abc1243", operations: OperationDoubleEndorsementEvidence.InlinedEndorsement.Content(kind: .transaction, level: 3), signature: "abc123")
		
		let op = OperationDoubleEndorsementEvidence(wallet: MockConstants.defaultHdWallet, op1: opInlined, op2: opInlined)
		let op2 = OperationDoubleEndorsementEvidence(wallet: MockConstants.defaultHdWallet, op1: opInlined2, op2: opInlined2)
		
		XCTAssert(op.op1.branch == "abc123", op.op1.branch)
		XCTAssertFalse(op.isEqual(op2))
		
		let writeResult = DiskService.write(encodable: op, toFileName: "OperationDoubleEndorsementEvidence.txt")
		XCTAssert(writeResult)
		
		let readResult = DiskService.read(type: OperationDoubleEndorsementEvidence.self, fromFileName: "OperationDoubleEndorsementEvidence.txt")
		XCTAssertNotNil(readResult)
		XCTAssert(readResult?.isEqual(op) ?? false)
		
		let _ = DiskService.delete(fileName: "OperationDoubleEndorsementEvidence.txt")
	}
	
	func testDoubleBakingEvidence() {
		let bh1 = OperationBlockHeader(level: 1, proto: 2, predecessor: "a", timestamp: Date(), validationPass: 4, operationsHash: "b", fitness: ["14"], context: "c", priority: 5, proofOfWorkNonce: "d", seedNonceHash: "e", signature: "f")
		let bh2 = OperationBlockHeader(level: 3, proto: 4, predecessor: "a", timestamp: Date(), validationPass: 4, operationsHash: "b", fitness: ["14"], context: "c", priority: 5, proofOfWorkNonce: "d", seedNonceHash: "e", signature: "f")
		
		let op = OperationDoubleBakingEvidence(wallet: MockConstants.defaultHdWallet, bh1: bh1, bh2: bh1)
		let op2 = OperationDoubleBakingEvidence(wallet: MockConstants.defaultHdWallet, bh1: bh2, bh2: bh2)
		
		XCTAssert(op.bh1.level == 1, "\(op.bh1.level)")
		XCTAssertFalse(op.isEqual(op2))
		
		let writeResult = DiskService.write(encodable: op, toFileName: "OperationDoubleBakingEvidence.txt")
		XCTAssert(writeResult)
		
		let readResult = DiskService.read(type: OperationDoubleBakingEvidence.self, fromFileName: "OperationDoubleBakingEvidence.txt")
		XCTAssertNotNil(readResult)
		XCTAssert(readResult?.isEqual(op) ?? false)
		
		let _ = DiskService.delete(fileName: "OperationDoubleBakingEvidence.txt")
	}
	
	func testProposals() {
		let op = OperationProposals(wallet: MockConstants.defaultHdWallet, period: 3, proposals: ["sapling1234"])
		let op2 = OperationProposals(wallet: MockConstants.defaultHdWallet, period: 7, proposals: ["gas-cost-783"])
		
		XCTAssert(op.period == 3, "\(op.period)")
		XCTAssert(op.proposals.first == "sapling1234", op.proposals.first ?? "")
		XCTAssertFalse(op.isEqual(op2))
		
		let writeResult = DiskService.write(encodable: op, toFileName: "OperationProposals.txt")
		XCTAssert(writeResult)
		
		let readResult = DiskService.read(type: OperationProposals.self, fromFileName: "OperationProposals.txt")
		XCTAssertNotNil(readResult)
		XCTAssert(readResult?.isEqual(op) ?? false)
		
		let _ = DiskService.delete(fileName: "OperationProposals.txt")
	}
	
	func testBallot() {
		let op = OperationBallot(wallet: MockConstants.defaultHdWallet, period: 2, proposal: "sapling1234", ballot: .yay)
		let op2 = OperationBallot(wallet: MockConstants.defaultHdWallet, period: 2, proposal: "sapling1234", ballot: .nay)
		
		XCTAssert(op.period == 2, "\(op.period)")
		XCTAssert(op.proposal == "sapling1234", op.proposal)
		XCTAssert(op.ballot == .yay, op.ballot.rawValue)
		XCTAssertFalse(op.isEqual(op2))
		
		let writeResult = DiskService.write(encodable: op, toFileName: "OperationBallot.txt")
		XCTAssert(writeResult)
		
		let readResult = DiskService.read(type: OperationBallot.self, fromFileName: "OperationBallot.txt")
		XCTAssertNotNil(readResult)
		XCTAssert(readResult?.isEqual(op) ?? false)
		
		let _ = DiskService.delete(fileName: "OperationBallot.txt")
	}
	
	func testFees() {
		let fees = OperationFees(transactionFee: XTZAmount(fromNormalisedAmount: 1), networkFees: [.allocationFee: XTZAmount(fromNormalisedAmount: 2)], gasLimit: 15000, storageLimit: 3000)
		let fees2 = OperationFees(transactionFee: XTZAmount(fromNormalisedAmount: 2), networkFees: [.allocationFee: XTZAmount(fromNormalisedAmount: 1)], gasLimit: 13000, storageLimit: 4000)
		
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
	
	func testUnknownOperationFallback() {
		let jsonString = """
		  {
				"kind": "somethingWeird",
				"amount": "1000000",
				"somethingVeryNew": "bingo",
				"destination": "KT1CYkiSJtKgFNy6whArwpn3TsYe7iX9SwFu",
				"parameters": {
					"entrypoint": "wrap",
					"value": {
						"string": "tz1bJyyFMMWhwkdKSi7Ud8fimu72yfjNC44j"
					}
				}
			}
		"""
		
		let unknown = try? JSONDecoder().decode(OperationUnknown.self, from: (jsonString.data(using: .utf8) ?? Data()))
		unknown?.source = "TZ1abcdef"
		unknown?.counter = "14"
		unknown?.operationFees = OperationFees(transactionFee: XTZAmount(fromNormalisedAmount: 0.14), gasLimit: 1400, storageLimit: 1452)
		
		
		XCTAssert(unknown?.operationKind == .unknown, unknown?.operationKind.rawValue ?? "-")
		XCTAssert(unknown?.unknownKind == "somethingWeird", unknown?.unknownKind ?? "-")
		XCTAssert(unknown?.source == "TZ1abcdef", unknown?.source ?? "-")
		
		let propTest1 = unknown?.allOtherProperties["somethingVeryNew"] as? String
		XCTAssert(propTest1 == "bingo", propTest1 ?? "-")
		
		let propTest2 = unknown?.allOtherProperties["destination"] as? String
		XCTAssert(propTest2 == "KT1CYkiSJtKgFNy6whArwpn3TsYe7iX9SwFu", propTest2 ?? "-")
		
		
		let encoder = JSONEncoder()
		encoder.outputFormatting = .sortedKeys
		
		let data = try? encoder.encode(unknown)
		let string = String(data: data ?? Data(), encoding: .utf8)
		
		let jsonOuput = """
		{"amount":"1000000","counter":"14","destination":"KT1CYkiSJtKgFNy6whArwpn3TsYe7iX9SwFu","fee":"140000","gasLimit":"1400","kind":"somethingWeird","parameters":{"entrypoint":"wrap","value":{"string":"tz1bJyyFMMWhwkdKSi7Ud8fimu72yfjNC44j"}},"somethingVeryNew":"bingo","source":"TZ1abcdef","storageLimit":"1452"}
		"""
		XCTAssert(string == jsonOuput, string ?? "-")
	}
}
