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
	
	func testRemoteFetch_1() {
		
		// URLSession downloadTask doesn't care if its actually remote or not, can pass a url to a local file and it will process as though its remote
		guard let path = Bundle.module.url(forResource: "delegate", withExtension: "json", subdirectory: "Stubs") else {
			XCTFail("Can't find file")
			return
		}
		
		let folderName = "models"
		let expectation = XCTestExpectation(description: "diskservice-remote")
		
		
		if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
			print("Documents Directory: \(documentsPath)")
		}
		
		DiskService.fetchRemoteFile(url: path, storeInFolder: folderName) { result in
			guard let _ = try? result.get() else {
				XCTFail("returned error: \(result)")
				return
			}
			
			let size = DiskService.sizeOfFolder(folderName) ?? 0
			XCTAssert(size > 0, "size of folder is zero")
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testRemoteFetch_2() {
		let folderName = "models"
		let expectation = XCTestExpectation(description: "diskservice-remote-2")
		
		DiskService.clearFiles(inFolder: folderName, olderThanDays: 0) { error in
			if let err = error {
				XCTFail("error'd removing file: \(err)")
				
			} else {
				let size = DiskService.sizeOfFolder(folderName) ?? 0
				XCTAssert(size == 0, "folder is not empty")
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
}
