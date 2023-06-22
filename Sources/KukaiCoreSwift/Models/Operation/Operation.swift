//
//  Operation.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 20/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// Base class representing an `Operation` on the Tezos network. On its own this class can't be sent to the network. See its subclasses for more info.
public class Operation: Codable {
	
	enum CodingKeys: String, CodingKey {
        case operationKind = "kind"
		case source
		case counter
		case storageLimit = "storage_limit"
		case gasLimit = "gas_limit"
		case fee
    }
	
	/// An enum to denote the type of operation. e.g. `transaction`, `delegation`, `reveal` etc.
	public let operationKind: OperationKind
	
	/// The source address for the operation
	public var source: String?
	
	/// A string representing a numeric counter. Must be unique and 1 higher than the previous counter. Current counter obtained from the metadata query in `TezosNodeClient`
	public var counter: String? = "0"
	
	/// Object representing the various fees, storage and compute required to fulfil this operation
	public var operationFees: OperationFees = OperationFees.zero()
	
	/**
	Create a base operation.
	- parameter operationKind: The type of operation.
	- parameter source: The address of the acocunt sending the operation.
	*/
	public init(operationKind: OperationKind, source: String) {
		self.operationKind = operationKind
		
		if operationKind != .activate_account {
			self.source = source
			
		} else {
			self.source = nil
			self.counter = nil
			self.operationFees = OperationFees.zero()
		}
	}
    
	/**
	Create a base operation.
	- parameter from: A decoder used to convert a data fromat (such as JSON) into the model object.
	*/
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		operationKind = OperationKind(rawValue: try container.decode(String.self, forKey: .operationKind)) ?? OperationKind.unknown
		
		if operationKind != .activate_account {
			source = try container.decodeIfPresent(String.self, forKey: .source)
			counter = try container.decodeIfPresent(String.self, forKey: .counter)
			
			
			// When we encode, we encode all properties. But when coming from beacon it will sometimes supply a suggestion for gas and storage, but will not include a fee
			// When we have all, just encode
			if let storageInt = Int(try container.decodeIfPresent(String.self, forKey: .storageLimit) ?? ""),
			   let gasInt = Int(try container.decodeIfPresent(String.self, forKey: .gasLimit) ?? ""),
			   let feeString = try container.decodeIfPresent(String.self, forKey: .fee) {
				operationFees = OperationFees(transactionFee: XTZAmount(fromRpcAmount: feeString) ?? XTZAmount.zero(), gasLimit: gasInt, storageLimit: storageInt)
			}
			
			// When we have gas and storage suggestions, encode those and compute a fee
			else if let storageInt = Int(try container.decodeIfPresent(String.self, forKey: .storageLimit) ?? ""),
					let gasInt = Int(try container.decodeIfPresent(String.self, forKey: .gasLimit) ?? "") {
				
				let fee = XTZAmount.zero() // Fee will need to be computed outside. Requires network calls to see current constants and forging the JSON. Can't be done here
				operationFees = OperationFees(transactionFee: fee, gasLimit: gasInt, storageLimit: storageInt)
			}
			
		} else {
			source = nil
			counter = nil
			operationFees = OperationFees.zero()
		}
	}
	
	/**
	Convert the object into a data format, such as JSON.
	- parameter to: An encoder that will allow conversions to multipel data formats.
	*/
	public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(operationKind.rawValue, forKey: .operationKind)
		
		if operationKind != .activate_account {
			try container.encode(source, forKey: .source)
			try container.encode(counter, forKey: .counter)
			try container.encode("\(operationFees.storageLimit)", forKey: .storageLimit)
			try container.encode("\(operationFees.gasLimit)", forKey: .gasLimit)
			try container.encode(operationFees.transactionFee.rpcRepresentation, forKey: .fee)
		}
    }
	
	/**
	A function to check if two operations are equal.
	- parameter _: An `Operation` to compare against
	- returns: A `Bool` indicating the result.
	*/
	public func isEqual(_ op: Operation) -> Bool {
		return operationKind == op.operationKind &&
			source == op.source &&
			counter == op.counter &&
			operationFees == op.operationFees
	}
}


extension Array where Element == Operation {
	
	/**
	 Operation's are classes, passed by reference, but often require making copies so that you can manipulate them before sending to be estimated.
	 Function make it easy by converting the array to JSON and recreating, avoiding issues where construnctors manipulate inputs before storing
	 */
	public func copyOperations() -> [Operation] {
		guard let opJson = try? JSONEncoder().encode(self), let jsonArray = try? JSONSerialization.jsonObject(with: opJson, options: .allowFragments) as? [[String: Any]] else {
			return []
		}
		
		var ops: [KukaiCoreSwift.Operation] = []
		for (index, jsonObj) in jsonArray.enumerated() {
			guard let kind = OperationKind(rawValue: (jsonObj["kind"] as? String) ?? ""), let jsonObjAsData = try? JSONSerialization.data(withJSONObject: jsonObj, options: .fragmentsAllowed) else {
				continue
			}
			
			var tempOp: KukaiCoreSwift.Operation? = nil
			switch kind {
				case .activate_account:
					tempOp = try? JSONDecoder().decode(OperationActivateAccount.self, from: jsonObjAsData)
				case .ballot:
					tempOp = try? JSONDecoder().decode(OperationBallot.self, from: jsonObjAsData)
				case .delegation:
					tempOp = try? JSONDecoder().decode(OperationDelegation.self, from: jsonObjAsData)
				case .double_baking_evidence:
					tempOp = try? JSONDecoder().decode(OperationDoubleBakingEvidence.self, from: jsonObjAsData)
				case .double_endorsement_evidence:
					tempOp = try? JSONDecoder().decode(OperationDoubleEndorsementEvidence.self, from: jsonObjAsData)
				case .endorsement:
					tempOp = try? JSONDecoder().decode(OperationEndorsement.self, from: jsonObjAsData)
				case .origination:
					tempOp = try? JSONDecoder().decode(OperationOrigination.self, from: jsonObjAsData)
				case .proposals:
					tempOp = try? JSONDecoder().decode(OperationProposals.self, from: jsonObjAsData)
				case .reveal:
					tempOp = try? JSONDecoder().decode(OperationReveal.self, from: jsonObjAsData)
				case .seed_nonce_revelation:
					tempOp = try? JSONDecoder().decode(OperationSeedNonceRevelation.self, from: jsonObjAsData)
				case .transaction:
					tempOp = try? JSONDecoder().decode(OperationTransaction.self, from: jsonObjAsData)
				case .unknown:
					tempOp = nil
			}
			
			if let tempOp = tempOp {
				tempOp.operationFees = self[index].operationFees
				ops.append(tempOp)
			}
		}
		
		return ops
	}
}
