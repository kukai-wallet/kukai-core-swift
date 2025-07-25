//
//  ErrorHandlingService.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 27/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import os.log

/**
 A struct conforming to `Error`, attempting to handle errors from all sources (RPC, network, OS, other services/components/libraries), without the implementing code having to deal with each layer themselves.
 Comes with helpers to extract meaning from RPC errors, optionally includes all the network data that caused the error for easier retrieval, and a fallback human readbale `description` to ensure something useful is always shown to the user.
 */
public struct KukaiError: CustomStringConvertible, Error {
	
	/// Categories of errors that are possible
	public enum ErrorType: Equatable {
		
		/// RPC errors come directly from the Tezos RPC, but with the massive JSON object filtered down to the most meraningful part
		case rpc
		
		/// System errors are ones coming from the OS, e.g. "No internet connection"
		case system
		
		/// Network errors are returned by a server, such as HTTP 404's and 500's
		case network(Int)
		
		/// Internal application errors are errors from other services, components, libraiers etc, wrapped up so that they don't require extra parsing
		case internalApplication
		
		/// For situations where the wrong model is returned. This can happen sometimes unexpectedily in GraphQL based APIs, instead of returning an error, it will just return a partial object missing non-optional fields
		case decodingError
		
		/// For clients to catch known errors, sometimes handled in odd ways, enabling the easy return of a String. E.g. GraphQL throwing a malformed object response for a situation that should be a 404
		case knownError
		
		/// Used as a fallback for strange edge cases where we can't easily idenitfiy the issue
		case unknown
	}
	
	/// The error category
	public let errorType: ErrorType
	
	public let knownErrorMessage: String?
	
	/// Optional error subType coming from another source (the OS, URLSession, another library etc)
	public let subType: Error?
	
	/// Optional string containing only the relvant portion of an RPC error (e.g instead of "proto.xxxxxxxx.gas\_exhausted.operation",  it would contain "gas\_exhausted.operation") to make parsing easier
	public let rpcErrorString: String?
	
	/// Optional object containing smart contract failure casues. May contain an Int (error code), a String (semi human readbale error message), and/or a dictionary containing metadata
	public let failWith: FailWith?
	
	/// The requested URL that returned the error
	public var requestURL: URL?
	
	/// The JSON that was sent as part of the request
	public var requestJSON: String?
	
	/// The raw JSON that was returned
	public var responseJSON: String?
	
	/// The HTTP status code returned
	public var httpStatusCode: Int?
	
	
	
	// MARK: - Constructors
	
	/// Create a KukaiError from an RPC string (will not be validated). You can use the string extension `.removeLeadingProtocolFromRPCError()` to strip the leading poriton of the error
	public static func rpcError(rpcErrorString: String, andFailWith: FailWith?, requestURL: URL?) -> KukaiError {
		return KukaiError(errorType: .rpc, knownErrorMessage: nil, subType: nil, rpcErrorString: rpcErrorString, failWith: andFailWith, requestURL: requestURL, requestJSON: nil, responseJSON: nil, httpStatusCode: nil)
	}
	
	/// Create a KukaiError denoting a sytem issue from the OS, by passing in the system Error type
	public static func systemError(subType: Error) -> KukaiError {
		return KukaiError(errorType: .system, knownErrorMessage: nil, subType: subType, rpcErrorString: nil, failWith: nil, requestURL: nil, requestJSON: nil, responseJSON: nil, httpStatusCode: nil)
	}
	
	/// Create a KukaiError denoting a network issue, by passing in the HTTP status code
	public static func networkError(statusCode: Int, requestURL: URL) -> KukaiError {
		return KukaiError(errorType: .network(statusCode), knownErrorMessage: nil, subType: nil, rpcErrorString: nil, failWith: nil, requestURL: requestURL, requestJSON: nil, responseJSON: nil, httpStatusCode: nil)
	}
	
	/// Create a KukaiError denoting an issue from some other component or library, by passing in the error that piece of code returned
	public static func internalApplicationError(error: Error) -> KukaiError {
		return KukaiError(errorType: .internalApplication, knownErrorMessage: nil, subType: error, rpcErrorString: nil, failWith: nil, requestURL: nil, requestJSON: nil, responseJSON: nil, httpStatusCode: nil)
	}
	
