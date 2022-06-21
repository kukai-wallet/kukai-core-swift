//
//  FailWithParserLiquidityBaking.swift
//  
//
//  Created by Simon Mcloughlin on 21/06/2022.
//

import Foundation

public struct FailWithParserLiquidityBaking: FailWithParser {
	
	public func parse(failWith: FailWith?) -> String? {
		guard let failWith = failWith, let intString = failWith.int, let errorCode = Int(intString) else {
			return nil
		}
		
		switch errorCode {
			case 0:
				return "token contract must have a transfer entrypoint"
			case 1:
				return unknownCode(errorCode)
			case 2:
				return "self is updating token pool must be false"
			case 3:
				return "the current time must be less than the deadline"
			case 4:
				return "max tokens deposited must be greater than or equal to tokens deposited"
			case 5:
				return "lqt minted must be greater than min lqt minted"
			case 6:
				return unknownCode(errorCode)
			case 7:
				return unknownCode(errorCode)
			case 8:
				return "xtz bought must be greater than or equal to min xtz bought"
			case 9:
				return "invalid to address"
			case 10:
				return "amount must be zero"
			case 11:
				return "the amount of xtz withdrawn must be greater than or equal to min xtz withdrawn"
			case 12:
				return "lqt contract must have a mint or burn entrypoint"
			case 13:
				return "the amount of tokens withdrawn must be greater than or equal to min tokens withdrawn"
			case 14:
				return "cannot burn more than the total amount of lqt"
			case 15:
				return "token pool minus tokens withdrawn is negative"
			case 16:
				return unknownCode(errorCode)
			case 17:
				return unknownCode(errorCode)
			case 18:
				return "tokens bought must be greater than or equal to min tokens bought"
			case 19:
				return "token pool minus tokens bought is negative"
			case 20:
				return "only manager can set baker"
			case 21:
				return "only manager can set manager"
			case 22:
				return "baker permanently frozen"
			case 23:
				return "only manager can set lqt adress"
			case 24:
				return "lqt address already set"
			case 25:
				return "call not from an implicit account"
			case 26:
				return unknownCode(errorCode)
			case 27:
				return unknownCode(errorCode)
			case 28:
				return "invalid token contract missing balance of"
			case 29:
				return "this entrypoint may only be called by getbalance of tokenaddress"
			case 30:
				return unknownCode(errorCode)
			case 31:
				return "invalid intermediate contract"
			case 32:
				return "invalid fa2 balance response"
			case 33:
				return "unexpected reentrance in update token pool"
			
			default:
				return unknownCode(errorCode)
		}
	}
	
	private func unknownCode(_ code: Int) -> String {
		return "unknown Liquidity Baking error code: \(code)"
	}
}
