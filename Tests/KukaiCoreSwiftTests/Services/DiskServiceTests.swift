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
}
