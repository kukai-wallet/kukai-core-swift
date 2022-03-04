//
//  NonFungibleChildTableViewController.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 10/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import UIKit
import KukaiCoreSwift
import AVFoundation

class NonFungibleChildTableViewController: UITableViewController {
	
	var parentNFT: Token? = nil
	let mediaProxyService = MediaProxyService()
	
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
			MediaProxyService.load(url: nft.displayURL, to: ftCell.iconView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: ftCell.iconView.frame.size)
			ftCell.label.text = nft.name
			ftCell.desc.text = nft.description
		}
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let selectedNFT = parentNFT?.nfts?[indexPath.row] {
			mediaProxyService.getMediaType(fromFormats: selectedNFT.metadata?.formats ?? [], orURL: selectedNFT.displayURL) { result in
				guard let res = try? result.get() else {
					print("Error: \(result.getFailure())")
					return
				}
				
				if res == .image {
					self.performSegue(withIdentifier: "display-image", sender: selectedNFT)
				} else {
					self.performSegue(withIdentifier: "display-video", sender: selectedNFT)
				}
			}
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let selectedNFT = sender as? NFT else {
			print("can't parse sender as NFT")
			return
		}
		
		if segue.identifier == "display-video", let playerController = segue.destination as? DisplayVideoViewController {
			playerController.contentURL = selectedNFT.artifactURL == nil ? selectedNFT.displayURL : selectedNFT.artifactURL
			
		} else if segue.identifier == "display-image", let imageController = segue.destination as? DisplayImageViewController, let contentURL = selectedNFT.displayURL {
			imageController.contentURL = contentURL
			
		} else {
			print("Unable to parse NFT data")
		}
	}
}
