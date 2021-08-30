//
//  Michelson.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 25/11/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import os.log


/// Michelson constants used to denote types and values
public enum MichelsonConstant: String, CodingKey {
	case prim
	case args
	case bytes
	case int
	case string
	
	// prim values
	case pair = "Pair"
	case elt = "Elt"
	case `false` = "False"
	case `true` = "True"
}



/// Custom Errors that can be returned by the decode or encode functions
public enum MichelsonParseError: Error {
	case NoKeysMatchingConstantsFound
}



/// Base Michelson type, only used for polymorphism inside `MichelsonPair` objects
public class AbstractMichelson: Codable, Equatable, CustomStringConvertible {
	
	/// Customized `description` with default value showing the Michelson types have not been parsed
	public var description: String {
		get {
			return "AbstractMichelson"
		}
	}
	
	public static func == (lhs: AbstractMichelson, rhs: AbstractMichelson) -> Bool {
		return true
	}
	
	public static func decodeUnknownMichelson<T: RawRepresentable>(container: KeyedDecodingContainer<T>, forKey key: T) -> AbstractMichelson? where T.RawValue == String {
		var michelsonValue: AbstractMichelson? = nil
		
		if let value = try? container.decodeIfPresent(MichelsonPair.self, forKey: key) {
			michelsonValue = value
			
		} else if let value = try? container.decodeIfPresent(MichelsonValue.self, forKey: key) {
			michelsonValue = value
		}
		
		return michelsonValue
	}
}



/// A polymophic warpper around a key value pair, used in conjuction with `MichelsonPair` to leverage automatice JSON serialisation through `Codable`
public class MichelsonValue: AbstractMichelson {
	
	/// The key denoting the Michelson type
	public let key: MichelsonConstant
	
	/// A string containing the Michelson type's value
	public let value: String
	
	enum CodingKeys: String, CodingKey {
		case key
		case value
	}
	
	/// Customized `description` to allow object to be logged to console, how it is returned from the RPC
	public override var description: String {
		get {
			return "{\"\(key.rawValue)\": \"\(value)\"}"
		}
	}
	
	
	
	/// Init accepting a contant and a string to act as the key and value
	public init(key: MichelsonConstant, value: String) {
		self.key = key
		self.value = value
		
		super.init()
	}
	
	
	
	/// Adhearing to `Decodable`
	required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: MichelsonConstant.self)
		
		if let firstKey = container.allKeys.first {
			key = firstKey
			value = try container.decode(String.self, forKey: firstKey)
		} else {
			throw MichelsonParseError.NoKeysMatchingConstantsFound
		}
		
		try super.init(from: decoder)
	}
	
	/// Adhearing to `Encodable`
	public override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: MichelsonConstant.self)
		try container.encode(value, forKey: key)
		
		try super.encode(to: encoder)
	}
	
	/// Adhearing to `Equatable`
	public static func == (lhs: MichelsonValue, rhs: MichelsonValue) -> Bool {
		return lhs.key == rhs.key && lhs.value == rhs.value
	}
}



public class MichelsonPair: AbstractMichelson {
	
	/// The primitive type, in this case will always be `Pair`
	public let prim: String
	
	/// An array of key / value objects, MichelsonPair's or combination of both
	public let args: [AbstractMichelson]
	
	enum CodingKeys: String, CodingKey {
		case prim
		case args
	}
	
	/// Customized `description` to allow object to be logged to console, how it is returned from the RPC
	public override var description: String {
		get {
			var json = "{\"prim\": \"Pair\", \"args\": ["
			
			for (index, arg) in args.enumerated() {
				json.append("\(arg)")
				
				if index != args.count-1 {
					json.append(",")
				}
			}
			
			json.append("]}")
			
			return json
		}
	}
	
	
	
	// MARK: - Init
	
	/// Init accepting any combination of `MichelsonValue` or `MichelsonPair`
	public init(args: [AbstractMichelson]) {
		self.prim = MichelsonConstant.pair.rawValue
		self.args = args
		
		super.init()
	}
	
	/// Create a `MichelsonPair` from a `Dictionary` of type `[String: Any]`, if possible
	public class func create(fromDictionary dictionary: [String: Any]?) -> MichelsonPair? {
		guard let dict = dictionary else {
			os_log("couldn't create MichelsonPair, empty dictionary", log: .kukaiCoreSwift, type: .error)
			return nil
		}
		
		do {
			let data = try JSONSerialization.data(withJSONObject: dict, options: .fragmentsAllowed)
			return try JSONDecoder().decode(MichelsonPair.self, from: data)
			
		} catch (let error) {
			os_log("couldn't create MichelsonPair - Error: %@", log: .kukaiCoreSwift, type: .error, "\(error)")
			return nil
		}
	}
	
	
	
	// MARK: - Getters
	
	/// Michelson Pairs are no longer confined to 2 args (left and right). Fetch an underlying arg by its index
	public func argIndex(_ index: Int) -> AbstractMichelson? {
		if index < args.count {
			return args[index]
		}
		
		return nil
	}
	
	/// Michelson Pairs are no longer confined to 2 args (left and right). Fetch an underlying arg by its index and attempt to convert to a `MichelsonPair`
	public func argIndexAsPair(_ index: Int) -> MichelsonPair? {
		return argIndex(index) as? MichelsonPair
	}
	
	/// Michelson Pairs are no longer confined to 2 args (left and right). Fetch an underlying arg by its index and attempt to convert to a `MichelsonValue`
	public func argIndexAsValue(_ index: Int) -> MichelsonValue? {
		return argIndex(index) as? MichelsonValue
	}
	
	
	
	// MARK: - Protocols
	
	/// Adhearing to `Decodable`
	
	private struct DummyCodable: Codable {} // Workaround to skipping unknown michelson types in array, as there is no ".skip" or ".next"
	
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		prim = try container.decode(String.self, forKey: .prim)
		
		var arrayContainer = try container.nestedUnkeyedContainer(forKey: .args)
		var tempArgs: [AbstractMichelson] = []
		
		while !arrayContainer.isAtEnd {
			if let tempPair = try? arrayContainer.decode(MichelsonPair.self) { tempArgs.append(tempPair) } // Must come before `MichelsonValue` as they share similarities
			else if let tempValue = try? arrayContainer.decode(MichelsonValue.self) { tempArgs.append(tempValue) }
			else {
				let _ = try? arrayContainer.decode(DummyCodable.self)
				os_log("Unknown Michelson type found, progress so far: %@", log: .kukaiCoreSwift, type: .error, tempArgs)
			}
		}
		
		args = tempArgs
		
		try super.init(from: decoder)
	}
	
	/// Adhearing to `Encodable`
	public override func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(prim, forKey: .prim)
		try container.encode(args, forKey: .args)
		
		try super.encode(to: encoder)
	}
	
	/// Adhearing to `Equatable`
	public static func == (lhs: MichelsonPair, rhs: MichelsonPair) -> Bool {
		return lhs.prim == rhs.prim && lhs.args == rhs.args
	}
}