	/// Create a KukaiError denoting an issue from some other component or library, by passing in the error that piece of code returned
	public static func decodingError(error: Error) -> KukaiError {
		return KukaiError(errorType: .decodingError, knownErrorMessage: nil, subType: error, rpcErrorString: nil, failWith: nil, requestURL: nil, requestJSON: nil, responseJSON: nil, httpStatusCode: nil)
	}
	
	/// Create a KukaiError allowing a client to simply provide the required error message.
	/// E.g. In situations where GraphQL returns a malformed object instead of an error, resulting in a decodingError, a client can catch that, supress it, and instead reutrn an error explaining that this record couldn't be found
	public static func knownErrorMessage(_ message: String) -> KukaiError {
		return KukaiError(errorType: .knownError, knownErrorMessage: message, subType: nil, rpcErrorString: nil, failWith: nil, requestURL: nil, requestJSON: nil, responseJSON: nil, httpStatusCode: nil)
	}
	
	/// Create an unknown KukaiError
	public static func unknown(withString: String? = nil) -> KukaiError {
		return KukaiError(errorType: .unknown, knownErrorMessage: nil, subType: nil, rpcErrorString: withString, failWith: nil, requestURL: nil, requestJSON: nil, responseJSON: nil, httpStatusCode: nil)
	}
	
	public static func missingBaseURL() -> KukaiError {
		return KukaiError(errorType: .system, knownErrorMessage: nil, subType: TezosNodeClientConfig.ConfigError.missingBaseURL, rpcErrorString: nil, failWith: nil)
	}
	
	
	
	// MARK: - Modifiers
	
	/// For network errors, attach all the necessary network data that may be needed in order to debug the issue, or log to a tool such as sentry
	public mutating func addNetworkData(requestURL: URL?, requestJSON: Data?, responseJSON: Data?, httpStatusCode: Int?) {
		self.requestURL = requestURL
		self.requestJSON = String(data: requestJSON ?? Data(), encoding: .utf8)
		self.responseJSON = String(data: responseJSON ?? Data(), encoding: .utf8)
		self.httpStatusCode = httpStatusCode
	}
	
	
	
	// MARK: - Helpers
	
	public func isMissingBaseURLError() -> Bool {
		if self.errorType == .system, let subType = self.subType, TezosNodeClientConfig.ConfigError.missingBaseURL.isEqualTo(other: subType) {
			return true
		}
		
		return false
	}
	
	
	
	// MARK: - Display
	
	/// Prints the underlying error type with either an RPC string, or an underlying Error object contents
	public var description: String {
		get {
			switch errorType {
				case .rpc:
					if let rpcErrorString = rpcErrorString {
						return rpcErrorString
					}
					return "RPC: Unknown"
					
				case .system:
					if let subType = subType {
						if let errString = checkErrorForKnownCase(subType) {
							return errString
						} else {
							return "System: \(subType.localizedDescription)"
						}
					}
					return "System: Unknown"
					
				case .network(let statusCode):
					guard let url = self.requestURL else {
						return "HTTP Status \(statusCode) \nUnknown error occured"
					}
					
					return messageForNetworkStatusCode(statusCode: statusCode, url: url)
					
				case .internalApplication:
					if let subType = subType {
						return "Internal Application Error: \(subType)"
					}
					return "Internal Application Error: Unknown"
				
				case .decodingError:
					return "Decoding error: The service returned an unexpected response, please check any information you've supplied is correct"
					
				case .knownError:
					return knownErrorMessage ?? "Unknown"
					
				case .unknown:
					if let rpcErrorString = rpcErrorString {
						return "Unknown: \(rpcErrorString)"
					}
					return "Unknown"
			}
		}
	}
	
	public func checkErrorForKnownCase(_ err: Error) -> String? {
		if err.domain == "NSURLErrorDomain" {
			if err.code == -1001 {
				return "The request timed out. Please check your connection and try again"
				
			} else if err.code == -1009 {
				return "Your device is unable to access the internet. Please check your connection and try again"
			}
			
			return nil
		}
		
		return nil
	}
	
	public func messageForNetworkStatusCode(statusCode: Int, url: URL) -> String {
		if statusCode == 403 {
			return "HTTP Status \(statusCode) \nYour device/network is unable to communicate with: \(url.absoluteStringByTrimmingQuery() ?? url.absoluteString)"
			
		} else if statusCode >= 400 && statusCode <= 499 {
			return "HTTP Status \(statusCode) \nYour device/network is unable to communicate with: \(url.absoluteStringByTrimmingQuery() ?? url.absoluteString)"
			
		} else if statusCode >= 500 {
			return "HTTP Status \(statusCode) \nThe server at the following URL is having trouble processing this request: \(url.absoluteStringByTrimmingQuery() ?? url.absoluteString)"
			
		} else {
			return "HTTP Status \(statusCode) \nUnable to communicate with: \(url.absoluteStringByTrimmingQuery() ?? url.absoluteString)"
		}
	}
	
	
	
