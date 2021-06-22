//
//  MockURLProtocol+Stream.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 16/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

extension URLRequest {

	func httpBodyStreamData() -> Data? {

		guard let bodyStream = self.httpBodyStream else { return nil }

		bodyStream.open()

		// Will read 16 chars per iteration. Can use bigger buffer if needed
		let bufferSize: Int = 16

		let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)

		var dat = Data()

		while bodyStream.hasBytesAvailable {

			let readDat = bodyStream.read(buffer, maxLength: bufferSize)
			dat.append(buffer, count: readDat)
		}

		buffer.deallocate()

		bodyStream.close()
		
		return dat
	}
}
