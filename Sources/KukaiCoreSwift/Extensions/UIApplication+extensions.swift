//
//  UIApplication+extensions.swift
//  
//
//  Created by Simon Mcloughlin on 22/12/2021.
//

import UIKit

extension UIApplication {
	
	var keyWindow: UIWindow? {
		return UIApplication.shared.connectedScenes
			.filter { $0.activationState == .foregroundActive }
			.first(where: { $0 is UIWindowScene })
			.flatMap({ $0 as? UIWindowScene })?.windows
			.first(where: \.isKeyWindow)
	}
}
