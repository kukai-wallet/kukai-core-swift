//
//  UIApplication+extensions.swift
//  
//
//  Created by Simon Mcloughlin on 22/12/2021.
//

import UIKit

extension UIApplication {
	
	/// SceneDelegate changed the way we manage windows, and removed `.keyWindow` from UIApplication. This computed var returns this functionlaity by fetching the first scene and its first window, for simpiler apps
	var keyWindow: UIWindow? {
		return UIApplication.shared.connectedScenes
			.filter { $0.activationState == .foregroundActive }
			.first(where: { $0 is UIWindowScene })
			.flatMap({ $0 as? UIWindowScene })?.windows
			.first(where: \.isKeyWindow)
	}
}
