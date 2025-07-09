//
//  NetworkService.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 18/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import Combine
import os.log

/// Class responsible for sending all the networking requests, checking for http errors, RPC errors, Decoding the responses and optionally logging progress
public class NetworkService {
	
	// MARK: - Types
	
	/// Errors that can be returned by the `NetworkService`
	public enum NetworkError: Error {
		case parse(error: String)
		case invalidURL
		case unknown
		case httpError(statusCode: Int, response: String?)
	}
	
	
	
	// MARK: - Public Properties
	
	/// The `URLSession` used to preform all the networking operations
	public let urlSession: URLSession
	
	/// The `URLSession` used to preform all the networking operations
	public let loggingConfig: LoggingConfig
	
	
	
	// MARK: - Init
	
	/**
	Init an `NetworkService` with a `URLSession`
	- parameter urlSession: A `URLSession` object
	*/
	public init(urlSession: URLSession, loggingConfig: LoggingConfig) {
		self.urlSession = urlSession
		self.loggingConfig = loggingConfig
	}
	
	
	
	// MARK: - Functions
	
	/**
	A generic send function that takes an RPC, with a generic type conforming to `Decodable`, executes the request and returns the result.
	- parameter rpc: A instance of `RPC`.
	- parameter withNodeURLs: An array of nodeURLs from `TezosNodeConfig`.
	- parameter retryCount: An Int denoting the current number of attempts made. 3 is max.
	- parameter completion: A completion callback that will be executed on the main thread.
	- returns: Void
	*/
	public func send<T: Decodable>(rpc: RPC<T>, withNodeURLs nodeURLs: [URL], retryCount: Int = 0, completion: @escaping ((Result<T, KukaiError>) -> Void)) {
		var serverString = nodeURLs[retryCount].absoluteString
		
		if serverString.suffix(1) != "/" {
			serverString.append("/")
		}
		
		// Avoid using 'appendPathComponent' as it will percent encode '?' if included in RPC url. This causes some servers issues
		guard let fullURL =  URL(string: "\(serverString)\(rpc.endpoint)") else {
			completion(Result.failure(KukaiError.internalApplicationError(error: NetworkError.invalidURL)))
			return
		}
		
		
		self.request(url: fullURL, isPOST: rpc.isPost, withBody: rpc.payload, forReturnType: T.self) { [weak self] result in
			guard let _ = try? result.get() else {
				
				// if request failed on first attempt, we have more urls, and the error was a HTTP error. The retry with another URL
				// else return the error
				let failure = result.getFailure()
				let isRPCError = failure.errorType == .rpc
				let isHttpError = (failure.httpStatusCode ?? 0) >= 300
				if retryCount < nodeURLs.count-1, retryCount <= 3, (isRPCError || isHttpError) {
					self?.send(rpc: rpc, withNodeURLs: nodeURLs, retryCount: (retryCount + 1), completion: completion)
					
				} else {
					completion(result)
				}
				
				return
			}
			
			completion(result)
		}
	}
	
