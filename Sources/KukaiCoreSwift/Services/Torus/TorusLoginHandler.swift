//
//  TorusLoginHandler.swift
//  
//
//  Created by Simon Mcloughlin on 04/07/2022.
//

import Foundation

public protocol TorusLoginHandler {
	func getLoginURL() -> URL
	func handleLogin()
}

public enum TorusLoginError: Error {
	case handleLoginRecievedInvalidParams
}

public extension TorusLoginHandler {
	
	static func generateNonce(ofLength length: Int) -> String {
		let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
		var random = ""
		
		for _ in 0...length {
			if let c = letters.randomElement() {
				random.append(c)
			}
		}
			
		return random
	}
}
