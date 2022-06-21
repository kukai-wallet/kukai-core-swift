//
//  FailWithParser.swift
//  
//
//  Created by Simon Mcloughlin on 21/06/2022.
//

import Foundation

/// Protocol to allow defining multiple dedicated structs, one for each dApp, that knows how to convert the specific failWith cases into more human readable error messages
public protocol FailWithParser {
	
	/// Take in a failWith and return a message
	func parse(failWith: FailWith?) -> String?
}
