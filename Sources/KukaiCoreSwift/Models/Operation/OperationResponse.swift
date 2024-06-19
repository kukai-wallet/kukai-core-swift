//
//  OperationResponse.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 24/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// Structure representing the response returned from RPC endpoints such as  `.../preapply/operations`
public struct OperationResponse: Codable {
	
	public let contents: [OperationResponseContent]
	
	/// Check if the operation(s) have been backtracked or reversed due to a failure
	public func isFailed() -> Bool {
		for content in contents {
			if content.metadata.operationResult?.status == "backtracked" || content.metadata.operationResult?.status == "failed" || content.metadata.operationResult?.status == "skipped" {
				return true
			}
		}
		
		return false
	}
	
	
	/// Return the last error object from each internal result. The last error object is the one that contains the location of the error in the smart contract and the `with` string, giving the most debugable information
	public func errors() -> [OperationResponseInternalResultError] {
		var errors: [OperationResponseInternalResultError] = []
		
		for content in contents {
			if let operationError = content.metadata.operationResult?.errors?.last {
				errors.append(operationError)
			}
			
			if let internalOperationResults = content.metadata.internalOperationResults {
				for internalResult in internalOperationResults {
					if let error = internalResult.result.errors?.last {
						errors.append(error)
					}
				}
			}
		}
		
		return errors
	}
}

/// The main `content` of the JSON returned
public struct OperationResponseContent: Codable {
	let kind: String
	let source: String?
	let metadata: OperationResponseMetadata
	let destination: String?
	let amount: String?
	let fee: String?
	let balance: String?
	
	public func isOrigination() -> Bool {
		if kind == "origination" {
			return true
		}
		
		return false
	}
}

/// The metadata belonging to the `OperationResponse`
public struct OperationResponseMetadata: Codable {
	let balanceUpdates: [BalanceUpdate]?
	let operationResult: OperationResponseResult?
	let internalOperationResults: [OperationResponseInternalOperation]?
	
	private enum CodingKeys: String, CodingKey {
		case balanceUpdates = "balance_updates"
		case operationResult = "operation_result"
		case internalOperationResults = "internal_operation_results"
	}
}

/// Struct representing a change to the balance of the sender, destination or intermediary contract
public struct BalanceUpdate: Codable {
	let kind: String
	let contract: String?
	let change: String
	let delegate: String?
	let cycle: Int?
	let staker: BalanceUpdateStake?
}

public struct BalanceUpdateStake: Codable {
	let contract: String
	let delegate: String
}

/// The inner `result` key from the `OeprationResponse`
public struct OperationResponseResult: Codable {
	let status: String
	let balanceUpdates: [BalanceUpdate]?
	let consumedMilligas: String?
	let storageSize: String?
	let paidStorageSizeDiff: String?
	let allocatedDestinationContract: Bool?
	let errors: [OperationResponseInternalResultError]?
	
	private enum CodingKeys: String, CodingKey {
		case status
		case balanceUpdates = "balance_updates"
		case consumedMilligas = "consumed_milligas"
		case storageSize = "storage_size"
		case paidStorageSizeDiff = "paid_storage_size_diff"
		case allocatedDestinationContract = "allocated_destination_contract"
		case errors
	}
	
	func isFailed() -> Bool {
		return status == "failed"
	}
}

/// Definition of the internal operation found inside `OperationResponse`
public struct OperationResponseInternalOperation: Codable {
	let kind: String
	let source: String
	let result: OperationResponseResult
}

/// Definition of the outer Error object found inside `OperationResponseInternalResult`
public struct OperationResponseInternalResultError: Codable, Equatable {
	public let kind: String
	public let id: String
	public let contract: String?
	public let expected: String?
	public let found: String?
	public let location: Int?
	public let with: FailWith?
}

/// The error string, error int (code), or micheline error object returned inside `FailWith`
public struct FailWith: Codable, Equatable {
	public let string: String?
	public let int: String?
	public let args: [[String: String]]?
	
	/// Pass in a dedicated FailWith parser (unique to each dApp) and have it convert the failWith data into an error message
	func convertToHumanReadableMessage(parser: FailWithParser) -> String? {
		return parser.parse(failWith: self)
	}
	
	enum CodingKeys: String, CodingKey {
		case string
		case int
		case args
	}
	
	public init(string: String?, int: String?, args: [[String: String]]?) {
		self.string = string
		self.int = int
		self.args = args
	}
	
	private struct DummyCodable: Codable {}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		string = try container.decodeIfPresent(String.self, forKey: .string)
		int = try container.decodeIfPresent(String.self, forKey: .int)
		
		// "args" is capable of being another complex Michelson type JSON object which would actually require "[String: Any]", but this opens up so many issues
		// Currently i've only ever seen something not compliant with `[String: String]`, when it was supplying additional data. The error message was still String: String
		// e.g. [string: "not enough balance", [args: ["147", "14"]]]
		// In this case, telling the user that they have insufficnet token balance without the amounts, is sufficient until a better solution can be found
		if container.allKeys.contains(.args) {
			var argsArray = try? container.nestedUnkeyedContainer(forKey: .args)
			var tempArgs: [[String: String]] = []
			
			while !(argsArray?.isAtEnd ?? true) {
				if let dict = try? argsArray?.decode([String: String].self) {
					tempArgs.append(dict)
				} else {
					let _ = try? argsArray?.decode(DummyCodable.self)
				}
			}
			
			args = tempArgs
			
		} else {
			args = nil
		}
	}
}
