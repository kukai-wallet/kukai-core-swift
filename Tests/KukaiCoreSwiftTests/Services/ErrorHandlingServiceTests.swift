//
//  ErrorHandlingServiceTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 16/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class ErrorHandlingServiceTests: XCTestCase {
	
	func testStaticConstrutors() {
		let error1 = KukaiError.rpcError(rpcErrorString: "testing RPC string", andFailWith: nil)
		XCTAssert(error1.rpcErrorString == "testing RPC string", error1.rpcErrorString ?? "-")
		XCTAssert(error1.description == "Error - RPC: testing RPC string", error1.description)
		
		let error2 = KukaiError.rpcError(rpcErrorString: "testing RPC string", andFailWith: FailWith(string: nil, int: "1", args: nil))
		XCTAssert(error2.rpcErrorString == "testing RPC string", error2.rpcErrorString ?? "-")
		XCTAssert(error2.description == "Error - RPC: testing RPC string", error2.description)
		
		let error3 = KukaiError.unknown(withString: "test unknown string")
		XCTAssert(error3.rpcErrorString == "test unknown string", error3.rpcErrorString ?? "-")
		XCTAssert(error3.description == "Error - Unknown: test unknown string", error3.description)
		
		let error4 = KukaiError.internalApplicationError(error: URLError(URLError.unknown))
		XCTAssert(error4.rpcErrorString == nil, error4.rpcErrorString ?? "-")
		XCTAssert(error4.description == "Error - Internal Application: Error Domain=NSURLErrorDomain Code=-1 \"(null)\"", error4.description)
		
		let error5 = KukaiError.systemError(subType: URLError(URLError.unknown))
		XCTAssert(error5.rpcErrorString == nil, error5.rpcErrorString ?? "-")
		XCTAssert(error5.description == "Error - System: Error Domain=NSURLErrorDomain Code=-1 \"(null)\"", error5.description)
	}
	
	func testSystemParsers() {
		let requestURL = URL(string: "http://google.com")!
		
		let successURLResponse = HTTPURLResponse(url: URL(string: "http://google.com")!, statusCode: 400, httpVersion: nil, headerFields: nil)
		let sameplData = "The Internet connection appears to be offline.".data(using: .utf8) ?? Data()
		
		let error1 = ErrorHandlingService.searchForSystemError(data: sameplData, response: successURLResponse, networkError: URLError(URLError.notConnectedToInternet), requestURL: requestURL, requestData: nil)
		XCTAssert(error1?.errorType == .system)
		XCTAssert(error1?.description == "Error - System: Error Domain=NSURLErrorDomain Code=-1009 \"(null)\"", error1?.description ?? "-")
		XCTAssert(error1?.httpStatusCode == 400)
		
		let errorURLResponse = HTTPURLResponse(url: URL(string: "http://google.com")!, statusCode: 400, httpVersion: nil, headerFields: nil)
		let error2 = ErrorHandlingService.searchForSystemError(data: nil, response: errorURLResponse, networkError: URLError(URLError.notConnectedToInternet), requestURL: requestURL, requestData: nil)
		XCTAssert(error2?.httpStatusCode == 400)
		XCTAssert(error2?.subType is URLError)
		XCTAssert((error2?.subType as? URLError)?.code == URLError.notConnectedToInternet)
	}
	
	func testOperationResponseParserIDString() {
		let error = OperationResponseInternalResultError(kind: "", id: "proto.012-Psithaca.gas_exhausted.operation", contract: nil, expected: nil, found: nil, location: 41, with: FailWith(string: nil, int: nil, args: nil))
		let operationResponseResultWithError = OperationResponseResult(status: "", balanceUpdates: nil, consumedMilligas: "", storageSize: "", paidStorageSizeDiff: "", allocatedDestinationContract: nil, errors: [error])
		let operationResponseResultWithoutError = OperationResponseResult(status: "", balanceUpdates: nil, consumedMilligas: "", storageSize: "", paidStorageSizeDiff: "", allocatedDestinationContract: nil, errors: nil)
		
		let operationMetadataWithError = OperationResponseMetadata(balanceUpdates: nil, operationResult: operationResponseResultWithError, internalOperationResults: nil)
		let operationMetadataWithoutError = OperationResponseMetadata(balanceUpdates: nil, operationResult: operationResponseResultWithoutError, internalOperationResults: nil)
		
		let ops = [
			OperationResponse(contents: [
				OperationResponseContent(kind: "", source: nil, metadata: operationMetadataWithError),
				OperationResponseContent(kind: "", source: nil, metadata: operationMetadataWithoutError)
			])
		]
		
		let containsErrors1 = ErrorHandlingService.searchOperationResponseForErrors(ops)
		XCTAssert(containsErrors1?.errorType == .rpc)
		XCTAssert(containsErrors1?.rpcErrorString == "gas_exhausted.operation", containsErrors1?.rpcErrorString ?? "-")
		XCTAssert(containsErrors1?.description == "Error - RPC: gas_exhausted.operation", containsErrors1?.description ?? "-")
	}
	
	func testOperationResponseParserFailWith() {
		let error = OperationResponseInternalResultError(kind: "", id: "proto.012-Psithaca.michelson_v1.runtime_error", contract: nil, expected: nil, found: nil, location: 41, with: FailWith(string: nil, int: "14", args: nil))
		let operationResponseResultWithError = OperationResponseResult(status: "", balanceUpdates: nil, consumedMilligas: "", storageSize: "", paidStorageSizeDiff: "", allocatedDestinationContract: nil, errors: [error])
		let operationResponseResultWithoutError = OperationResponseResult(status: "", balanceUpdates: nil, consumedMilligas: "", storageSize: "", paidStorageSizeDiff: "", allocatedDestinationContract: nil, errors: nil)
		
		let operationMetadataWithError = OperationResponseMetadata(balanceUpdates: nil, operationResult: operationResponseResultWithError, internalOperationResults: nil)
		let operationMetadataWithoutError = OperationResponseMetadata(balanceUpdates: nil, operationResult: operationResponseResultWithoutError, internalOperationResults: nil)
		
		let ops = [
			OperationResponse(contents: [
				OperationResponseContent(kind: "", source: nil, metadata: operationMetadataWithError),
				OperationResponseContent(kind: "", source: nil, metadata: operationMetadataWithoutError)
			])
		]
		
		let containsErrors1 = ErrorHandlingService.searchOperationResponseForErrors(ops)
		XCTAssert(containsErrors1?.errorType == .rpc)
		XCTAssert(containsErrors1?.rpcErrorString == "A FAILWITH instruction was reached: {\"int\": 14}", containsErrors1?.rpcErrorString ?? "-")
		XCTAssert(containsErrors1?.description == "Error - RPC: A FAILWITH instruction was reached: {\"int\": 14}", containsErrors1?.description ?? "-")
	}
	
	func testJsonResponse() {
		let errorData = MockConstants.jsonStub(fromFilename: "error_smart-contract_gas_exhausted")
		
		guard let opResponse = try? JSONDecoder().decode([OperationResponse].self, from: errorData) else {
			XCTFail("Couldn't parse data as [OperationResponse]")
			return
		}
		
		let result2 = ErrorHandlingService.searchOperationResponseForErrors(opResponse)
		XCTAssert(result2?.rpcErrorString == "gas_exhausted.operation", result2?.rpcErrorString ?? "-")
		XCTAssert(result2?.description == "Error - RPC: gas_exhausted.operation", result2?.description ?? "-")

	}
	
	func testJsonDappResponse() {
		let errorData = MockConstants.jsonStub(fromFilename: "rpc_error_dapp-with-string")
		
		guard let opResponse = try? JSONDecoder().decode(OperationResponse.self, from: errorData) else {
			XCTFail("Couldn't parse data as [OperationResponse]")
			return
		}
		
		let result = ErrorHandlingService.searchOperationResponseForErrors(opResponse)
		XCTAssert(result?.rpcErrorString == "A FAILWITH instruction was reached: {\"string\": Dex/wrong-min-out}", result?.rpcErrorString ?? "-")
		XCTAssert(result?.description == "Error - RPC: A FAILWITH instruction was reached: {\"string\": Dex/wrong-min-out}", result?.description ?? "-")
	}
	
	func testNotEnoughBalanceResponse() {
		let errorData = MockConstants.jsonStub(fromFilename: "rpc_error_not-enough-token")
		
		guard let opResponse = try? JSONDecoder().decode(OperationResponse.self, from: errorData) else {
			XCTFail("Couldn't parse data as [OperationResponse]")
			return
		}
		
		let result = ErrorHandlingService.searchOperationResponseForErrors(opResponse)
		XCTAssert(result?.rpcErrorString == "A FAILWITH instruction was reached: {\"args\": [[\"string\": \"NotEnoughBalance\"]]}", result?.rpcErrorString ?? "-")
		XCTAssert(result?.description == "Error - RPC: A FAILWITH instruction was reached: {\"args\": [[\"string\": \"NotEnoughBalance\"]]}", result?.description ?? "-")
	}
	
	func testFailWithParsers() {
		let fw1 = FailWith(string: nil, int: "0", args: nil)
		let errorMessage1 = fw1.convertToHumanReadableMessage(parser: FailWithParserLiquidityBaking())
		XCTAssert(errorMessage1 == "token contract must have a transfer entrypoint", errorMessage1 ?? "-")
		
		let fw2 = FailWith(string: nil, int: "1", args: nil)
		let errorMessage2 = fw2.convertToHumanReadableMessage(parser: FailWithParserLiquidityBaking())
		XCTAssert(errorMessage2 == "unknown Liquidity Baking error code: 1", errorMessage2 ?? "-")
		
		let fw3 = FailWith(string: nil, int: "2", args: nil)
		let errorMessage3 = fw3.convertToHumanReadableMessage(parser: FailWithParserLiquidityBaking())
		XCTAssert(errorMessage3 == "self is updating token pool must be false", errorMessage3 ?? "-")
	}
}
