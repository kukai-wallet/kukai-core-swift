//
//  TzKTAddress.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

/// Details about a given contract
public struct TzKTAddress: Codable {
	
	/// Contract addresses may have an alias (human readbale) name, to denote a person or service
	public let alias: String?
	
	/// The KT1 address of the contract
	public let address: String
}
