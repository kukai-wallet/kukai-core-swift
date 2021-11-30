//
//  QuipuswapExchangeLedger.swift
//  
//
//  Created by Simon Mcloughlin on 26/11/2021.
//

import Foundation

/// Wrapper object around the network response
public typealias QuipuswapExchangeLedgerKeyResponse = [QuipuswapExchangeLedgerKey]

/// The gneric container object holding the raw data
public struct QuipuswapExchangeLedgerKey: Codable {
	
	public let value: QuipuswapExchangeLedger
}

/// The unique data inside the Ledger BigMap
public struct QuipuswapExchangeLedger: Codable {
	
	/// Usable balance of the token owned
	public let balance: String
	
	/// Currently unaccessible balance of the token owned
	public let frozen_balance: String
}
