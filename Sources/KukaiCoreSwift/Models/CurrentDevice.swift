//
//  CurrentDevice.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 22/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import LocalAuthentication


public enum BiometricType {
	case none
	case touchID
	case faceID
}

/// Enum used to get details about the current device's capabilities
public enum CurrentDevice {
	
	/// Does the current device have a secure enclave
	public static var hasSecureEnclave: Bool {
		return !isSimulator && biometricTypeSupported() != .none
	}
	
	/// Is the current device a simulator
	public static var isSimulator: Bool {
		return TARGET_OS_SIMULATOR == 1
	}
	
	// Check what type of biometrics is available to the app. Will return .none if user has opted to not give permission
	public static func biometricTypeAuthorized() -> BiometricType {
		let authContext = LAContext()
		var error: NSError?
		
		guard authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
			return .none
		}
		
		if #available(iOS 11.0, *) {
			switch authContext.biometryType {
				case .none:
					return .none
				case .touchID:
					return .touchID
				case .faceID:
					return .faceID
				@unknown default:
					return .none
			}
		}
		
		return authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touchID : .none
	}
	
	// Check what type of biometrics is available to the app. Will return with the value indicating what capabilities the device has, ignoring whther user has given permission
	public static func biometricTypeSupported() -> BiometricType {
		let authContext = LAContext()
		
		if #available(iOS 11.0, *) {
			switch authContext.biometryType {
				case .none:
					return .none
				case .touchID:
					return .touchID
				case .faceID:
					return .faceID
				@unknown default:
					return .none
			}
		}
		
		return authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touchID : .none
	}
}
