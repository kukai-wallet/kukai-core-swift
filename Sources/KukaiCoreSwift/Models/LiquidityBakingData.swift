//
//  File.swift
//  
//
//  Created by Simon Mcloughlin on 09/08/2021.
//

import Foundation

public struct LiquidityBakingData: Codable {
	
	let xtzPool: XTZAmount
	let tokenPool: TokenAmount
	let totalLiquidity: TokenAmount
	let tokenContractAddress: String
	let liquidityTokenContractAddress: String
}