	// MARK: - Central callback parsers
	
	/**
	 Allow the delegate of the error callback the ability to decide what errors to log or not by detecting the high level type of error being generated
	*/
	public func isTimeout() -> Bool {
		return (self.subType?.domain == "NSURLErrorDomain" && self.subType?.code == -1001) ||
				(self.underlyingError?.domain == "NSURLErrorDomain" && self.underlyingError?.code == -1001)
	}
}



// MARK: - Service class

/// A class used to process errors into more readable format, and optionally notifiy a global error handler of every error occuring
public class ErrorHandlingService {
	
	
	// MARK: - Properties
	
	/// Shared instance so that it can hold onto an event closure
	public static let shared = ErrorHandlingService()
	
	/// Called everytime an error is parsed. Extremely useful to track / log errors globally, in order to run logic or record to external service
	public var errorEventClosure: ((KukaiError) -> Void)? = nil
	
	private init() {}
	
	
	
	// MARK: - Error parsers
	
	/// Convert an `OperationResponseInternalResultError` into a `KukaiError` and optionally log it to the central logger
	public static func fromOperationError(_ opError: OperationResponseInternalResultError, requestURL: URL?, andLog: Bool = true) -> KukaiError {
		let errorWithoutProtocol = opError.id.removeLeadingProtocolFromRPCError()
		var errorToReturn = KukaiError(errorType: .rpc, knownErrorMessage: nil, subType: nil, rpcErrorString: "RPC error code: \(errorWithoutProtocol ?? "Unknown")", failWith: nil, requestURL: nil, requestJSON: nil, responseJSON: nil, httpStatusCode: nil)
		
		
		if let result = knownRPCErrorString(rpcStringWithoutLeadingProtocol: errorWithoutProtocol, with: opError.with) {
			errorToReturn = KukaiError.rpcError(rpcErrorString: result, andFailWith: opError.with, requestURL: requestURL)
			
		} else if (errorWithoutProtocol == "michelson_v1.runtime_error" || errorWithoutProtocol == "michelson_v1.script_rejected"), let withError = opError.with  {
			
			if let failwith = withError.int, let failwithInt = Int(failwith) {
				// Smart contract failwith reached with an Int denoting an error code
				// Liquidity baking error codes, need to consider how to incorporate: https://gitlab.com/dexter2tz/dexter2tz/-/blob/liquidity_baking/dexter.liquidity_baking.mligo#L85
				errorToReturn = KukaiError.rpcError(rpcErrorString: "A FAILWITH instruction was reached: {\"int\": \(failwithInt)}", andFailWith: opError.with, requestURL: requestURL)
				
			} else if let failwith = withError.string {
				// Smart contract failwith reached with an String error message
				errorToReturn = KukaiError.rpcError(rpcErrorString: "A FAILWITH instruction was reached: {\"string\": \(failwith)}", andFailWith: opError.with, requestURL: requestURL)
				
			} else if let args = withError.args {
				// Smart Contract failwith reached with a dictionary
				errorToReturn = KukaiError.rpcError(rpcErrorString: "A FAILWITH instruction was reached: {\"args\": \(args)}", andFailWith: opError.with, requestURL: requestURL)
				
			} else {
				// Unknown smart contract error
				errorToReturn = KukaiError.rpcError(rpcErrorString: "michelson_v1.runtime_error", andFailWith: opError.with, requestURL: requestURL)
			}
		}
		
		if andLog { logAndCallback(withKukaiError: errorToReturn) }
		return errorToReturn
	}
	
	public static func knownRPCErrorString(rpcStringWithoutLeadingProtocol: String?, with: FailWith?) -> String? {
		guard let rpcStringWithoutLeadingProtocol = rpcStringWithoutLeadingProtocol else { return nil }
		
		switch rpcStringWithoutLeadingProtocol {
			
			// top level protocol errors
			case "implicit.empty_implicit_contract":
				return "Your account has a 0 XTZ balance and is unable to pay for the fees to complete the transaction."
			
			case "tez.subtraction_underflow":
				return "Your account does not have enough XTZ to complete the transaction."
				
			
			// known michelson contract related errors (e.g. insufficent balance for a known token standard)
			// can appear in 2 places
			case "michelson_v1.script_rejected":
				if let string = with?.string {
					return compareInnerString(string)
					
				} else if let string = with?.args?.first?["string"] {
					return compareInnerString(string)
					
				} else {
					return nil
				}
				
			default:
				return nil
		}
	}
	
