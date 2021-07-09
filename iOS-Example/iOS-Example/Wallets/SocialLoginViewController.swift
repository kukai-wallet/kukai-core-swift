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
	
	let torusService = TorusAuthService(
		networkType: ClientsAndData.shared.clientConfig.networkType,
		nativeRedirectURL: "tdsdk://tdsdk/oauthCallback",
		googleRedirectURL: "com.googleusercontent.apps.238941746713-vfap8uumijal4ump28p9jd3lbe6onqt4:/oauthredirect",
		browserRedirectURL: "https://scripts.toruswallet.io/redirect.html"
	)
	
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
		torusService.createWallet(from: .apple, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	@IBAction func twitterTapped(_ sender: Any) {
		/*showActivity()
		torusService.createWallet(from: .twitter, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}*/
		
		
		showActivity()
		torusService.getAddress(from: .twitter, for: "twitter|163484202") { result in
			print("\n\n\n Result: \(result) \n\n\n")
		}
	}
	
	@IBAction func googleTapped(_ sender: Any) {
		showActivity()
		torusService.createWallet(from: .google, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	@IBAction func redditTapped(_ sender: Any) {
		showActivity()
		torusService.createWallet(from: .reddit, displayOver: self) { [weak self] result in
			self?.handleResult(result: result)
		}
	}
	
	@IBAction func facebookTapped(_ sender: Any) {
		showActivity()
		torusService.createWallet(from: .facebook, displayOver: self) { [weak self] result in
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
				self.present(alert, animated: true, completion: nil)
		}
		
		self.hideActiviy()
	}
}
