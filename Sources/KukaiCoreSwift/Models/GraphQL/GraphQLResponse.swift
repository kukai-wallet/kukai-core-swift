//
//  GraphQLResponse.swift
//  
//
//  Created by Simon Mcloughlin on 15/10/2021.
//

import Foundation

/// GraphQL error object
public struct GraphQLError: Codable {
	
	/// Message sent from the server explaining the issue
	public let message: String
	
	/// Identifying the location fo the issue. E.g. codefile and line, or location of unexpected character/symbol in request string
	public let locations: [String: String]?
	
	/// Not sure, but it shows up sometimes
	public let extenstions: [String: String]?
}

/// Simple model object to wrap a GraphQL response to expose a Codable response without having to use large GraphQL libraries
public struct GraphQLResponse<T: Codable>: Codable {
	
	/// Array of errors returned from the server
	public let errors: [GraphQLError]?
	
	/// Generic data type matching the user supplied type
	public let data: T?
	
	/// Helper to check if the response contains errors
	func containsErrors() -> Bool {
		return errors != nil
	}
}
