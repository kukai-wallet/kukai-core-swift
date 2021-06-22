//
//  ErrorHandlingService.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 27/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import os.log

// MARK: - Types

public enum ErrorResponseType: String, Codable {
	case unknownError
	case unknownWallet
	case unknownBalance
	case unknownParseError
	case internalApplicationError
	
	case noInternetConnection
	case requestTimeOut
	case tooManyRedirects
	case atsUnsecureConnection
	
	case exchangeDataOutOfSync
	case exchangeHigherThanZero
	case insufficientFunds
	case insufficientFundsDelegation
	case delegationUnchanged
	case emptyTransaction
	case invalidAddress
	case bakerCantDelegate
	case invalidBaker
	case exchangeTimeout
	case exchangeNotEnoughFa
	case exchangeNotEnoughTez
	
	case tokenToTokenUnavailable
	case counterError
	case dexterNotEnoughFA
	case dexterNotEnoughTez
}

public struct ErrorResponse: CustomStringConvertible, Error {
	public var requestURL: URL?
	public var requestJSON: String?
	public var responseJSON: String?
	public var httpStatusCode: Int?
	public var errorObject: Error?
	public var errorString: String?
	
	public var errorType: ErrorResponseType
	
	public var description: String {
		get {
			if let requestURL = requestURL {
				return "ErrorResponse - Network: Type: \(errorType), StatusCode: \(httpStatusCode ?? -1), \nURL: \(requestURL), \nRequest: \(requestJSON ?? ""), \nResponse: \(responseJSON ?? ""), \nErrorObject: \(ErrorResponse.errorToString(errorObject))"
			} else {
				return "ErrorResponse - Application: Type: \(errorType), ErrorString: \(errorString ?? "")"
			}
		}
	}
	
	public init(requestURL: URL?, requestJSON: String?, responseJSON: String?, httpStatusCode: Int?, errorObject: Error?, errorString: String?, errorType: ErrorResponseType) {
		self.requestURL = requestURL
		self.requestJSON = requestJSON
		self.responseJSON = responseJSON
		self.httpStatusCode = httpStatusCode
		self.errorObject = errorObject
		self.errorString = errorString
		self.errorType = errorType
	}
	
	public static func error(string: String, errorType: ErrorResponseType) -> ErrorResponse {
		return ErrorResponse(requestURL: nil, requestJSON: nil, responseJSON: nil, httpStatusCode: nil, errorObject: nil, errorString: string, errorType: errorType)
	}
	
	public static func internalApplicationError(error: Error) -> ErrorResponse {
		return ErrorResponse(requestURL: nil, requestJSON: nil, responseJSON: nil, httpStatusCode: nil, errorObject: error, errorString: errorToString(error), errorType: .internalApplicationError)
	}
	
	public static func unknownParseError(error: Error) -> ErrorResponse {
		return ErrorResponse(requestURL: nil, requestJSON: nil, responseJSON: nil, httpStatusCode: nil, errorObject: nil, errorString: errorToString(error), errorType: .unknownParseError)
	}
	
	public static func unknownError() -> ErrorResponse {
		return ErrorResponse(requestURL: nil, requestJSON: nil, responseJSON: nil, httpStatusCode: nil, errorObject: nil, errorString: nil, errorType: .unknownError)
	}
	
	public static func errorToString(_ error: Error?) -> String {
		guard let err = error else {
			return ""
		}
		
		if #available(iOS 13.0, *) {
			return "\(err)"
		} else {
			return "\(err.localizedDescription): \(err.userInfo)"
		}
	}
}



// MARK: - Service class

public class ErrorHandlingService {
	
	
	// MARK: - Properties
	
	public static let shared = ErrorHandlingService()
	public var errorEventClosure: ((ErrorResponse) -> Void)? = nil
	
	private init() {}
	
	
	
	// MARK: - Error parsers
	
	public class func parse(string: String, andLog: Bool = true) -> ErrorResponse {
		var errorResponse: ErrorResponse = ErrorResponse.unknownError()
		