	/**
	A generic network request function that takes a URL, optional payload and a `Decodable` response type. Function will execute the request and attempt to parse the response.
	Using the Logging config, will auto log (or not) urls, response outputs, or fails to the console
	- parameter url: The full url, including query parameters to execute.
	- parameter isPOST: Bool indicating if its a POST or GET request.
	- parameter withBody: Optional Data to be passed as the body.
	- parameter forReturnType: The Type to parse the response as.
	- parameter completion: A completion block with a `Result<T, Error>` T being the supplied decoable type
	*/
	public func request<T: Decodable>(url: URL, isPOST: Bool, withBody body: Data?, forReturnType: T.Type, completion: @escaping ((Result<T, KukaiError>) -> Void)) {
		
		var request = URLRequest(url: url)
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpMethod = isPOST ? "POST" : "GET"
		
		if let payload = body {
			request.httpBody = payload
			request.cachePolicy = .reloadIgnoringCacheData
		}
		
		urlSession.dataTask(with: request) { [weak self] (data, response, error) in
			
			if let kukaiError = ErrorHandlingService.searchForSystemError(data: data, response: response, networkError: error, requestURL: url, requestData: body) {
				NetworkService.logRequestFailed(loggingConfig: self?.loggingConfig, isPost: isPOST, fullURL: url, payload: body, error: error, statusCode: kukaiError.httpStatusCode, responseData: data)
				completion(Result.failure( kukaiError ))
				return
			}
			
			// If no errors found, check we have a valid data object
			guard let d = data else {
				completion(Result.failure( KukaiError.unknown() ))
				return
			}
			
			// Log request success
			NetworkService.logRequestSucceded(loggingConfig: self?.loggingConfig, isPost: isPOST, fullURL: url, payload: body, responseData: data)
			
			do {
				// If the response type passed in is `Data`, just return the raw value without doing any parsing
				if T.self == Data.self, let dt = d as? T {
					completion(Result.success(dt))
					return
				}
				
				// Else try to parse the JSON
				let parsedResponse = try JSONDecoder().decode(T.self, from: d)
				
				// Check for RPC errors, if none, return success
				if let rpcOperationError = self?.checkForRPCOperationErrors(parsedResponse: parsedResponse, withRequestURL: url, requestPayload: body, responsePayload: d, httpStatusCode: (response as? HTTPURLResponse)?.statusCode) {
					completion(Result.failure(rpcOperationError))
					
				} else {
					completion(Result.success(parsedResponse))
				}
				
			} catch (let error) {
				
				/// RPC annoyingly returns multiple different types of responses for error situations. When requesting an `OperationResponse` it may sometimes return one with an error inside, or return a new object in an array `[OperationResponse]` with errors inside
				/// We try to catch an issue where network client was expecting 1 object, but got back an array of objects with errors inside. We attempt to parse the new object looking for errors instead of unnecessarily throwing DecodingError.typeMistach(...) errors
				if error is DecodingError,
				   let parsedResponse = try? JSONDecoder().decode([OperationResponse].self, from: d),
				   let rpcOperationError = self?.checkForRPCOperationErrors(parsedResponse: parsedResponse, withRequestURL: url, requestPayload: body, responsePayload: d, httpStatusCode: (response as? HTTPURLResponse)?.statusCode)
				{
					completion(Result.failure(rpcOperationError))
				}
				
				/// In extreme situations, where something completely incorrect is sent to the RPC (think i'll formed addresses or negative numbers). Instead of an object containing errors, you will just get a string containing something looking like a stacktrace
				else if error is DecodingError,
						  let parsedResponse = try? JSONDecoder().decode(String.self, from: d),
						  parsedResponse.contains("Assert")
				{
					var errorToReturn = KukaiError.unknown(withString: parsedResponse)
					errorToReturn.addNetworkData(requestURL: url, requestJSON: body, responseJSON: d, httpStatusCode: (response as? HTTPURLResponse)?.statusCode)
					completion(Result.failure( errorToReturn ))
				}
				
				/// If those don't work, just return the original error
				else
				{
					if error is DecodingError {
						// Specifically tag DecodingErrors, as can be an issue with GraphQL that clients want to more easily catch
						completion(Result.failure( KukaiError.decodingError(error: error) ))
						
					} else {
						completion(Result.failure( KukaiError.internalApplicationError(error: error) ))
					}
				}
				
				return
			}
		}.resume()
		NetworkService.logRequestStart(loggingConfig: loggingConfig, fullURL: url)
	}
	
	/**
	A generic network request function that takes a URL, optional payload and a `Decodable` response type. Function will execute the request and attempt to parse the response, returning it as a combine publisher.
	Using the Logging config, will auto log (or not) urls, response outputs, or fails to the console
	- parameter url: The full url, including query parameters to execute.
	- parameter isPOST: Bool indicating if its a POST or GET request.
	- parameter withBody: Optional Data to be passed as the body.
	- parameter forReturnType: The Type to parse the response as.
	- returns: A publisher of the supplied return type, or error response
	*/
	public func request<T: Decodable>(url: URL, isPOST: Bool, withBody body: Data?, forReturnType: T.Type) -> AnyPublisher<T, KukaiError> {
		return Future<T, KukaiError> { [weak self] promise in
			self?.request(url: url, isPOST: isPOST, withBody: body, forReturnType: forReturnType) { result in
				guard let output = try? result.get() else {
					let error = (try? result.getError()) ?? KukaiError.unknown()
					promise(.failure(error))
					return
				}
				
				promise(.success(output))
			}
		}.eraseToAnyPublisher()
	}
	
	/**
	 Send a HTTP DELETE to a given URL
	 */
	public func delete(url: URL, completion: @escaping ((Result<Bool, KukaiError>) -> Void)) {
		var request = URLRequest(url: url)
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpMethod = "DELETE"
		
		urlSession.dataTask(with: request) { (data, response, error) in
			if let err = error {
				completion(Result.failure(KukaiError.internalApplicationError(error: err)))
			} else {
				completion(Result.success(true))
			}
		}.resume()
		NetworkService.logRequestStart(loggingConfig: loggingConfig, fullURL: url)
	}
	
