//
//  LoggingConfig.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 19/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// A struct to control what messages get logged
public struct LoggingConfig {
	
	// MARK: - Public properties
	
	/// Allow `NetworkService` to log failed request data
	var logNetworkFailures: Bool = true
	
	/// Allow `NetworkService` to log successful request data
	var logNetworkSuccesses: Bool = true
	
	
	
	// MARK: - Functions
	
	/// Turn off all logging
	public mutating func allOff() {
		logNetworkFailures = false
		logNetworkSuccesses = false
	}
	
	// Turn on all logging
	public mutating func allOn() {
		logNetworkFailures = true
		logNetworkSuccesses = true
	}
}