		// General errors
		if string.contains("balance_too_low") {
			errorResponse = ErrorResponse.error(string: string, errorType: .insufficientFunds)
			
		} else if (string.contains("Counter") && string.contains("already used for contract")) || string.contains("counter_in_the_past") {
			errorResponse = ErrorResponse.error(string: string, errorType: .counterError)
			
		} else if string.contains("The Internet connection appears to be offline.") || string.contains("A data connection is not currently allowed.") {
			errorResponse = ErrorResponse.error(string: string, errorType: .noInternetConnection)
			
		} else if string.contains("The request timed out.") {
			errorResponse = ErrorResponse.error(string: string, errorType: .requestTimeOut)
			
		} else if string.contains("too many HTTP redirects") {
			errorResponse = ErrorResponse.error(string: string, errorType: .tooManyRedirects)
			
		} else if string.contains("App Transport Security policy requires the use of a secure connection") {
			errorResponse = ErrorResponse.error(string: string, errorType: .atsUnsecureConnection)
			
		} else if string.contains("gas_exhausted") || string.contains("storage_exhausted") {
			errorResponse = ErrorResponse.error(string: string, errorType: .unknownError)
			
		} else if string.contains("implicit.empty_implicit_contract") 	// No XTZ
					|| string.contains("\"NotEnoughBalance\"") { 		// No FA1.2 for Dexter swap
			
			errorResponse = ErrorResponse.error(string: string, errorType: .insufficientFunds)
			
		} else if string.contains("storage_limit_too_high") {
			errorResponse = ErrorResponse.error(string: string, errorType: .unknownError)
			
		} else if string.contains("NOW is greater than deadline") {
			errorResponse = ErrorResponse.error(string: string, errorType: .exchangeTimeout)
			
		} else if string.contains("storage_error") {
			// Belive this to be an issue caused when the account doesn't have enough balance left to pay the burn fee needed to update the contract storage
			errorResponse = ErrorResponse.error(string: string, errorType: .insufficientFunds)
			
		}  else if string.contains("delegate.unchanged") {
			errorResponse = ErrorResponse.error(string: string, errorType: .delegationUnchanged)
			
		} else if string.contains("empty_transaction") {
			errorResponse = ErrorResponse.error(string: string, errorType: .emptyTransaction)
			
		} else if string.contains("delegate.no_deletion") {
			errorResponse = ErrorResponse.error(string: string, errorType: .bakerCantDelegate)
			
		} else if string.contains("contract.manager.unregistered_delegate") {
			errorResponse = ErrorResponse.error(string: string, errorType: .invalidBaker)
			
		} else if string.contains("Unhandled error (Failure \"Invalid contract notation.\")") {
			errorResponse = ErrorResponse.error(string: string, errorType: .invalidAddress)
			
		} else if string.contains("Failed to parse the request body: No case matched:") {
			errorResponse = ErrorResponse.error(string: string, errorType: .invalidAddress)
		}
		
		// Dexter errors
		else if string.contains("tokensBought is less than minTokensBought")
					|| string.contains("xtzBought is less than minXtzBought") {
			
			errorResponse = ErrorResponse.error(string: string, errorType: .exchangeDataOutOfSync)
			
		} else if string.contains("minTokensBought must be greater than zero")
					|| string.contains("minXtzBought must be greater than zero")
					|| string.contains("Amount must be greater than zero") {
			
			errorResponse = ErrorResponse.error(string: string, errorType: .exchangeHigherThanZero)
			
		} else if string.contains("NOW is greater than deadline") {
			errorResponse = ErrorResponse.error(string: string, errorType: .exchangeTimeout)
			
		} else if string.contains("xtzPool must be greater than zero") {
			errorResponse = ErrorResponse.error(string: string, errorType: .exchangeNotEnoughTez)
			
		} else if string.contains("tokenPool must be greater than zero") {
			errorResponse = ErrorResponse.error(string: string, errorType: .exchangeNotEnoughFa)
			
		} else if string.contains("Amount must be zero") {
			errorResponse = ErrorResponse.error(string: string, errorType: .unknownError)
			
		} else if string.contains("tokensSold is zero") {
			errorResponse = ErrorResponse.error(string: string, errorType: .unknownError)
		}
		
		if andLog { logAndCallback(withErrorResponse: errorResponse) }
		return errorResponse
	}
	
	public class func parse(data: Data?, response: URLResponse?, networkError: Error?, requestURL: URL, requestData: Data?) -> ErrorResponse? {
		var errorResponse: ErrorResponse? = nil
		
		// Some RPC errors don't come in JSON format.
		// For example its possible that a Http 400 might include a string stack trace indicating that the destination address is invalid.
		// Attempt to parse the body as a string and process
		
		if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
			if let d = data {
				errorResponse = parse(string: String(data: d, encoding: .utf8) ?? "", andLog: false)
				
			} else if let err = networkError {
				errorResponse = parse(string: ErrorResponse.errorToString(err), andLog: false)
			}
			
			errorResponse?.requestURL = requestURL
			errorResponse?.requestJSON = String(data: requestData ?? Data(), encoding: .utf8)
			errorResponse?.responseJSON = String(data: data ?? Data(), encoding: .utf8) ?? ""
			errorResponse?.httpStatusCode = httpResponse.statusCode
			errorResponse?.errorObject = networkError
			
		} else if let err = networkError {
			
			let requestJson = String(data: requestData ?? Data(), encoding: .utf8)
			let responseJson = String(data: data ?? Data(), encoding: .utf8)
			let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
			
			errorResponse = parse(string: ErrorResponse.errorToString(err), andLog: false)
			errorResponse?.requestURL = requestURL
			errorResponse?.requestJSON = requestJson
			errorResponse?.responseJSON = responseJson
			errorResponse?.httpStatusCode = statusCode
			errorResponse?.errorString = ErrorResponse.errorToString(err)
			errorResponse?.errorObject = err
		}
		
		// If we have any kind of error at this point, add in the network details
		if let errorRes = errorResponse {
			logAndCallback(withErrorResponse: errorRes)
		}
		
