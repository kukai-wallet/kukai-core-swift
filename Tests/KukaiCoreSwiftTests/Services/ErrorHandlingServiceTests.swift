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
	
	enum TestError: Error {
		case example
		case parseError
	}
	
	
	func testClassMethods() {
		
		let error1 = KukaiError.error(string: "Blah", errorType: .counterError)
		XCTAssert(error1.errorString == "Blah")
		XCTAssert(error1.errorType == .counterError)
		XCTAssert(error1.errorObject == nil)
		XCTAssert(error1.httpStatusCode == nil)
		
		let error2 = KukaiError.internalApplicationError(error: TestError.example)
		XCTAssert(error2.errorString == KukaiError.errorToString(TestError.example), "left: '\(error2.errorString ?? "")' != right: `\(KukaiError.errorToString(TestError.parseError))`")
		XCTAssert(error2.errorType == .internalApplicationError)
		XCTAssert(error2.errorObject != nil)
		XCTAssert(error2.httpStatusCode == nil)
		
		let error3 = KukaiError.unknownParseError(error: TestError.parseError)
		XCTAssert(error3.errorString == KukaiError.errorToString(TestError.parseError))
		XCTAssert(error3.errorType == .unknownParseError)
		XCTAssert(error3.errorObject == nil)
		XCTAssert(error3.httpStatusCode == nil)
		
		let error4 = KukaiError.unknown()
		XCTAssert(error4.errorString == nil)
		XCTAssert(error4.errorType == .unknownError)
		XCTAssert(error4.errorObject == nil)
		XCTAssert(error4.httpStatusCode == nil)
		
		let errorString = KukaiError.errorToString(TestError.parseError)
		XCTAssert(errorString == "parseError", errorString)
	}
	
	func testParseString() {
		let errorString1 = "balance_too_low"
		let kukaiError1 = ErrorHandlingService.parse(string: errorString1)
		XCTAssert(kukaiError1.errorType == .insufficientFunds)
		
		let errorString2 = "Counter 147222 already used for contract"
		let kukaiError2 = ErrorHandlingService.parse(string: errorString2)
		XCTAssert(kukaiError2.errorType == .counterError)
		
		let errorString3 = "The Internet connection appears to be offline."
		let kukaiError3 = ErrorHandlingService.parse(string: errorString3)
		XCTAssert(kukaiError3.errorType == .noInternetConnection)
		
		let errorString4 = "The request timed out."
		let kukaiError4 = ErrorHandlingService.parse(string: errorString4)
		XCTAssert(kukaiError4.errorType == .requestTimeOut)
		
		let errorString5 = "too many HTTP redirects"
		let kukaiError5 = ErrorHandlingService.parse(string: errorString5)
		XCTAssert(kukaiError5.errorType == .tooManyRedirects)
	}
	
	func testParseData() {
		let requestURL = URL(string: "http://google.com")!
		
		let successURLResponse = HTTPURLResponse(url: URL(string: "http://google.com")!, statusCode: 400, httpVersion: nil, headerFields: nil)
		let error1 = ErrorHandlingService.parse(data: "The Internet connection appears to be offline.".data(using: .utf8) ?? Data(), response: successURLResponse, networkError: TestError.example, requestURL: requestURL, requestData: nil)
		XCTAssert(error1?.errorType == .noInternetConnection)
		XCTAssert(error1?.errorObject != nil)
		XCTAssert(error1?.httpStatusCode == 400)
		
		let errorURLResponse = HTTPURLResponse(url: URL(string: "http://google.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
		let error2 = ErrorHandlingService.parse(data: nil, response: errorURLResponse, networkError: TestError.example, requestURL: requestURL, requestData: nil)
		XCTAssert(error2?.errorObject is TestError)
		XCTAssert((error2?.errorObject as? TestError) == TestError.example)
	}
	
	func testContainsError() {
		let tzktOpsWithError = [
			TzKTOperation(type: "", id: 4, level: 4, timestamp: "", block: "", hash: "", counter: 4, status: "", errors: nil),
			TzKTOperation(type: "", id: 4, level: 4, timestamp: "", block: "", hash: "", counter: 4, status: "", errors: [
				TzKTOperationError(type: "gas_exhausted")
			]),
			TzKTOperation(type: "", id: 4, level: 4, timestamp: "", block: "", hash: "", counter: 4, status: "", errors: nil)
		]
		let containsErrors1 = ErrorHandlingService.containsErrors(tzktOperations: tzktOpsWithError)
		XCTAssert(containsErrors1)
		
		let tzktOpsWithoutError = [
			TzKTOperation(type: "", id: 4, level: 4, timestamp: "", block: "", hash: "", counter: 4, status: "", errors: nil),
			TzKTOperation(type: "", id: 4, level: 4, timestamp: "", block: "", hash: "", counter: 4, status: "", errors: nil)
		]
		let containsErrors2 = ErrorHandlingService.containsErrors(tzktOperations: tzktOpsWithoutError)
		XCTAssert(containsErrors2 == false)
	}
	
	func testExtractMeaningfulErrorsFromTzKT() {
		let tzktOpsWithError = [
			TzKTOperation(type: "", id: 4, level: 4, timestamp: "", block: "", hash: "", counter: 4, status: "", errors: nil),
			TzKTOperation(type: "", id: 4, level: 4, timestamp: "", block: "", hash: "", counter: 4, status: "", errors: [
				TzKTOperationError(type: "blah"),
				TzKTOperationError(type: "something weird")
			]),
			TzKTOperation(type: "", id: 4, level: 4, timestamp: "", block: "", hash: "", counter: 4, status: "", errors: [
				TzKTOperationError(type: "balance_too_low")
			]),
			TzKTOperation(type: "", id: 4, level: 4, timestamp: "", block: "", hash: "", counter: 4, status: "", errors: nil)
		]
		let containsErrors1 = ErrorHandlingService.extractMeaningfulErrors(fromTzKTOperations: tzktOpsWithError)
		XCTAssert(containsErrors1?.errorType == .insufficientFunds)
	}
	
	func testExtractMeaningfulErrorsFromRPC() {
		
		let error = OperationResponseInternalResultError(kind: "", id: "", location: 41, with: OperationResponseInternalResultErrorWith(string: "balance_too_low", int: nil, args: nil))
		let operationResponseResultWithError = OperationResponseResult(status: "", balanceUpdates: nil, consumedGas: "", storageSize: "", paidStorageSizeDiff: "", allocatedDestinationContract: nil, errors: [error])
		let operationResponseResultWithoutError = OperationResponseResult(status: "", balanceUpdates: nil, consumedGas: "", storageSize: "", paidStorageSizeDiff: "", allocatedDestinationContract: nil, errors: nil)
		
		let operationMetadataWithError = OperationResponseMetadata(balanceUpdates: nil, operationResult: operationResponseResultWithError, internalOperationResults: nil)
		let operationMetadataWithoutError = OperationResponseMetadata(balanceUpdates: nil, operationResult: operationResponseResultWithoutError, internalOperationResults: nil)
		
		let ops = [
			OperationResponse(contents: [
				OperationResponseContent(kind: "", source: nil, metadata: operationMetadataWithError),
				OperationResponseContent(kind: "", source: nil, metadata: operationMetadataWithoutError)
			])
		]
		
		let containsErrors1 = ErrorHandlingService.extractMeaningfulErrors(fromRPCOperations: ops, withRequestURL: nil, requestPayload: nil, responsePayload: nil, httpStatusCode: nil)
		XCTAssert(containsErrors1?.errorType == .insufficientFunds)
	}
	
	func testTest() {
		let errorData = MockConstants.jsonStub(fromFilename: "error_smart-contract_gas_exhausted")
		
		guard let opResponse = try? JSONDecoder().decode([OperationResponse].self, from: errorData) else {
			XCTFail("Couldn't parse data as [OperationResponse]")
			return
		}
		
		let result = ErrorHandlingService.extractMeaningfulErrors(fromRPCOperations: opResponse, withRequestURL: nil, requestPayload: nil, responsePayload: nil, httpStatusCode: nil)
		XCTAssert(result?.errorString == "", result?.errorString ?? "-")
		
		
		let result2 = ErrorTest.searchOperationResponseForErrors(opResponse)
		XCTAssert(result2?.rpcErrorString == "gas_exhausted.operation", result2?.rpcErrorString ?? "-")
		XCTAssert(result2?.description == "Error - RPC: gas_exhausted.operation", result2?.description ?? "-")
	}
}
