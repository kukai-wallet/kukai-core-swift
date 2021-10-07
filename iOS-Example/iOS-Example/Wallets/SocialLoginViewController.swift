//
//  SocialLoginViewController.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 08/07/2021.
//

import UIKit
import KukaiCoreSwift

class SocialLoginViewController: UIViewController {

	@IBOutlet weak var importedAddressLabel: UILabel!
	@IBOutlet weak var activityView: UIActivityIndicatorView!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		activityView.isHidden = true
	}
	
	func showActivity() {
		activityView.isHidden = false
		activityView.startAnimating()
	}
	
	func hideActiviy() {
		activityView.isHidden = true
		activityView.stopAnimating()
	}
	
	@IBAction func appleTapped(_ sender: Any) {
		showActivity()
		ClientsAndData.shared.torusAuthService.createWallet(from: .apple, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	@IBAction func twitterTapped(_ sender: Any) {
		showActivity()
		ClientsAndData.shared.torusAuthService.createWallet(from: .twitter, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	@IBAction func googleTapped(_ sender: Any) {
		showActivity()
		ClientsAndData.shared.torusAuthService.createWallet(from: .google, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	@IBAction func redditTapped(_ sender: Any) {
		showActivity()
		ClientsAndData.shared.torusAuthService.createWallet(from: .reddit, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	@IBAction func facebookTapped(_ sender: Any) {
		showActivity()
		ClientsAndData.shared.torusAuthService.createWallet(from: .facebook, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	func handleResult(result: Result<TorusWallet, ErrorResponse>) {
		switch result {
			case .success(let wallet):
				self.importedAddressLabel.text = wallet.address
				
				let cacheService = WalletCacheService()
				let _ = cacheService.deleteCacheAndKeys()
				let _ = cacheService.cache(wallet: wallet)
				
			case .failure(let error):
				let alert = UIAlertController(title: "Error", message: error.description, preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
				self.present(alert, animated: true, completion: nil)
		}
		
		self.hideActiviy()
	}
}
