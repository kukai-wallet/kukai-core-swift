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
	case unavailable
	case none
	case touchID
	case faceID
}

/// Enum used to get details about the current device's capabilities
public enum CurrentDevice {
	
	/// Is the current device a simulator
	public static var isSimulator: Bool {
		#if targetEnvironment(simulator)
		return true
		#else
		return false
		#endif
	}
	
	// Check what type of biometrics is available to the app. Will return .none if user has opted to not give permission
	public static func biometricTypeAuthorized() -> BiometricType {
		let authContext = LAContext()
		var error: NSError?
		
		guard authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
			if error?.code == -7 {
				return .unavailable // User has not setup biometrics on their device
			} else {
				return .none // (code == -6) = User has denied access
			}
		}
		
		if #available(iOS 11.0, *) {
			switch authContext.biometryType {
				case .none:
					return .none
				case .touchID:
					return .touchID
				case .faceID:
					return .faceID
				default:
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
				default:
					return .none
			}
		}
		
		return authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) ? .touchID : .none
	}
}
