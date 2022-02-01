//
//  NonFungibleChildTableViewController.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 10/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import UIKit
import KukaiCoreSwift

class NonFungibleChildTableViewController: UITableViewController {
	
	var parentNFT: Token? = nil
	
    override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		self.navigationItem.title = parentNFT?.name
		self.tableView.reloadData()
	}
	

	// MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return parentNFT?.nfts?.count ?? 0
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "nonFungibleTokenCell", for: indexPath)
		
		guard let nft = parentNFT?.nfts?[indexPath.row] else {
			return UITableViewCell()
		}
		
		if let ftCell = cell as? NonFungibleTokenCell {
			MediaProxyService.load(url: nft.displayURL, to: ftCell.iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: (width: 150, height: 150))
			ftCell.label.text = nft.name
			ftCell.desc.text = nft.description
		}
		
		return cell
	}

}
