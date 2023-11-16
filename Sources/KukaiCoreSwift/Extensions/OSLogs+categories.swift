//
//  OSLogs+categories.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 17/08/2020.
//

import Foundation
import os.log

/// Extension to OSLog to create some custom categories for logging
public extension Logger {
	private static var subsystem = Bundle.main.bundleIdentifier ?? "app.kukai.kukai-core-swift"
	
	static let kukaiCoreSwift = Logger(subsystem: subsystem, category: "KukaiCoreSwift")
	static let walletCache = Logger(subsystem: subsystem, category: "WalletCache")
	static let kukaiCoreSwiftError = Logger(subsystem: subsystem, category: "KukaiCoreSwift-error")
	static let keychain = Logger(subsystem: subsystem, category: "KukaiCoreSwift-keychain")
	static let network = Logger(subsystem: subsystem, category: "KukaiCoreSwift-network")
	static let bcd = Logger(subsystem: subsystem, category: "BetterCallDev")
	static let tzkt = Logger(subsystem: subsystem, category: "TzKT")
	static let taquitoService = Logger(subsystem: subsystem, category: "TaquitoService")
	static let torus = Logger(subsystem: subsystem, category: "Torus")
	static let ledger = Logger(subsystem: subsystem, category: "Ledger")
	
	/// Used by the app importing this library
	static let app = Logger(subsystem: subsystem, category: "app")
}
