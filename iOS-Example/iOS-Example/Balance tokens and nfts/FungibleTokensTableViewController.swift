//
//  FungibleTokensTableViewController.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 10/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import UIKit
import KukaiCoreSwift

class FungibleTokensTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

	
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return ClientsAndData.shared.account?.tokens.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fungibleTokenCell", for: indexPath)
		let token = ClientsAndData.shared.account?.tokens[indexPath.row]
		
		if let ftCell = cell as? FungibleTokenCell {
			MediaProxyService.load(url: token?.thumbnailURL, to: ftCell.iconView, fromCache: MediaProxyService.permanentImageCache(), fallback: UIImage(), downSampleSize: ftCell.iconView.frame.size)
			ftCell.label.text = (token?.balance.normalisedRepresentation ?? "0") + " \(token?.symbol ?? "?")"
		}
		
        return cell
    }
}
