//
//  String+extensions.swift
//  
//
//  Created by Simon Mcloughlin on 24/08/2021.
//

import Foundation
import CryptoKit

public extension String {
	
	func md5() -> String {
		let digest = Insecure.MD5.hash(data: data(using: .utf8) ?? Data())

		return digest.map {
			String(format: "%02hhx", $0)
		}.joined()
	}
}
