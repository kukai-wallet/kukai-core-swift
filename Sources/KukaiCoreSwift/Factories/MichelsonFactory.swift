//
//  MichelsonFactory.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 18/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation


/// A temporary factory class (until a better solution can be found) with some helper methods for parsing / Creating Michelson objects.
/// Also includes quicker functions to just extract values from raw JSON, useful for processing transaction history without having to implement the entire Michelson spec
public class MichelsonFactory {
	
	// MARK: - Type checkers
	
	/// Take in undecoded JSON and reutrn true if it matches a Michelson Pair type
	public static func isPair(_ obj: [String: Any]) -> Bool {
		return (obj[MichelsonConstant.prim.rawValue] as? String) == MichelsonConstant.pair.rawValue
	}
	
	/// Take in undecoded JSON and reutrn true if it matches a Michelson Int type
	public static func isInt(_ obj: [String: Any]) -> Bool {
		return (obj[MichelsonConstant.int.rawValue] as? String) != nil
	}
	
	/// Take in undecoded JSON and reutrn true if it matches a Michelson String type
	public static func isString(_ obj: [String: Any]) -> Bool {
		return (obj[MichelsonConstant.string.rawValue] as? String) != nil
	}
	
	
	
	// MARK: - Extractors
	
	/// Take in undecoded JSON, check its a valid Pair type, and return the left side of the pair
	public static func left(_ obj: [String: Any]?) -> [String: Any]? {
		guard let obj = obj, isPair(obj) else {
			return nil
		}
		
		if let args = obj[MichelsonConstant.args.rawValue] as? [[String: Any]], args.count > 0 {
			return args[0]
		}
		
		return nil
	}
	
	/// Take in undecoded JSON, check its a valid Pair type, and return the right side of the pair
	public static func right(_ obj: [String: Any]?) -> [String: Any]? {
		guard let obj = obj, isPair(obj) else {
			return nil
		}
		
		if let args = obj[MichelsonConstant.args.rawValue] as? [[String: Any]], args.count > 1 {
			return args[1]
		}
		
		return nil
	}
	
	/// Take in undecoded JSON, check its a valid Int type, and return the underlying value as a Decimal
	public static func int(_ obj: [String: Any]?) -> Decimal? {
		guard let obj = obj, isInt(obj) else {
			return nil
		}
		
		if let intString = obj[MichelsonConstant.int.rawValue] as? String, let decimal = Decimal(string: intString) {
			return decimal
		}
		
		return nil
	}
	
	/// Take in undecoded JSON, check its a valid String type, and return the underlying value
	public static func string(_ obj: [String: Any]?) -> String? {
		guard let obj = obj, isString(obj) else {
			return nil
		}
		
		return obj[MichelsonConstant.string.rawValue] as? String
	}
	
	
	
	// MARK: - Builders
	
	/// Helper to create a Michelson compliant object, containing an `Int` value. Passing in a `TokenAmount`, it will be converted to the appropriate RPC format
	/// The returned object can be passed into a `MichelsonPair` object, in order to send as part of a smart contract call
	public static func createInt(_ value: TokenAmount) -> MichelsonValue {
		return MichelsonValue(key: MichelsonConstant.int, value: value.rpcRepresentation)
	}
	
	/// Helper to create a Michelson compliant object, containing an `String` value.
	/// The returned object can be passed into a `MichelsonPair` object, in order to send as part of a smart contract call
	public static func createString(_ value: String) -> MichelsonValue {
		return MichelsonValue(key: MichelsonConstant.string, value: value)
	}
}
