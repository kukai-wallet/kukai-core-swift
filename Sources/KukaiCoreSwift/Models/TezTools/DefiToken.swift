//
//  DefiToken.swift
//  
//
//  Created by Simon Mcloughlin on 08/11/2021.
//

import Foundation

public struct DefiToken: Codable {
	
	public let token: TezToolToken
	public let price: TezToolPrice
	
	public init(withToken: TezToolToken, andPrice: TezToolPrice) {
		token = withToken
		price = andPrice
	}
	
	public init(withToken: TezToolToken) {
		token = withToken
		price = TezToolPrice(symbol: token.symbol ?? "", tokenAddress: token.tokenAddress, decimals: token.decimals, address: token.address, ratio: 0, currentPrice: 0, buyPrice: XTZAmount.zero(), pairs: [])
	}
}