		return errorResponse
	}
	
	
	
	// MARK: - Error Extractors
	
	public class func containsErrors(tzktOperations: [TzKTOperation]) -> Bool {
		for op in tzktOperations {
			if op.containsError() {
				return true
			}
		}
		
		return false
	}
	
	/**
	There are 2 types of high level errors in Tezos.
	1. Account state errors: These errors are global across the entire ecosystem, and will effect any application, or product. Examples: insufficent balance, invalid address, invalid baker.
	2. Script errors: These errors are specific to each application. Examples: Dexter-invalid requested exchange operation, TNS-the requested domain name is unavailable.
	When working with smart contracts on Tezos, operations may have internal child operations, each of which can have an error. When an error of type 2 mentioned above occurs,
	the array of operations will contain many generic "a unknown script error occured" messages, with one of the operations containing the detailed, application specific error. This function is an
	attempt to abstract this logic away from developers, by simply taking in an array of operations, and returning the most meaningful error it can, to reduce time and effort.
	- Returns: `nil` if no errors found, useful for checking status, `.unknownError` if no meaningful errors can be found, or some `ErrorResponseType` matching the meaningful error
	*/
	public class func extractMeaningfulErrors(fromTzKTOperations operations: [TzKTOperation]) -> ErrorResponse? {
		
		// If operations contain no errors, return empty array
		guard operations.map({ $0.containsError() }).filter({ $0 == true }).count > 0 else {
			return nil
		}
		
		// Else, try to parse basic errors for something meaningful
		let errorArrays = operations.map({ $0.errors })
		var parsedErrors: [ErrorResponse] = []
		
		errorArrays.forEach { (array) in
			array?.forEach({ (error) in
				parsedErrors.append( ErrorHandlingService.parse(string: error.type, andLog: false) )
			})
		}
		
		let meaningfulErrors = parsedErrors.filter({ $0.errorType != .unknownError })
		
		// Only log the last error
		if meaningfulErrors.count != 0, let returningError = meaningfulErrors.last {
			logAndCallback(withErrorResponse: returningError)
			return returningError
		}
		
		return ErrorResponse.unknownError()
	}
	
	/**
	There are 2 types of high level errors in Tezos.
	1. Account state errors: These errors are global across the entire ecosystem, and will effect any application, or product. Examples: insufficent balance, invalid address, invalid baker.
	2. Script errors: These errors are specific to each application. Examples: Dexter-invalid requested exchange operation, TNS-the requested domain name is unavailable.
	When working with smart contracts on Tezos, operations may have internal child operations, each of which can have an error. When an error of type 2 mentioned above occurs,
	the array of operations will contain many generic "a unknown script error occured" messages, with one of the operations containing the detailed, application specific error. This function is an
	attempt to abstract this logic away from developers, by simply taking in an array of operations, and returning the most meaningful error it can, to reduce time and effort.
	- Returns: `nil` if no errors found, useful for checking status, `.unknownError` if no meaningful errors can be found, or some `ErrorResponseType` matching the meaningful error
	*/
	public class func extractMeaningfulErrors(fromRPCOperations operations: [OperationResponse], withRequestURL: URL?, requestPayload: Data?, responsePayload: Data?, httpStatusCode: Int?) -> ErrorResponse? {
		
		// If operations contain no errors, return empty array
		guard operations.map({ $0.errors().count > 0 }).filter({ $0 == true }).count > 0 else {
			return nil
		}
		
		// Else, try to parse basic errors for something meaningful
		let errorArrays = operations.map({ $0.errors() })
		var parsedErrors: [ErrorResponse] = []
		
		
		errorArrays.forEach { (array) in
			array.forEach({ (error) in
				
				// Error we are looking for could be inside the returned `.id` or optionally inside `.with.string`.
				// Since we are just just check for string contents, add both together and search the full string
				let fullErrorString = error.id + " " + (error.with?.string ?? "")
				parsedErrors.append( ErrorHandlingService.parse(string: fullErrorString, andLog: false) )
			})
		}
		
		let meaningfulErrors = parsedErrors.filter({ $0.errorType != .unknownError })
		
		// Only log the last error
		if meaningfulErrors.count != 0 {
			var returningError = meaningfulErrors.last
			returningError?.requestURL = withRequestURL
			returningError?.requestJSON = String(data: requestPayload ?? Data(), encoding: .utf8)
			returningError?.responseJSON = String(data: responsePayload ?? Data(), encoding: .utf8)
			returningError?.httpStatusCode = httpStatusCode
			
			logAndCallback(withErrorResponse: returningError ?? ErrorResponse.unknownError())
			return returningError
		}
		
		return ErrorResponse.unknownError()
	}
	
	
	
	// MARK: - Logging
	
	private class func logAndCallback(withErrorResponse errorResponse: ErrorResponse) {
		os_log(.error, log: .kukaiCoreSwift, "Error parsed: %@", errorResponse.description)
		
		if let closure = ErrorHandlingService.shared.errorEventClosure {
			closure(errorResponse)
		}
	}
}

