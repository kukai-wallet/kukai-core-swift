//
//  QuipuswapExchangeLedger.swift
//  
//
//  Created by Simon Mcloughlin on 26/11/2021.
//

import Foundation

public typealias QuipuswapExchangeLedgerKeyResponse = [QuipuswapExchangeLedgerKey]

public struct QuipuswapExchangeLedgerKey: Codable {
	
	public let value: QuipuswapExchangeLedger
}

public struct QuipuswapExchangeLedger: Codable {
	
	public let balance: String
	public let frozen_balance: String
}
