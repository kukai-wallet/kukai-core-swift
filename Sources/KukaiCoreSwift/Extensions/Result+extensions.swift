//
//  Result+extensions.swift
//  
//
//  Created by Simon Mcloughlin on 24/08/2021.
//

import Foundation

public enum ResultExtensionError: Error {
	case noErrorFound
}

public extension Result {
	
	/// Similar to `Result.get()`, getError returns the failure case or throws
	func getError() throws -> Failure {
		switch self {
			case .success(_):
				throw ResultExtensionError.noErrorFound
			
			case .failure(let error):
				return error
		}
	}
}

public extension Result where Failure == ErrorResponse {
	
	/// Similar to `Result.get()`, getFailure returns the kukai-core-specific `ErrorResponse` case or throws
	func getFailure() -> Failure {
		switch self {
			case .success(_):
				return ErrorResponse.unknownError()
			
			case .failure(let error):
				return error
		}
	}
}
