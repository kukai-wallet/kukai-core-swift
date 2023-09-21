//
//  DiskServiceTests.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 25/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import XCTest
@testable import KukaiCoreSwift

class DiskServiceTests: XCTestCase {
	
	
	
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }
	
	
	func testCodable() {
		let deleteResult = DiskService.delete(fileName: MockConstants.testCodableFilename)
		XCTAssert(deleteResult)
		
		let existsResult = DiskService.exists(fileName: MockConstants.testCodableFilename)
		XCTAssert(existsResult == nil)
		
		let writeResult = DiskService.write(encodable: MockConstants.testCodableInstance, toFileName: MockConstants.testCodableFilename)
		XCTAssert(writeResult)
		
		let existsResult2 = DiskService.exists(fileName: MockConstants.testCodableFilename)
		XCTAssert(existsResult2 != nil)
		
		let readResult = DiskService.read(type: MockConstants.TestCodable.self, fromFileName: MockConstants.testCodableFilename)
		XCTAssert(readResult?.text == MockConstants.testCodableInstance.text)
		XCTAssert(readResult?.number == MockConstants.testCodableInstance.number)
		XCTAssert(readResult?.date.timeIntervalSince1970 == MockConstants.testCodableTimestmap)
		
		let deleteResult2 = DiskService.delete(fileName: MockConstants.testCodableFilename)
		XCTAssert(deleteResult2)
	}
	
	func testData() {
		let deleteResult = DiskService.delete(fileName: MockConstants.testCodableFilename)
		XCTAssert(deleteResult)
		
		let existsResult = DiskService.exists(fileName: MockConstants.testCodableFilename)
		XCTAssert(existsResult == nil)
		
		let writeResult = DiskService.write(data: MockConstants.testCodableData, toFileName: MockConstants.testCodableFilename)
		XCTAssert(writeResult)
		
		let existsResult2 = DiskService.exists(fileName: MockConstants.testCodableFilename)
		XCTAssert(existsResult2 != nil)
		
		let readResult = DiskService.readData(fromFileName: MockConstants.testCodableFilename)
		let resultAsString = String(data: readResult ?? Data(), encoding: .utf8)
		XCTAssert( resultAsString == MockConstants.testCodableString )
		
		let deleteResult2 = DiskService.delete(fileName: MockConstants.testCodableFilename)
		XCTAssert(deleteResult2)
	}
	
	func testDocumentsDirectory() {
		let url = DiskService.documentsDirectory()
		XCTAssert(url != nil)
	}
	
	func testBulk() {
		let writeResult1 = DiskService.write(encodable: MockConstants.testCodableInstance, toFileName: "bulk-test-1")
		XCTAssert(writeResult1)
		
		let writeResult2 = DiskService.write(encodable: MockConstants.testCodableInstance, toFileName: "bulk-test-2")
		XCTAssert(writeResult2)
		
		let writeResult3 = DiskService.write(encodable: MockConstants.testCodableInstance, toFileName: "bulk-test-3")
		XCTAssert(writeResult3)
		
		let writeResult4 = DiskService.write(encodable: MockConstants.testCodableInstance, toFileName: "something-else")
		XCTAssert(writeResult4)
		
		let bulkSearchResult = DiskService.allFileNamesWith(prefix: "bulk-test")
		XCTAssert(bulkSearchResult.count == 3)
		
		let bulkDelete = DiskService.delete(fileNames: bulkSearchResult)
		XCTAssert(bulkDelete)
		
		let leftOverSearchResult = DiskService.allFileNamesWith(prefix: "something-else")
		XCTAssert(leftOverSearchResult.count == 1)
		
		let deleteResult = DiskService.delete(fileName: "something-else")
		XCTAssert(deleteResult)
	}
}
