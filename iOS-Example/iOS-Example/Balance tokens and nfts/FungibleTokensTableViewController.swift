//
//  FungibleTokensTableViewController.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 10/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import UIKit
import Kingfisher

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
			ftCell.iconView?.kf.setImage(with: token?.icon, options: [.processor( DownsamplingImageProcessor(size: CGSize(width: 30, height: 30)) )])
			ftCell.label.text = (token?.balance.normalisedRepresentation ?? "0") + " \(token?.symbol ?? "?")"
		}
		
        return cell
    }
}
