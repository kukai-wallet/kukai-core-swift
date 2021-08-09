//
//  File.swift
//  
//
//  Created by Simon Mcloughlin on 09/08/2021.
//

import Foundation

public struct LiquidityBakingData: Codable {
	
	public let xtzPool: XTZAmount
	public let tokenPool: TokenAmount
	public let totalLiquidity: TokenAmount
	public let tokenContractAddress: String
	public let liquidityTokenContractAddress: String
}
