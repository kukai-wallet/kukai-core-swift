//
//  Sodium+TezosCrypto.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 17/08/2020.
//

import Foundation
import Sodium

/// Extension to `Sodium`to add a static shared instance, to avoid having to load it into memory frequently
extension Sodium {
	
	public static let shared = Sodium()
}
