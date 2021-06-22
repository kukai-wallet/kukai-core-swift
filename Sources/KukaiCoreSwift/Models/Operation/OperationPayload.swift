//
//  OperationPayload.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 20/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import WalletCore
import os.log

/// A structure representing the request that needs to be made when sending `Opertion`'s to the RPC
public struct OperationPayload: Codable, Equatable {
	
	/// The bracnh to use when sending
	public let branch: String
	
	/// An array of `Operation`'s to be sent together in 1 request.
	public let contents: [Operation]
	
	/// Base58 signature
	var signature: String?
	
	/// Bind the operation to a specific protocol
	var `protocol`: String?
	
	
	/// Conforming to `Equatable`
	public static func == (lhs: OperationPayload, rhs: OperationPayload) -> Bool {
		
		if lhs.contents.count != rhs.contents.count {
			return false
		}
		
		var allOpsMatch = true
		for (index, op) in lhs.contents.enumerated() {
			allOpsMatch = (op.isEqual(rhs.contents[index]))
			
			if !allOpsMatch {
				return false
			}
		}
		
		return allOpsMatch && lhs.branch == rhs.branch
	}
	
	/**
	Add the signature and the protocol to the operation so that it can be injected to the blockchain
	- parameter binarySignature: Use the `Wallet.sign(...)` function to sign the forged version of the operationPayload.
	- parameter signingCurve: The `EllipticalCurve` used for signing.
	- parameter andProtocol: An `OperationMetadata` containing the network protocol to use to perform the injection.
	*/
	public mutating func addSignature(_ binarySignature: [UInt8], signingCurve: EllipticalCurve) {
		self.signature = Base58.encode(message: binarySignature, ellipticalCurve: signingCurve)
	}
	
	public mutating func addProtcol(fromMetadata metadata: OperationMetadata) {
		self.protocol = metadata.protocol
	}
}
