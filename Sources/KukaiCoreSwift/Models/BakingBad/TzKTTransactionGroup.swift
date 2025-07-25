//
//  TzKTTransactionGroup.swift
//  
//
//  Created by Simon Mcloughlin on 08/03/2022.
//

import Foundation

/// Artifical object used to group related transactions into a more user friendly display
/// For example, 1 contract call can reuslt in many transactions being returned. To avoid the users UI being clogged, we group all them into 1 group, so the user only needs to see 1 item for 1 action they performed
public struct TzKTTransactionGroup: Codable, Hashable, Identifiable, CustomStringConvertible {
	
	// MARK: - Properties
	
	public var groupType: TzKTTransaction.TransactionSubType
	public let hash: String
	public let transactions: [TzKTTransaction]
	public let status: TzKTTransaction.TransactionStatus
	
	public var primaryToken: Token? = nil
	public var secondaryToken: Token? = nil
	public var entrypointCalled: String? = nil
	
	public var id: Decimal {
		get {
			return transactions.map({ $0.id }).reduce(0, +)
		}
	}
	
	public init?(withTransactions transactions: [TzKTTransaction], currentWalletAddress: String) {
		guard let first = transactions.first/*, let last = transactions.last*/ else {
			return nil
		}
		
		self.hash = first.hash
		self.transactions = transactions
		self.groupType = .unknown
		self.status = first.status ?? .unknown
		
		
		if transactions.count == 1 {
			self.groupType = first.subType ?? .unknown
			self.entrypointCalled = first.entrypointCalled
			self.primaryToken = first.primaryToken
			
		}/* else if transactions.count > 1,
				  let exchangeFirst = transactions.last(where: { $0.getEntrypoint() == "transfer" || $0.amount != .zero() }),
				  let exchangeLast = transactions.first(where: { ($0.getEntrypoint() == "transfer" || $0.amount != .zero()) && $0.id != exchangeFirst.id }),
				  (exchangeFirst.target?.address != currentWalletAddress && exchangeFirst.getTokenTransferDestination() != currentWalletAddress),
				  (exchangeLast.target?.address == currentWalletAddress || exchangeLast.getTokenTransferDestination() == currentWalletAddress),
				  let primary = exchangeFirst.createPrimaryToken(),
				  let secondary = exchangeLast.createPrimaryToken(),
				  (primary.isXTZ() || primary.tokenContractAddress != nil),
				  (secondary.isXTZ() || secondary.tokenContractAddress != nil) {
			
			// Going from reverse order, get first op in the array that transfers token or XTZ amount
			// get the last op that transfers a token or an XTZ amount
			// Double check that both are not the same op
			//
			// Then confirm that the first token transfer is not pointing to current address, and last token transfer
			// is pointing to the current wallet (either top level address or inside michelson)
			// as harvesting farms looks similar to exchange, with the difference that a harvest is all tokens coming to the wallet
			
			self.groupType = .exchange
			self.primaryToken = primary
			self.secondaryToken = secondary
			
		  }*/ else if let entrypoint = transactions.last(where: { $0.entrypointCalled != "approve" && $0.entrypointCalled != "update_operators" && $0.entrypointCalled != nil })?.entrypointCalled {
			self.groupType = .contractCall
			self.entrypointCalled = entrypoint
			
		} else if let first = transactions.first, first.subType != .unknown {
			self.groupType = first.subType ?? .unknown
			self.primaryToken = first.primaryToken
			
		} else {
			self.groupType = .unknown
		}
	}
	
	
	
	// MARK: - CustomStringConvertible
	
	public var description: String {
		return "\nHash: \(hash), GroupType: \(groupType), entrypointCalled: \(entrypointCalled ?? "-"), primaryToken: \(primaryToken?.balance.normalisedRepresentation ?? "-") \(primaryToken?.symbol ?? "-"), secondaryToken: \(secondaryToken?.balance.normalisedRepresentation ?? "-") \(secondaryToken?.symbol ?? "-"), Transactions: \n \(transactions) \n"
	}
	
	
	// MARK: - Hashable
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
	
	public static func == (lhs: TzKTTransactionGroup, rhs: TzKTTransactionGroup) -> Bool {
		return lhs.id == rhs.id
	}
}