	private static func compareInnerString(_ remoteString: String?) -> String? {
		switch remoteString?.lowercased() {
			case "fa2_insufficient_balance":
				return "Insufficient NFT/DeFi token balance to complete the transaction"
				
			case "fa1.2_insufficientbalance":
				return "Insufficient DeFi token balance to complete the transaction"
				
			case "notenoughbalance":
				return "Insufficient token balance to complete the transaction"
				
			case .none:
				return nil
				
			case .some(_):
				return nil
		}
	}
	
	/// Search an `OperationResponse` to see does it contain any errors, if so return the last one as a `KukaiError` and optionally log it to the central logger
	public static func searchOperationResponseForErrors(_ opResponse: OperationResponse, requestURL: URL?, andLog: Bool = true) -> KukaiError? {
		if let lastError = opResponse.errors().last {
			let errorToReturn = ErrorHandlingService.fromOperationError(lastError, requestURL: requestURL)
			
			if andLog { logAndCallback(withKukaiError: errorToReturn) }
			return errorToReturn
		}
		
		return nil
	}
	
	/// Search an `[OperationResponse]` to see does it contain any errors, if so return the last one as a`KukaiError` and optionally log it to the central logger
	public static func searchOperationResponseForErrors(_ opResponse: [OperationResponse], requestURL: URL?, andLog: Bool = true) -> KukaiError? {
		if let lastError = opResponse.flatMap({ $0.errors() }).last {
			let errorToReturn = ErrorHandlingService.fromOperationError(lastError, requestURL: requestURL)
			
			if andLog { logAndCallback(withKukaiError: errorToReturn) }
			return errorToReturn
		}
		
		return nil
	}
	
	/// Take in network response data and see does it contain an error, if so return create a`KukaiError`from it and optionally log it to the central logger
	public static func searchForSystemError(data: Data?, response: URLResponse?, networkError: Error?, requestURL: URL, requestData: Data?, andLog: Bool = true) -> KukaiError? {
		
		// Check if we got an error object (e.g. no internet connection)
		if let networkError = networkError {
			var errorToReturn = KukaiError.systemError(subType: networkError)
			errorToReturn.addNetworkData(requestURL: requestURL, requestJSON: requestData, responseJSON: data, httpStatusCode: (response as? HTTPURLResponse)?.statusCode)
			
			if andLog { logAndCallback(withKukaiError: errorToReturn) }
			return errorToReturn
		}
		// Check if we didn't get an error object, but instead got a non http 200 (e.g. 404)
		else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
			
			// HTTP 500's can also be sent by the RPC for specific RPC errors, such as counter in the future. So first check if we can parse the response to an RPC error
			// If not, then return a generic HTTP != 200 error
			var errorToReturn = KukaiError.networkError(statusCode: httpResponse.statusCode, requestURL: requestURL)
			if let d = data,
				let errorArray = try? JSONDecoder().decode([OperationResponseInternalResultError].self, from: d),
				let lastError = errorArray.last,
				let errorString = lastError.id.removeLeadingProtocolFromRPCError()
			{
				let updatedString = knownRPCErrorString(rpcStringWithoutLeadingProtocol: errorString, with: lastError.with)
				errorToReturn = KukaiError.rpcError(rpcErrorString: updatedString ?? "RPC error code: \(errorString)", andFailWith: lastError.with, requestURL: requestURL)
			} else {
				errorToReturn.addNetworkData(requestURL: requestURL, requestJSON: requestData, responseJSON: data, httpStatusCode: httpResponse.statusCode)
			}
			
			if andLog { logAndCallback(withKukaiError: errorToReturn) }
			return errorToReturn
		}
		
		return nil
	}
	
	
	
	// MARK: - Logging
	
	private class func logAndCallback(withKukaiError kukaiError: KukaiError) {
		Logger.kukaiCoreSwift.error("\(kukaiError.description)")
		
		if let closure = ErrorHandlingService.shared.errorEventClosure {
			closure(kukaiError)
		}
	}
}
