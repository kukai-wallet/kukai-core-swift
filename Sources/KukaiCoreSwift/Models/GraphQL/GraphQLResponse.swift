//
//  GraphQLResponse.swift
//  
//
//  Created by Simon Mcloughlin on 15/10/2021.
//

import Foundation

public struct GraphQLError: Codable {
	public let message: String
	public let locations: [String: String]?
	public let extenstions: [String: String]?
}

public struct GraphQLResponse<T: Codable>: Codable {
	
	public let errors: [GraphQLError]?
	public let data: T?
	
	func containsErrors() -> Bool {
		return errors != nil
	}
}
