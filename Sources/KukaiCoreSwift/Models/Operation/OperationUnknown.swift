//
//  OperationUnknown.swift
//  
//
//  Created by Simon Mcloughlin on 11/01/2024.
//

import Foundation
import OSLog

public enum OperationUnknownError: Error {
	case unableToRegisterKey
}

/// A subclass of `Operation` meant to catch any, currently, unsupported operations. The Tezos protocol can add new operations at any time. If not `Codable` struct / class is present to parse it, then that operation can't be performed.
/// This class allows for clients to parse the JSON, capturing all of the data, enabling the ability to add counter, source and fees, without needing to know what type of operation it is.
/// Class can be encoded as JSON and presented to the user to confirm if they want to trust it or not
public class OperationUnknown: Operation {
	
	/// Allows to use Codable encoder and decoder, with CodingKey, without knowing in advanced what they keys are
	struct DynamicCodingKey : CodingKey {
		var stringValue: String
		init?(stringValue: String) {
			self.stringValue = stringValue
		}
		
		var intValue: Int? { return nil }
		init?(intValue: Int) { return nil }
	}
	
	/// We need to capture and return whatever `kind` value is supplied. But due to the fact that `Operation` will parse this as an enum, with a fixed number of cases
	/// we need to capture it seperately and overwrite `kind` during the encode process
	public let unknownKind: String
	
	/// A dicitoanry containing all the top level keys and values. May contain string, decimal, bool, array of type Any, or dictionary of type [String: Any]
	public let allOtherProperties: [String: Any]
	
	
	
	
	// MARK: - Codable
	
	/// Iterate through every key in the JSON and capture them all. Pass the object up to the super to pull out source, counter, fees etc
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: DynamicCodingKey.self)
		
		var allProperties: [String: Any] = [:]
		for key in container.allKeys {
			
			if let value = try? container.decodeIfPresent(String.self, forKey: key) {
				allProperties[key.stringValue] = value
				
			} else if let value = try? container.decodeIfPresent(Decimal.self, forKey: key) {
				allProperties[key.stringValue] = value
				
			} else if let value = try? container.decodeIfPresent(Bool.self, forKey: key) {
				allProperties[key.stringValue] = value
				
			} else if let value = try? container.decodeIfPresent([String:Any].self, forKey: key) {
				allProperties[key.stringValue] = value
				
			} else if let value = try? container.decodeIfPresent([Any].self, forKey: key) {
				allProperties[key.stringValue] = value
				
			} else {
				Logger.kukaiCoreSwift.error("Unable to extract property for OperationUnknown. Value of unknown type for key: \(key)")
			}
		}
		
		unknownKind = allProperties["kind"] as? String ?? "unknown"
		allOtherProperties = allProperties
		
		try super.init(from: decoder)
	}
	
	/// Encode all values from `allOtherProperties` into a JSON dictionary, use unknownKind as the `kind` value, and then add anything applied to the super class
	public override func encode(to encoder: Encoder) throws {
		guard let kindKey =  DynamicCodingKey(stringValue: "kind") else {
			throw OperationUnknownError.unableToRegisterKey
		}
		
		var container = encoder.container(keyedBy: DynamicCodingKey.self)
		
		// Manually handle Kind
		try? container.encode(unknownKind, forKey: kindKey)
		
		// Process all stored values
		for keyString in allOtherProperties.keys {
			if let key = DynamicCodingKey(stringValue: keyString) {
				if let val = allOtherProperties[keyString] as? String {
					try? container.encode(val, forKey: key)
					
				} else if let val = allOtherProperties[keyString] as? Decimal {
					try? container.encode(val, forKey: key)
					
				} else if let val = allOtherProperties[keyString] as? Bool {
					try? container.encode(val, forKey: key)
					
				} else if let val = allOtherProperties[keyString] as? [Any] {
					try? container.encode(val, forKey: key)
					
				} else if let val = allOtherProperties[keyString] as? [String: Any] {
					try? container.encode(val, forKey: key)
				}
			}
		}
		
		// Handle any super class properties that weren't inside allProperties. Due to kind be handled already, we can't rely on super
		if allOtherProperties["source"] == nil, let key = DynamicCodingKey(stringValue: "source") {
			try? container.encodeIfPresent(self.source, forKey: key)
		}
		
		if allOtherProperties["counter"] == nil, let key = DynamicCodingKey(stringValue: "counter") {
			try? container.encodeIfPresent(self.counter, forKey: key)
		}
		
		if let storageKey = DynamicCodingKey(stringValue: "storage_limit"), let gasKey = DynamicCodingKey(stringValue: "gas_limit"), let feeKey = DynamicCodingKey(stringValue: "fee") {
			try container.encode("\(operationFees.storageLimit)", forKey: storageKey)
			try container.encode("\(operationFees.gasLimit)", forKey: gasKey)
			try container.encode(operationFees.transactionFee.rpcRepresentation, forKey: feeKey)
		}
	}
}
