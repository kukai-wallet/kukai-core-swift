//
//  NilOnDecodingError.swift
//  
//
//  Created by Simon Mcloughlin on 19/06/2023.
//

import Foundation

@propertyWrapper
public struct NilOnDecodingError<Wrapped> {
	public init(wrappedValue: Wrapped?) {
		self.wrappedValue = wrappedValue
	}
	
	public var wrappedValue: Wrapped?
}

extension NilOnDecodingError: Decodable where Wrapped: Decodable {
	public init(from decoder: Decoder) throws {
		let container = try decoder.singleValueContainer()
		do {
			wrappedValue = .some(try container.decode(Wrapped.self))
		} catch is DecodingError {
			wrappedValue = nil
		}
	}
}

extension NilOnDecodingError: Encodable where Wrapped: Encodable {
	public func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()
		if let value = wrappedValue {
			try container.encode(value)
		} else {
			try container.encodeNil()
		}
	}
}

public extension KeyedDecodingContainer {
	
	func decode<T>(_ type: NilOnDecodingError<T>.Type, forKey key: Self.Key) throws -> NilOnDecodingError<T> where T: Decodable {
		try decodeIfPresent(type, forKey: key) ?? NilOnDecodingError(wrappedValue: nil)
	}
	
	/// In case where people have not followed the spec correctly, and named keys slightly differently, allow a second key to be used so that, for example, we could check for `artifcatUri` or `artifact_uri` in one call
	func decodeIfPresent<T>(_ type: T.Type, forKey key: Self.Key, orBackupKey: Self.Key) throws -> T? where T: Decodable {
		if let val = try? decodeIfPresent(type, forKey: key) {
			return val
			
		} else if let backupValue = try? decodeIfPresent(type, forKey: orBackupKey) {
			return backupValue
			
		} else {
			return try decodeIfPresent(type, forKey: key)
		}
	}
}
