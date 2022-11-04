//
//  NewWalletViewController.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 15/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import UIKit
import KukaiCoreSwift

class NewWalletViewController: UIViewController {
	
	@IBOutlet weak var addressLabel: UILabel!
	@IBOutlet weak var derivationPathLabel: UILabel!
	@IBOutlet weak var mnemonicLabel: UILabel!
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	 
	@IBAction func createButtonTapped(_ sender: Any) {
		
		// We can create HD Wallets or linear wallets in a single line of code, creating a new Mnemonic and using the default derivation path (for HD)
		let wallet = HDWallet(withMnemonicLength: .twelve, passphrase: "")
		// wallet = LinearWallet(withMnemonicLength: .twelve, passphrase: "")
		
		addressLabel.text = wallet?.address
		derivationPathLabel.text = wallet?.derivationPath
		mnemonicLabel.text = wallet?.mnemonic.words.description
		
		
		// You should never keep a wallet object in memory any long than absolutely necessary, for security reasons
		// KukaiCoreSwift provides a `WalletCacheService` that stores wallet data in an encrytped text file, who's key is held in the secure enclave.
		// You can write / read objects from this store in a single line.
		// Once created you should store it and when needed again in other file recover it again
		guard let w = wallet else {
			print("Error finding wallet object")
			return
		}
		
		let cacheService = WalletCacheService()
		let _ = cacheService.deleteCacheAndKeys()
		let saveResult = cacheService.cache(wallet: w)
		print("Wallet saved to encrypted file: \(saveResult)")
	}
}
