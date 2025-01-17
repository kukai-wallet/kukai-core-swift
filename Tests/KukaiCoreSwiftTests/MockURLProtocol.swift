//
//  MockURLProtocol.swift
//  KukaiCoreSwiftTests
//
//  Created by Simon Mcloughlin on 16/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import KukaiCoreSwift

struct MockPostUrlKey: Hashable {
	let url: URL
	let requestData: Data
}

class MockURLProtocol: URLProtocol {
	
	private static var lastForgeRequest: Data? = nil
	private let forgeURL = MockConstants.shared.config.nodeURLs[0].appendingPathComponent("chains/main/blocks/head/helpers/forge/operations")
	private let parseURL = MockConstants.shared.config.nodeURLs[1].appendingPathComponent("chains/main/blocks/head/helpers/parse/operations")
	
	
	/// Dictionary maps URLs to tuples of data, and response
	static var mockURLs = [URL?: (data: Data?, response: HTTPURLResponse?)]()
	static var errorURLs = [URL?: (data: Data?, response: HTTPURLResponse?)]()
	
	static var mockPostURLs = [MockPostUrlKey: (data: Data?, response: HTTPURLResponse?)]()
	static var errorPostURLs = [MockPostUrlKey: (data: Data?, response: HTTPURLResponse?)]()
	
	
	override class func canInit(with request: URLRequest) -> Bool {
			return true
	}
	
	override class func canonicalRequest(for request: URLRequest) -> URLRequest {
		return request
	}

	override func startLoading() {
		
		if let url = request.url {
			
			let unencodedString = url.absoluteString.removingPercentEncoding ?? ""
			let unencodedUrl = URL(string: unencodedString)!
			
			if let body = request.httpBodyStreamData() {
				self.handlePostURL(mockPostUrlKey: MockPostUrlKey(url: unencodedUrl, requestData: body))
				
			} else {
				self.handleGetURL(url: unencodedUrl)
			}
		}
		
		self.client?.urlProtocolDidFinishLoading(self)
	}
	
	func handleGetURL(url: URL) {
		
		// Check if URL is in the error list first as many error URL's and Success URLs will be indentical
		if let (data, response) = MockURLProtocol.errorURLs[url] {
			
			if let res = response {
				self.client?.urlProtocol(self, didReceive: res, cacheStoragePolicy: .notAllowed)
			}
			
			if let d = data {
				self.client?.urlProtocol(self, didLoad: d)
			}
			
			// remove it from the list
			if let index = MockURLProtocol.errorURLs.index(forKey: url) {
				MockURLProtocol.errorURLs.remove(at: index)
			}
			
			self.client?.urlProtocolDidFinishLoading(self)
			return
		}
		
		
		// Special case. Parse will fail it if doesn't match the data returned from network. Need to cache and return
		if url.absoluteString == forgeURL.absoluteString {
			let payloadSent = try? JSONDecoder().decode(OperationPayload.self, from: request.httpBodyStreamData() ?? Data())
			let payloadAsArray = [payloadSent]
			MockURLProtocol.lastForgeRequest = try? JSONEncoder().encode(payloadAsArray)
			
			
		} else if url.absoluteString == parseURL.absoluteString {
			self.client?.urlProtocol(self, didLoad: MockURLProtocol.lastForgeRequest ?? Data())
			self.client?.urlProtocolDidFinishLoading(self)
			return
		}
		
		
		// Handle other URLs
		if let (data, response) = MockURLProtocol.mockURLs[url] {
			
			if let res = response {
				self.client?.urlProtocol(self, didReceive: res, cacheStoragePolicy: .notAllowed)
			}
			
			if let d = data {
				self.client?.urlProtocol(self, didLoad: d)
			}
		} else {
			
			if let body = request.httpBodyStreamData() {
				fatalError("POST URL not mocked: \(url.absoluteString), \nwith request: \(String(data: body, encoding: .utf8) ?? "")")
				
			} else {
				fatalError("URL not mocked: \(url.absoluteString)")
			}
		}
	}
	
