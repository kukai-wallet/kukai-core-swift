//
//  NetworkChoiceViewController.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 06/07/2021.
//

import UIKit
import KukaiCoreSwift

class NetworkChoiceViewController: UIViewController {

	@IBOutlet weak var switchToButton: UIButton!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		updateButtonText()
    }
	
	func updateButtonText() {
		if ClientsAndData.shared.clientConfig.networkType == .testnet {
			switchToButton.setTitle("Switch to Mainnet", for: .normal)
		} else {
			switchToButton.setTitle("Switch to Testnet", for: .normal)
		}
	}
	
	@IBAction func switchToTapped(_ sender: Any) {
		let isTestnet = ClientsAndData.shared.clientConfig.networkType == .testnet
		ClientsAndData.shared.updateNetwork(network: isTestnet ? .mainnet : .testnet)
		updateButtonText()
	}
}
