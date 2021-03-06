//
//  NetworkService.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 18/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
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
	- parameter withBaseURL: The base URL needed. This will typically come from `TezosNodeConfig`.
	- parameter completion: A completion callback that will be executed on the main thread.
	- returns: Void
	*/
	public func send<T: Decodable>(rpc: RPC<T>, withBaseURL baseURL: URL, completion: @escaping ((Result<T, ErrorResponse>) -> Void)) {
		let fullURL = baseURL.appendingPathComponent(rpc.endpoint)
		
		self.request(url: fullURL, isPOST: rpc.isPost, withBody: rpc.payload, forReturnType: T.self, completion: completion)
	}
	
	/**
	A generic network request function that takes a URL, optional payload and a `Decodable` response type. Function will execute teh request and attempt to parse the response.
	Using the Logging config, will auto log (or not) urls, response outputs, or fails to the console
	- parameter url: The full url, including query parameters to execute.
	- parameter isPOST: Bool indicating if its a POST or GET request.
	- parameter withBody: Optional Data to be passed as the body.
	- parameter forReturnType: The Type to parse the response as.
	- parameter completion: A completion block with a `Result<T, Error>` T being the supplied decoable type
	- returns: Void
	*/
	public func request<T: Decodable>(url: URL, isPOST: Bool, withBody body: Data?, forReturnType: T.Type, completion: @escaping ((Result<T, ErrorResponse>) -> Void)) {
		
		var request = URLRequest(url: url)
		request.addValue("application/json", forHTTPHeaderField: "Accept")
		request.addValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpMethod = isPOST ? "POST" : "GET"
		
		if let payload = body {
			request.httpBody = payload
			request.cachePolicy = .reloadIgnoringCacheData
		}
		
		urlSession.dataTask(with: request) { [weak self] (data, response, error) in
			
			// Check for errors and non-standard errors, returning a custom ErrorResponse object if found
			if let errorResponse = ErrorHandlingService.parse(data: data, response: response, networkError: error, requestURL: url, requestData: body) {
				NetworkService.logRequestFailed(loggingConfig: self?.loggingConfig, isPost: isPOST, fullURL: url, payload: body, error: error, statusCode: errorResponse.httpStatusCode, responseData: data)
				DispatchQueue.main.async { completion(Result.failure( errorResponse )) }
				return
			}
			
			// If no errors found, check we have a valid data object
			guard let d = data else {
				DispatchQueue.main.async { completion(Result.failure( ErrorResponse.unknownError() )) }
				return
			}
			
			// Log request success
			NetworkService.logRequestSucceded(loggingConfig: self?.loggingConfig, isPost: isPOST, fullURL: url, payload: body, responseData: data)
			
			// Attempt to parse to the required type, and check for RPC errors, embedded in the returned object
			var tempParsedResponse: T? = nil
			var isAllowFragmentsError = false
			
			
			// Because iOS 12 doesn't support allowFragments inside JSONDecoder, and because we have many object types expecting to use decode(fromDecoder)
			// We first test can we decode the JSON the way we want to. If it fails because of a fragmetn error, we record the state and carry on. Other errors cause an early exit
			do {
				tempParsedResponse = try JSONDecoder().decode(T.self, from: d)
				
			} catch (let error) {
				if let underlyingError = error.underlyingError, underlyingError.code == 3840 { // fragment error code
					isAllowFragmentsError = true
					
				} else {
					DispatchQueue.main.async { completion(Result.failure( ErrorResponse.unknownParseError(error: error) )) }
					return
				}
			}
			
			
			// Check if we have a nil object and the reason is because of the fragment error
			// The fragment should always be a string, in which case we can just use the standard `JSONSerialization` and cast
			if tempParsedResponse == nil && isAllowFragmentsError {
				do {
					tempParsedResponse = try JSONSerialization.jsonObject(with: d, options: .allowFragments) as? T
				} catch (let error) {
					DispatchQueue.main.async { completion(Result.failure( ErrorResponse.unknownParseError(error: error) )) }
					return
				}
			}
			
			
			// Ensure we have a valid object
			guard let parsedResponse = tempParsedResponse else {
				DispatchQueue.main.async { completion(Result.failure( ErrorResponse.error(string: "", errorType: .unknownParseError) )) }
				return
			}
			
			
			// Check for RPC errors, if none, return success
			if let rpcOperationError = self?.checkForRPCOperationErrors(parsedResponse: parsedResponse, withRequestURL: url, requestPayload: body, responsePayload: d, httpStatusCode: (response as? HTTPURLResponse)?.statusCode ) {
				DispatchQueue.main.async { completion(Result.failure(rpcOperationError)) }
				
			} else {
				DispatchQueue.main.async { completion(Result.success(parsedResponse)) }
			}
		}.resume()
		NetworkService.logRequestStart(loggingConfig: loggingConfig, fullURL: url)
	}
	
	func checkForRPCOperationErrors(parsedResponse: Any, withRequestURL: URL?, requestPayload: Data?, responsePayload: Data?, httpStatusCode: Int?) -> ErrorResponse? {
		var operations: [OperationResponse] = []
		
		if parsedResponse is OperationResponse, let asOperation = parsedResponse as? OperationResponse {
			operations = [asOperation]
			
		} else if parsedResponse is [OperationResponse], let asOperations = parsedResponse as? [OperationResponse] {
			operations = asOperations
		}
		
		return ErrorHandlingService.extractMeaningfulErrors(fromRPCOperations: operations, withRequestURL: withRequestURL, requestPayload: requestPayload, responsePayload: responsePayload, httpStatusCode: httpStatusCode)
	}
	
	
	
	// MARK: - Logging
	
	/// Logging details of request failures using `os_log` global logging
	public static func logRequestFailed(loggingConfig: LoggingConfig?, isPost: Bool, fullURL: URL, payload: Data?, error: Error?, statusCode: Int?, responseData: Data?) {
		if !(loggingConfig?.logNetworkFailures ?? false) { return }
		
		let errorString = ErrorResponse.errorToString(error)
		let payloadString = String(data: payload ?? Data(), encoding: .utf8) ?? ""
		let dataString = String(data: responseData ?? Data(), encoding: .utf8) ?? ""
		
		if isPost {
			os_log(.error, log: .network, "Request Failed to: %@ \nRequest Body: %@ \nError: %@ \nStatusCode: %@ \nResponse: %@ \n_", fullURL.absoluteString, payloadString, errorString, "\(String(describing: statusCode))", dataString)
		} else {
			os_log(.error, log: .network, "Request Failed to: %@ \nError: %@ \nResponse: %@ \n_", fullURL.absoluteString, errorString, dataString)
		}
	}
	
	/// Logging details of successful requests using `os_log` global logging
	public static func logRequestSucceded(loggingConfig: LoggingConfig?, isPost: Bool, fullURL: URL, payload: Data?, responseData: Data?) {
		if !(loggingConfig?.logNetworkSuccesses ?? false) { return }
		
		let payloadString = String(data: payload ?? Data(), encoding: .utf8) ?? ""
		let dataString = String(data: responseData ?? Data(), encoding: .utf8) ?? ""
		
		if isPost {
			os_log(.debug, log: .network, "Request Succeeded to: %@ \nRequest Body: %@ \nResponse: %@ \n_", fullURL.absoluteString, payloadString, dataString)
		} else {
			os_log(.debug, log: .network, "Request Succeeded to: %@ \nResponse: %@ \n_", fullURL.absoluteString, dataString)
		}
	}
	
	/// Logging details when a request starts using `os_log` global logging
	public static func logRequestStart(loggingConfig: LoggingConfig?, fullURL: URL) {
		if !(loggingConfig?.logNetworkFailures ?? false) && !(loggingConfig?.logNetworkSuccesses ?? false) { return }
		
		os_log(.debug, log: .network, "Sending request to: %@", fullURL.absoluteString)
	}
}
