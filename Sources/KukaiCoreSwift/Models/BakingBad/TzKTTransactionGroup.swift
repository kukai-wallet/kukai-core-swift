//
//  TzKTTransactionGroup.swift
//  
//
//  Created by Simon Mcloughlin on 08/03/2022.
//

import Foundation

public struct TzKTTransactionGroup: Codable {
	
	// MARK: Types
	
	public enum TransactionGroupType: String, Codable {
		case send
		case receive
		case delegate
		case reveal
		case exchange
		case contractCall
		case unknown
	}
	
	public struct TokenDetails: Codable {
		public let target: TzKTTransaction.TransactionLocation?
		public let rpcAmount: String
		
		public func isXTZ() -> Bool {
			return target == nil
		}
	}
	
	
	
	// MARK: - Properties
	
	public var groupType: TransactionGroupType
	public let hash: String
	public let transactions: [TzKTTransaction]
	
	public var primaryToken: TokenDetails? = nil
	public var secondaryToken: TokenDetails? = nil
	public var entrypointCalled: String? = nil
	
	public init?(withTransactions transactions: [TzKTTransaction], currentWalletAddress: String) {
		guard let first = transactions.first, let last = transactions.last else {
			return nil
		}
		
		self.hash = first.hash
		self.transactions = transactions
		self.groupType = .unknown
		
		
		if transactions.count == 1, let entrypoint = first.getEntrypoint() {
			self.groupType = .contractCall
			self.entrypointCalled = entrypoint
			
		} else if transactions.count == 1 {
			if first.target?.address == currentWalletAddress {
				self.groupType = .receive
				self.primaryToken = createTokenDetails(transaction: first)
				return
				
			} else if first.target?.address != currentWalletAddress {
				self.groupType = .send
				self.primaryToken = createTokenDetails(transaction: first)
				return
				
			} else if first.type == .delegation {
				self.groupType = .delegate
				return
				
			} else if first.type == .reveal {
				self.groupType = .reveal
				return
			}
			
		} else if transactions.count > 1,
				  let exchangeFirst = transactions.last(where: { $0.getEntrypoint() == "transfer" || $0.amount != .zero() }),
				  let exchangeLast = transactions.first(where: { ($0.getEntrypoint() == "transfer" || $0.amount != .zero()) && $0.id != exchangeFirst.id }),
				  (exchangeFirst.target?.address != currentWalletAddress && exchangeFirst.getTokenTransferDestination() != currentWalletAddress),
				  (exchangeLast.target?.address == currentWalletAddress || exchangeLast.getTokenTransferDestination() == currentWalletAddress),
				  let primary = createTokenDetails(transaction: exchangeFirst),
				  let secondary = createTokenDetails(transaction: exchangeLast),
				  (primary.isXTZ() || primary.target != nil),
				  (secondary.isXTZ() || secondary.target != nil) {
			
			// going from reverse order, get first op in the array that transfers token or XTZ amount
			// get the last op that transfers a token or an XTZ amount
			// Double check that both are not the same op
			//
			// Then confirm that the first token transfer is not point to current address, andlast token transfer
			// is pointing to the current wallet (either top level address or inside michelson)
			// as harvesting farms looks similar to exchange, with the difference that a harvest is all tokens coming to the wallet
			
			self.groupType = .exchange
			self.primaryToken = primary
			self.secondaryToken = secondary
			
		} else if let entrypoint = last.getEntrypoint() {
			self.groupType = .contractCall
			self.entrypointCalled = entrypoint
			
		} else {
			self.groupType = .unknown
		}
	}
	
	private func createTokenDetails(transaction: TzKTTransaction) -> TokenDetails? {
		if (transaction.amount != .zero()) {
			return TokenDetails(target: nil, rpcAmount: transaction.amount.rpcRepresentation)
			
		} else if let amount = transaction.getTokenTransferAmount() {
			return TokenDetails(target: transaction.target, rpcAmount: amount)
		}
		
		return nil
	}
}
