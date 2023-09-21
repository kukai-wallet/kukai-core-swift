//
//  LiquidityBakingData.swift
//  
//
//  Created by Simon Mcloughlin on 09/08/2021.
//

import Foundation

/// Wrapper object to hold onto all the necessary data in order to work with liquidity baking contract (swap, add or remove liqudity)
public struct LiquidityBakingData: Codable {
	
	/// The total amount of XTZ in the contract
	public let xtzPool: XTZAmount
	
	/// The total amount of the token in the contract (currently tzBTC)
	public let tokenPool: TokenAmount
	
	/// The total amount of liquidity tokens in circulation
	public let totalLiquidity: TokenAmount
	
	/// The address of the dex contract
	public let tokenContractAddress: String
	
	/// The address of the liquidty token contract
	public let liquidityTokenContractAddress: String
}
