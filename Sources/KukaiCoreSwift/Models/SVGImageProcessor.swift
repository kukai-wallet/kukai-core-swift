//
//  SVGImageProcessor.swift
//  
//
//  Created by Simon Mcloughlin on 18/08/2021.
//

import UIKit
import Kingfisher
import SVGKit

public struct SVGImgProcessor: ImageProcessor {
	
	public var identifier: String = "app.kukai.mobile.webpprocessor"
	
	public func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
		
		switch item {
			case .image(let image):
				return image
				
			case .data(let data):
				let imsvg = SVGKImage(data: data)
				return imsvg?.uiImage
		}
	}
}
