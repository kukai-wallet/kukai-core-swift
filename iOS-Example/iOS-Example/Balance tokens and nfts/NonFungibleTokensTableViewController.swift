//
//  NonFungibleTokensTableViewController.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 10/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import UIKit
import KukaiCoreSwift

class NonFungibleTokensTableViewController: UITableViewController {
	
	private var selectedIndex = 0
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }

	// MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return ClientsAndData.shared.account?.nfts.count ?? 0
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "fungibleTokenCell", for: indexPath)
		let token = ClientsAndData.shared.account?.nfts[indexPath.row]
		
		if let ftCell = cell as? FungibleTokenCell {
			MediaProxyService.load(url: token?.thumbnailURL, to: ftCell.iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: ftCell.iconView.frame.size)
			ftCell.label.text = token?.name
		}
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		selectedIndex = indexPath.row
		self.performSegue(withIdentifier: "children", sender: self)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let dest = segue.destination as? NonFungibleChildTableViewController else {
			return
		}
		
		dest.parentNFT = ClientsAndData.shared.account?.nfts[selectedIndex]
	}
}
