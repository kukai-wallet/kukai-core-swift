//
//  ImportHDViewController.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 15/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import UIKit
import KukaiCoreSwift

class ImportHDViewController: UIViewController {

	@IBOutlet weak var textview: UITextView!
	@IBOutlet weak var textfield: UITextField!
	@IBOutlet weak var importedAddressLabel: UILabel!
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		textview.layer.borderWidth = 1
		textview.layer.borderColor = UIColor.black.cgColor
		
		textfield.text = HDWallet.defaultDerivationPath
    }
	
	@IBAction func importTapped(_ sender: Any) {
		let wallet = HDWallet.create(withMnemonic: textview.text ?? "", passphrase: "", derivationPath: textfield.text ?? "")
		
		if let w = wallet {
			importedAddressLabel.text = w.address
			
			let cacheService = WalletCacheService()
			let _ = cacheService.deleteCacheAndKeys()
			let _ = cacheService.cache(wallet: w, andPassphrase: nil)
			
		} else {
			let alert = UIAlertController(title: "Error", message: "An error occured creating the wallet object", preferredStyle: .alert)
			self.present(alert, animated: true, completion: nil)
		}
	}
}
