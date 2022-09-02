//
//  CreateAndSendOpViewController.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 15/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import UIKit
import KukaiCoreSwift

class CreateAndSendOpViewController: UIViewController {

	@IBOutlet weak var destinationTextField: UITextField!
	@IBOutlet weak var amountTextField: UITextField!
	@IBOutlet weak var opHashLabel: UILabel!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
	/*
	override func viewDidLoad() {
        super.viewDidLoad()
		
		activityIndicator.isHidden = true
    }
	
	
	/**
	The function will take the destination address entered, the XTZ amount entered, convert it to an `XTZAmount` and then use the `TezosNodeClient` to estimate the network fees and send.
	
	The TezosNodeClient and its configuration are inside a singleton called `ClientsAndData`. By default its been setup to use testnet and local forging. But these can be changed by creating a new config object.
	*/
	@IBAction func sendTapped(_ sender: Any) {
		
		// Check we have a wallet saved in the wallet cahce
		guard let wallet = WalletCacheService().fetchPrimaryWallet() else {
			let alert = UIAlertController(title: "Error", message: "No Wallet cached on device. Please use the wallet creation / import feature first", preferredStyle: .alert)
			alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
			self.present(alert, animated: true, completion: nil)
			return
		}
		
		// Grab the values entered in the UI
		let textAsDecimal = Decimal(string: amountTextField.text ?? "0") ?? 0
		let xtzAmount = XTZAmount(fromNormalisedAmount: textAsDecimal)
		let destination = destinationTextField.text ?? ""
		
		
		// Create the array of operations needed, by using the helper methods inside the OperationFactory
		let operations = OperationFactory.sendOperation(xtzAmount, of: Token.xtz(), from: wallet.address, to: destination)
		
		activityIndicator.isHidden = false
		activityIndicator.startAnimating()
		
		// Estimate the cost of the operation (ideally display this to a user first and let them confirm)
		ClientsAndData.shared.tezosNodeClient.estimate(operations: operations, withWallet: wallet, receivedSuggestedGas: false) { [weak self] estimationResult in
			switch estimationResult {
				case .success(let estimatedOperations):
					
					
					
					// Take the estimated operations and send them to the Tezos node
					ClientsAndData.shared.tezosNodeClient.send(operations: estimatedOperations, withWallet: wallet) { [weak self] sendResult in
						switch sendResult {
							case .success(let opHash):
								
								// If successful, we will get back a hash of the Operation that was injected to the blockchain. We can look this up later using `TzKTService`
								self?.opHashLabel.text = opHash
								
								// TODO: update
								/*
								ClientsAndData.shared.tzktClient.waitForInjection(ofHash: opHash, fromAddress: wallet.address) { success, systemError, kukaiError in
									if success {
										let alert = UIAlertController(title: "Success", message: "Operation has been injected", preferredStyle: .alert)
										alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
										self?.present(alert, animated: true, completion: nil)
										self?.activityIndicator.stopAnimating()
										self?.activityIndicator.isHidden = true
										
									} else {
										let alert = UIAlertController(title: "Error", message: "an error occured searching for the operation: \(kukaiError?.description ?? "")", preferredStyle: .alert)
										alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
										self?.present(alert, animated: true, completion: nil)
										self?.activityIndicator.stopAnimating()
										self?.activityIndicator.isHidden = true
									}
								}
								*/
								
							case .failure(let sendError):
								
								// It may fail for many resons, display the error
								let alert = UIAlertController(title: "Error", message: sendError.description, preferredStyle: .alert)
								alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
								
								self?.present(alert, animated: true, completion: nil)
								self?.activityIndicator.stopAnimating()
								self?.activityIndicator.isHidden = true
						}
					}
					
					
					
				case .failure(let estimationError):
					let alert = UIAlertController(title: "Error", message: estimationError.description, preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
					self?.present(alert, animated: true, completion: nil)
					self?.activityIndicator.stopAnimating()
					self?.activityIndicator.isHidden = true
			}
		}
	}
	*/
}
