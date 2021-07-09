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
	
	
	@IBAction func twitterTapped(_ sender: Any) {
		showActivity()
		torusService.createWallet(from: .twitter, displayOver: self) { [weak self] result in
			
			switch result {
				case .success(let wallet):
					self?.importedAddressLabel.text = wallet.address
					
					let cacheService = WalletCacheService()
					let _ = cacheService.deleteCacheAndKeys()
					let _ = cacheService.cache(wallet: wallet, andPassphrase: nil)
					
				case .failure(let error):
					let alert = UIAlertController(title: "Error", message: error.description, preferredStyle: .alert)
					self?.present(alert, animated: true, completion: nil)
			}
			
			self?.hideActiviy()
		}
	}
	
	@IBAction func googleTapped(_ sender: Any) {
	}
	
	@IBAction func redditTapped(_ sender: Any) {
	}
	
	@IBAction func facebookTapped(_ sender: Any) {
	}
}
