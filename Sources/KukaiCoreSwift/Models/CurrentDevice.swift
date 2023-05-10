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
	case touch
	case face
}

/// Enum used to get details about the current device's capabilities
public enum CurrentDevice {
	
	/// Does the current device have a secure enclave
	public static var hasSecureEnclave: Bool {
		return !isSimulator && hasBiometrics
	}
	
	/// Is the current device a simulator
	public static var isSimulator: Bool {
		return TARGET_OS_SIMULATOR == 1
	}
	
	/// Does the current device have biometric hardware available
	public static var hasBiometrics: Bool {
		
		let localAuthContext = LAContext()
		var error: NSError?
		
		/// Policies can have certain requirements which, when not satisfied, would always cause
		/// the policy evaluation to fail - e.g. a passcode set, a fingerprint
		/// enrolled with Touch ID or a face set up with Face ID. This method allows easy checking
		/// for such conditions.
		let isValidPolicy = localAuthContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
		
		guard isValidPolicy == true else {
			if error!.code != LAError.biometryNotAvailable.rawValue {
				return true
					
			} else {
				return false
			}
		}
		
		return isValidPolicy
	}
	
	public static func biometricType() -> BiometricType {
		let authContext = LAContext()
		let _ = authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
		switch(authContext.biometryType) {
			case .none:
				return .none
				
			case .touchID:
				return .touch
				
			case .faceID:
				return .face
				
			@unknown default:
				return .none
		}
	}
}
