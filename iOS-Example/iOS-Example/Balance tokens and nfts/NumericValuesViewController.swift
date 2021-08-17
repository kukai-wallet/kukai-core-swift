//
//  NumericValuesViewController.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 15/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import UIKit
import KukaiCoreSwift

class NumericValuesViewController: UIViewController {

	@IBOutlet weak var textfield: UITextField!
	
	@IBOutlet weak var xtzNormalLabel: UILabel!
	@IBOutlet weak var xtzRpcLabel: UILabel!
	@IBOutlet weak var xtzLocalisedLabel: UILabel!
	
	@IBOutlet weak var token1NormalLabel: UILabel!
	@IBOutlet weak var token1RpcLabel: UILabel!
	@IBOutlet weak var token1Localisedlabel: UILabel!
	
	@IBOutlet weak var token2NormalLabel: UILabel!
	@IBOutlet weak var token2RpcLabel: UILabel!
	@IBOutlet weak var token2LocalisedLabel: UILabel!
	
	let TokenXTZ = Token.xtz()
	let Token1 = Token(icon: nil, name: "Token 1", symbol: "TK1", tokenType: .fungible, faVersion: .fa2, balance: TokenAmount.zero(), tokenContractAddress: "", nfts: nil)
	let Token2 = Token(icon: nil, name: "Token 2", symbol: "TK2", tokenType: .fungible, faVersion: .fa1_2, balance: TokenAmount.zero(), tokenContractAddress: "", nfts: nil)
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	
	/**
	Handling numeric types is quite complex in Tezos. Tokens can have varying number of deicmal places, but the network doesn't accept any decimals. All tokens have an "RPC Representation" that must be sent to the server, and a "Normalised Representation" thats for the UI in the format users would expect to see it.
	
	For Example:
	Users would expect to see in the UI  "1.5 XTZ". But if a user wanted to send this amount to someone else, you can't send "1.5" to the server. You need to multiply it by the number of decimal places it has (in this case 6) and instead send "1500000" to the server.
	
	This gets more complicated with other tokens having their own number of decimal places, and having to deal with strings containing VERY long numbers. ETHtz for example has 18 decimal places.
	
	`TokenAmount` and `XTZAmount` where created to abstract as much of this away as possible, and allow you to simply deal with numeric amounts in the "normalised" format. All KukaiCoreSwift functions take in a tokenAmount or xtzAmount, and behind the scenes, will convert it to the RPC representation whenever it goes to the server. When downloading balances from the server, these classes can take in RPC values for you, so you never have to deal with this logic.
	
	The classes coem with several helper methods, such as the below, that make dealing with numerics much simplier. Have a look at the example, type in numeric amounts into the textfield as if you wanted to send these amounts. You will see all the difference conversions and formatting's taking place for you in the UI.
	*/
	@IBAction func processTapped(_ sender: Any) {
		let textAsDecimal = Decimal(string: textfield.text ?? "0") ?? 0
		
		let xtzAmount = XTZAmount(fromNormalisedAmount: textAsDecimal)
		xtzNormalLabel.text = xtzAmount.normalisedRepresentation + " \(TokenXTZ.symbol ?? "")"
		xtzRpcLabel.text = xtzAmount.rpcRepresentation
		xtzLocalisedLabel.text = xtzAmount.formatNormalisedRepresentation(locale: Locale(identifier: "en-us"))
		
		let token1Amount = TokenAmount(fromNormalisedAmount: textAsDecimal, decimalPlaces: 3)
		token1NormalLabel.text = token1Amount.normalisedRepresentation + " \(Token1.symbol ?? "")"
		token1RpcLabel.text = token1Amount.rpcRepresentation
		token1Localisedlabel.text = token1Amount.formatNormalisedRepresentation(locale: Locale(identifier: "es_ES"))
		
		let token2Amount = TokenAmount(fromNormalisedAmount: textAsDecimal, decimalPlaces: 10)
		token2NormalLabel.text = token2Amount.normalisedRepresentation + " \(Token2.symbol ?? "")"
		token2RpcLabel.text = token2Amount.rpcRepresentation
		token2LocalisedLabel.text = token2Amount.formatNormalisedRepresentation(locale: Locale.current)
	}
}
