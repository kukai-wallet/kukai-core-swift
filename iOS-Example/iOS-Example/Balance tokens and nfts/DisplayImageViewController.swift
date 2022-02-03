//
//  DisplayImageViewController.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 03/02/2022.
//

import UIKit
import KukaiCoreSwift

class DisplayImageViewController: UIViewController {

	@IBOutlet weak var imageView: UIImageView!
	
	public var contentURL: URL?
	
	override func viewDidLoad() {
        super.viewDidLoad()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		MediaProxyService.load(url: contentURL, to: imageView, fromCache: MediaProxyService.temporaryImageCache(), fallback: UIImage(), downSampleSize: nil)
	}
}
