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

	@IBOutlet weak var textfield: UITextField!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		stopActivity()
		
		// Prefil the textfield with the address thats encrypted on disk, if available
		let cacheService = WalletCacheService()
		let wallet = cacheService.fetchPrimaryWallet()
		textfield.text = wallet?.address ?? ""
    }

	@IBAction func searchTapped(_ sender: Any) {
		startActivity()
		
		ClientsAndData.shared.bcdClient.fetchAccountInfo(forAddress: textfield.text ?? "") { [weak self] result in
			switch result {
				case .failure(let error):
					let alert = UIAlertController(title: "Error", message: error.description, preferredStyle: .alert)
					self?.present(alert, animated: true, completion: nil)
					
				case .success(let account):
					ClientsAndData.shared.account = account
					self?.performSegue(withIdentifier: "account", sender: self)
			}
			
			self?.stopActivity()
		}
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