	func handlePostURL(mockPostUrlKey: MockPostUrlKey) {
		
		// Check if URL is in the error list first as many error URL's and Success URLs will be indentical
		if let (data, response) = MockURLProtocol.errorURLs[mockPostUrlKey.url] {
			
			if let res = response {
				self.client?.urlProtocol(self, didReceive: res, cacheStoragePolicy: .notAllowed)
			}
			
			if let d = data {
				self.client?.urlProtocol(self, didLoad: d)
			}
			
			// remove it from the list
			if let index = MockURLProtocol.errorURLs.index(forKey: mockPostUrlKey.url) {
				MockURLProtocol.errorURLs.remove(at: index)
			}
			
			self.client?.urlProtocolDidFinishLoading(self)
			return
		}
		
		// Check if URL is in the error list first as many error URL's and Success URLs will be indentical
		if let (data, response) = MockURLProtocol.errorPostURLs[mockPostUrlKey] {
			
			if let res = response {
				self.client?.urlProtocol(self, didReceive: res, cacheStoragePolicy: .notAllowed)
			}
			
			if let d = data {
				self.client?.urlProtocol(self, didLoad: d)
			}
			
			// remove it from the list
			if let index = MockURLProtocol.errorPostURLs.index(forKey: mockPostUrlKey) {
				MockURLProtocol.errorPostURLs.remove(at: index)
			}
			
			self.client?.urlProtocolDidFinishLoading(self)
			return
		}
		
		// Handle other URLs
		if let (data, response) = MockURLProtocol.mockPostURLs[mockPostUrlKey] {
			
			if let res = response {
				self.client?.urlProtocol(self, didReceive: res, cacheStoragePolicy: .notAllowed)
			}
			
			if let d = data {
				self.client?.urlProtocol(self, didLoad: d)
			}
		} else {
			handleGetURL(url: mockPostUrlKey.url)
		}
	}

	override func stopLoading() {
		
	}
	
	static func triggerGasExhaustedErrorOnSimulateOperation(nodeUrl: Int = 0) {
		var url = MockConstants.shared.config.nodeURLs[nodeUrl].appendingPathComponent("chains/main/blocks/head/helpers/scripts/simulate_operation")
		url.appendQueryItem(name: "version", value: "1")
		MockURLProtocol.errorURLs[url] = (data: MockConstants.jsonStub(fromFilename: "rpc_error_gas"), response: MockConstants.http200)
	}
	
	static func triggerAssertErrorOnSimulateOperation(nodeUrl: Int = 0) {
		var url = MockConstants.shared.config.nodeURLs[nodeUrl].appendingPathComponent("chains/main/blocks/head/helpers/scripts/simulate_operation")
		url.appendQueryItem(name: "version", value: "1")
		MockURLProtocol.errorURLs[url] = (data: MockConstants.jsonStub(fromFilename: "rpc_error_assert"), response: MockConstants.http200)
	}
	
	static func triggerCounterInFutureError(nodeUrl: Int = 0) {
		let url = MockConstants.shared.config.nodeURLs[nodeUrl].appendingPathComponent("chains/main/blocks/head/helpers/preapply/operations")
		MockURLProtocol.errorURLs[url] = (data: MockConstants.jsonStub(fromFilename: "rpc_error_counter-in-future"), response: MockConstants.http500)
	}
	
	static func triggerHttp500ErrorOnSimulateOperation(nodeUrl: Int = 0) {
		var url = MockConstants.shared.config.nodeURLs[nodeUrl].appendingPathComponent("chains/main/blocks/head/helpers/scripts/simulate_operation")
		url.appendQueryItem(name: "version", value: "1")
		MockURLProtocol.errorURLs[url] = (data: nil, response: MockConstants.http500)
	}
}
