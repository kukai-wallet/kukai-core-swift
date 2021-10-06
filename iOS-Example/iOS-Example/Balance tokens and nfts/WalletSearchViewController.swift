//
//  WalletSearchViewController.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 10/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import UIKit
import KukaiCoreSwift

class WalletSearchViewController: UIViewController {

	@IBOutlet weak var tz1Textfield: UITextField!
	@IBOutlet weak var twitterTextfield: UITextField!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		stopActivity()
		
		// Prefil the textfield with the address thats encrypted on disk, if available
		let cacheService = WalletCacheService()
		let wallet = cacheService.fetchPrimaryWallet()
		tz1Textfield.text = wallet?.address ?? ""
    }

	@IBAction func tz1SearchTapped(_ sender: Any) {
		startActivity()
		
		ClientsAndData.shared.bcdClient.fetchAccountInfo(forAddress: tz1Textfield.text ?? "") { [weak self] result in
			switch result {
				case .failure(let error):
					let alert = UIAlertController(title: "Error", message: error.description, preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
					self?.present(alert, animated: true, completion: nil)
					
				case .success(let account):
					ClientsAndData.shared.account = account
					self?.performSegue(withIdentifier: "account", sender: self)
			}
			
			self?.stopActivity()
		}
	}
	
	@IBAction func twitterSearchTapped(_ sender: Any) {
		guard let twitterUsername = twitterTextfield.text else {
			return
		}
		
		startActivity()
		/*ClientsAndData.shared.torusAuthService.getAddress(from: .twitter, for: twitterUsername) { [weak self] torusResult in
			
			switch torusResult {
				
				case .success(let torusAddress):
					ClientsAndData.shared.bcdClient.fetchAccountInfo(forAddress: torusAddress) { [weak self] bcdResult in
						switch bcdResult {
							case .failure(let error):
								let alert = UIAlertController(title: "Error", message: error.description, preferredStyle: .alert)
								alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
								self?.present(alert, animated: true, completion: nil)
								
							case .success(let account):
								ClientsAndData.shared.account = account
								self?.performSegue(withIdentifier: "account", sender: self)
						}
						
						self?.stopActivity()
					}
					
				case .failure(let torusError):
					let alert = UIAlertController(title: "Error", message: torusError.description, preferredStyle: .alert)
					alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
					self?.present(alert, animated: true, completion: nil)
					self?.stopActivity()
			}
		}*/
	}
	
	func startActivity() {
		activityIndicator.isHidden = false
		activityIndicator.startAnimating()
	}
	
	func stopActivity() {
		activityIndicator.isHidden = true
		activityIndicator.stopAnimating()
	}
}
