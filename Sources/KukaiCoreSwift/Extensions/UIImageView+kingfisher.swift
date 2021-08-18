//
//  File.swift
//  
//
//  Created by Simon Mcloughlin on 18/08/2021.
//

import UIKit
import Kingfisher

public extension UIImageView {
	
	func setKuakiImage(withURL url: URL?, downSampleStandardImage downSample: (width: Int, height: Int)?) {
		guard let url = url else {
			return
		}
		
		let fileExtension = url.absoluteString.components(separatedBy: ".").last ?? ""
		var processors: [KingfisherOptionsInfoItem] = []
		
		if fileExtension == "svg" {
			processors = [.processor(SVGImgProcessor())]
			
		} else if fileExtension == "gif" {
			// Do nothing, all handled by default
			processors = []
			
		} else if let size = downSample {
			// Only possible on non SVG's and non gifs, like jpeg, png etc
			processors = [.processor( DownsamplingImageProcessor(size: CGSize(width: size.width, height: size.height)))]
		}
		
		kf.setImage(with: url, options: processors)
	}
}
