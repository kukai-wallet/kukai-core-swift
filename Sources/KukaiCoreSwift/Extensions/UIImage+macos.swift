//
//  UIImage+macos.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 16/12/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

#if os(macOS)
import Cocoa

/// Create "UIImage" as typealias of NSImage
public typealias UIImage = NSImage

/// Create standard UIImage properties and methods
extension NSImage {
	public var cgImage: CGImage? {
		var proposedRect = CGRect(origin: .zero, size: size)
		
		return cgImage(forProposedRect: &proposedRect,
					   context: nil,
					   hints: nil)
	}
	
	public convenience init?(named name: String) {
		self.init(named: Name(name))
	}
}
#endif