	/**
	 Send a HTTP DELETE to a given URL
	 */
	public func delete(url: URL) -> AnyPublisher<Bool, KukaiError> {
		return Future<Bool, KukaiError> { [weak self] promise in
			self?.delete(url: url, completion: { result in
				guard let output = try? result.get() else {
					let error = (try? result.getError()) ?? KukaiError.unknown()
					promise(.failure(error))
					return
				}
				
				promise(.success(output))
			})
		}.eraseToAnyPublisher()
	}
	
	func checkForRPCOperationErrors(parsedResponse: Any, withRequestURL: URL?, requestPayload: Data?, responsePayload: Data?, httpStatusCode: Int?) -> KukaiError? {
		var operations: [OperationResponse] = []
		
		if parsedResponse is OperationResponse, let asOperation = parsedResponse as? OperationResponse {
			operations = [asOperation]
			
		} else if parsedResponse is [OperationResponse], let asOperations = parsedResponse as? [OperationResponse] {
			operations = asOperations
		}
		
		var error = ErrorHandlingService.searchOperationResponseForErrors(operations, requestURL: withRequestURL)
		error?.addNetworkData(requestURL: withRequestURL, requestJSON: requestPayload, responseJSON: responsePayload, httpStatusCode: httpStatusCode)
		
		return error
	}
	
	
	
	// MARK: - Logging
	
	/// Logging details of request failures using `os_log` global logging
	public static func logRequestFailed(loggingConfig: LoggingConfig?, isPost: Bool, fullURL: URL, payload: Data?, error: Error?, statusCode: Int?, responseData: Data?) {
		if !(loggingConfig?.logNetworkFailures ?? false) { return }
		
		let payloadString = String(data: payload ?? Data(), encoding: .utf8) ?? ""
		let dataString = NetworkService.dataToStringStippingMichelsonContractCode(data: responseData)
		
		if isPost {
			Logger.network.error("Request Failed to: \(fullURL.absoluteString) \nRequest Body: \(payloadString) \nError: \(String(describing: error)) \nStatusCode: \(String(describing: statusCode)) \nResponse: \(dataString) \n_")
		} else {
			Logger.network.error("Request Failed to: \(fullURL.absoluteString) \nError: \(String(describing: error)) \nResponse: \(dataString) \n_")
		}
	}
	
	/// Logging details of successful requests using `os_log` global logging
	public static func logRequestSucceded(loggingConfig: LoggingConfig?, isPost: Bool, fullURL: URL, payload: Data?, responseData: Data?) {
		if !(loggingConfig?.logNetworkSuccesses ?? false) { return }
		
		let payloadString = String(data: payload ?? Data(), encoding: .utf8) ?? ""
		let dataString = NetworkService.dataToStringStippingMichelsonContractCode(data: responseData)
		
		if isPost {
			Logger.network.info("Request Succeeded to: \(fullURL.absoluteString) \nRequest Body: \(payloadString) \nResponse: \(dataString) \n_")
		} else {
			Logger.network.info("Request Succeeded to: \(fullURL.absoluteString) \nResponse: \(dataString) \n_")
		}
	}
	
	/// Logging details when a request starts using `os_log` global logging
	public static func logRequestStart(loggingConfig: LoggingConfig?, fullURL: URL) {
		if !(loggingConfig?.logNetworkFailures ?? false) && !(loggingConfig?.logNetworkSuccesses ?? false) { return }
		
		Logger.network.info("Sending request to: \(fullURL.absoluteString)")
	}
	
	/**
	When an error occurs involving a smart contract, the RPC will return the entire contract as part of the JSON, exceeding the logging's max size.
	We check can we parse it to our object and strip out all the unnecessary attributes to avoid overloading the logger and making it possible to debug
	*/
	private static func dataToStringStippingMichelsonContractCode(data: Data?) -> String {
		if let d = data,
		   let asOperation = try? JSONDecoder().decode(OperationResponse.self, from: d),
		   let data = try? JSONEncoder().encode(asOperation) {
			
			return String(data: data, encoding: .utf8) ?? ""
			
		} else {
			return String(data: data ?? Data(), encoding: .utf8) ?? ""
		}
	}
}
