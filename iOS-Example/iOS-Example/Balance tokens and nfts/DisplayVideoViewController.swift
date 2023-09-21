//
//  DisplayVideoViewController.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 03/02/2022.
//

import UIKit
import AVKit
import KukaiCoreSwift

class DisplayVideoViewController: AVPlayerViewController, AVPlayerViewControllerDelegate {
	
	public var contentURL: URL?
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		delegate = self
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if let cURL = contentURL {
			let player = AVPlayer(url: cURL)
			self.player = player
			self.player?.play()
			
		} else {
			print("Invalid URL")
		}
	}
	
}
