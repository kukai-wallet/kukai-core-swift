//
//  AccountViewController.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 10/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import UIKit
import KukaiCoreSwift

class AccountViewController: UIViewController {
	
	@IBOutlet weak var walletLabel: UILabel!
	@IBOutlet weak var balanceLabel: UILabel!
	@IBOutlet weak var fungibleTokenButton: UIButton!
	@IBOutlet weak var nonFungibleTokenButton: UIButton!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		walletLabel.text = ClientsAndData.shared.account?.walletAddress ?? ""
		balanceLabel.text = (ClientsAndData.shared.account?.xtzBalance.normalisedRepresentation ?? "0") + " XTZ"
    }
}
