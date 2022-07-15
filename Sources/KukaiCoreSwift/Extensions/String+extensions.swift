//
//  String+extensions.swift
//  
//
//  Created by Simon Mcloughlin on 24/08/2021.
//

import Foundation
import CryptoKit

public extension String {
	
	/// Generate an MD5 hash from the string
	func md5() -> String {
		let digest = Insecure.MD5.hash(data: data(using: .utf8) ?? Data())

		return digest.map {
			String(format: "%02hhx", $0)
		}.joined()
	}
	
	/// Return the starting indexes of each occurnace of the supplied string
	func indexesOf(string: String) -> [String.Index] {
		var searchRange = self.startIndex..<self.endIndex
		var indices: [String.Index] = []
		
		while let range = self.range(of: string, options: .caseInsensitive, range: searchRange) {
			searchRange = range.upperBound..<searchRange.upperBound
			indices.append(range.lowerBound)
		}
		
		return indices
	}
	
	/// When an error is returned in the format `proto.012-Psithaca.gas_exhausted.operation`, in many cases we only care about the bit after the protocol. This function returns only that piece
	func removeLeadingProtocolFromRPCError() -> String? {
		let indexes = self.indexesOf(string: ".")
		
		if indexes.count > 2 {
			return String(self[index(after: indexes[1])...])
			
		} else {
			return nil
		}
	}
	
	func fromBase64URL() -> String? {
		var base64 = self
		base64 = base64.replacingOccurrences(of: "-", with: "+")
		base64 = base64.replacingOccurrences(of: "_", with: "/")
		
		while base64.count % 4 != 0 {
			base64 = base64.appending("=")
		}
		
		guard let data = Data(base64Encoded: base64) else {
			return nil
		}
		
		return String(data: data, encoding: .utf8)
	}
	
	func toBase64URL() -> String {
		var result = Data(self.utf8).base64EncodedString()
		result = result.replacingOccurrences(of: "+", with: "-")
		result = result.replacingOccurrences(of: "/", with: "_")
		result = result.replacingOccurrences(of: "=", with: "")
		return result
	}
}
