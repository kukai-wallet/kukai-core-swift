//
//  OSLogs+categories.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 17/08/2020.
//

import Foundation
import os.log

/// Extension to OSLog to create some custom categories for logging
extension OSLog {
	private static var subsystem = Bundle.main.bundleIdentifier ?? "app.kukai.kukai-core-swift"
	
	static let kukaiCoreSwift = OSLog(subsystem: subsystem, category: "KukaiCoreSwift")
	static let kukaiCoreSwiftError = OSLog(subsystem: subsystem, category: "KukaiCoreSwift-error")
	static let keychain = OSLog(subsystem: subsystem, category: "KukaiCorSwifte-keychain")
	static let network = OSLog(subsystem: subsystem, category: "KukaiCoreSwift-network")
	static let bcd = OSLog(subsystem: subsystem, category: "BetterCallDev")
	static let tzkt = OSLog(subsystem: subsystem, category: "TzKT")
	static let taquitoService = OSLog(subsystem: subsystem, category: "TaquitoService")
	static let torus = OSLog(subsystem: subsystem, category: "Torus")
	static let ledger = OSLog(subsystem: subsystem, category: "Ledger")
}
