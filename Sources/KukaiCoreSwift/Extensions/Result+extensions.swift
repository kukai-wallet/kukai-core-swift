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
	
	func getFailure() -> Failure {
		switch self {
			case .success(_):
				return ErrorResponse.unknownError()
			
			case .failure(let error):
				return error
		}
	}
}
