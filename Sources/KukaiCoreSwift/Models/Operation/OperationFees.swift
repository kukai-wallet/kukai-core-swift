//
//  OperationFee.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 20/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// typealias to make it clearer when we are using NanoTez, which only is only used for fee calcualtion
public typealias NanoTez = Int

/// A structure representing all the fees, storage and computation needed to perform an `Operation`
public struct OperationFees: Equatable {
	
	/// Enum to differentiate different types of extra fees. Such as allocation fees when sending to a currently unrevealed account.
	public enum NetworkFeeType: String {
		case burnFee
		case allocationFee
	}
	
	/// The transaction fee that the sender is willing to pay in order to perform the `Operation`.
	/// Strictly speaking operations don't have a fee, but a gas cost, and fees and offered by the user instead.
	/// Practically, bakers will prioritsie `Operation`'s with higher fees. Resulting in default feePerGas rate being required in order to get a transaction through.
	public var transactionFee: XTZAmount
	
	/// Additional fees the account will have to pay in order to send this operation. Such as allocating space for an unrevealed account.
	public var networkFees: [[NetworkFeeType: XTZAmount]] = []
	
	/// The limit of gas (computation + CPU) this `Operation` should take. If it exceeds this value when running, the `Operation` will fail.
	public var gasLimit: Int
	
	/// The limit of storage (disk) this `Operation` requires to complete. If it exceeds this value when running, the `Operation` will fail.
	public var storageLimit: Int
	
	
	/**
	Add together all the network fees and transaction fees
	*/
	public func allFees() -> XTZAmount {
		return allNetworkFees() + transactionFee
	}
	
	
	/**
	Add together all the network fees and transaction fees
	*/
	public func allNetworkFees() -> XTZAmount {
		var total = XTZAmount.zero()
		
		networkFees.forEach { (fee) in
			total += fee.values.reduce(XTZAmount.zero(), +)
		}
		
		return total
	}
	
	
	/**
	Get a default fees for each type of `Operation`. No guarentee these will succeed.
	- parameter operationKing: enum to denote the type of `Operation`
	- returns: a `OperationFees` object with all the values set.
	*/
	public static func defaultFees(operationKind: OperationKind) -> OperationFees {
		switch operationKind {
			case .delegation:
				return OperationFees(transactionFee: XTZAmount(fromNormalisedAmount: 0.001257), gasLimit: 10000, storageLimit: 0)
			
			case .transaction, .unknown:
				return OperationFees(transactionFee: XTZAmount(fromNormalisedAmount: 0.001410), gasLimit: 10500, storageLimit: 257)
			
			case .reveal:
				return OperationFees(transactionFee: XTZAmount(fromNormalisedAmount: 0.001268), gasLimit: 10000, storageLimit: 0)
				
			case .activate_account:
				return OperationFees(transactionFee: XTZAmount(fromNormalisedAmount: 0.001268), gasLimit: 10000, storageLimit: 0)
			
			case .origination:
				return OperationFees(transactionFee: XTZAmount(fromNormalisedAmount: 0.001477), gasLimit: 10000, storageLimit: 257)
		}
	}
	
	/**
	Confirming to `Equatable`
	*/
	public static func == (lhs: OperationFees, rhs: OperationFees) -> Bool {
		// Intentionally not checking Network Fees, these don't come back down from the network when doing a parse, these are local only
		return lhs.transactionFee.rpcRepresentation == rhs.transactionFee.rpcRepresentation &&
			lhs.gasLimit == rhs.gasLimit &&
			lhs.storageLimit == rhs.storageLimit
	}
}
