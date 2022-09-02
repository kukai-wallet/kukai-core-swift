//
//  SceneDelegate.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 22/06/2021.
//

import UIKit
import KukaiCoreSwift
import KukaiCryptoSwift
import CustomAuth
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?
	var bag = Set<AnyCancellable>()

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
		// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
		// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
		guard let _ = (scene as? UIWindowScene) else { return }
	}

	func sceneDidDisconnect(_ scene: UIScene) {
		// Called as the scene is being released by the system.
		// This occurs shortly after the scene enters the background, or when its session is discarded.
		// Release any resources associated with this scene that can be re-created the next time the scene connects.
		// The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
		// Called when the scene has moved from an inactive state to an active state.
		// Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
		
		experiment()
	}

	func sceneWillResignActive(_ scene: UIScene) {
		// Called when the scene will move from an active state to an inactive state.
		// This may occur due to temporary interruptions (ex. an incoming phone call).
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		// Called as the scene transitions from the background to the foreground.
		// Use this method to undo the changes made on entering the background.
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		// Called as the scene transitions from the foreground to the background.
		// Use this method to save data, release shared resources, and store enough scene-specific state information
		// to restore the scene back to its current state.
	}
	
	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		guard let url = URLContexts.first?.url else {
			return
		}
		
		CustomAuth.handle(url: url)
	}
	
	func experiment() {
		
		print("Processing ...")
		
		ClientsAndData.shared.tzktClient.estimateLastAndNextReward(forAddress: "tz1QoUmcycUDaFGvuju2bmTSaCqQCMEpRcgs", baker: TzKTAddress(alias: "Bake Nug", address: "tz1fwnfJNgiDACshK9avfRfFbMaXrs3ghoJa")) { result in
			print("Result: \(result)")
			
			switch result {
				case .success(let obj):
					print("Success: \(obj)")
					
				case .failure(let error):
					print("Error: \(error)")
			}
		}
	}
}

/*
// ==================================================
// 			Activate a faucet account
// ==================================================

 let newWallet = LinearWallet(withMnemonic: "", passphrase: "")
 print("newWallet: \(newWallet?.address)")
 
 let operations = [OperationActivateAccount(wallet: newWallet!, andSecret: "")]
 ClientsAndData.shared.tezosNodeClient.send(operations: operations, withWallet: newWallet!) { (result) in
	switch result {
		case .success(let string):
			print("\n\nAPPLICATION - SEND SUCCESS: \(string)")
 
		case .failure(let error):
			print("\n\nAPPLICATION - SEND FAILURE: \(error)")
	}
 }
*/


/*
let maxAmountMinusMutez = XTZAmount(fromNormalisedAmount: "", decimalPlaces: 6) ?? .zero()

let operations = OperationFactory.sendOperation(maxAmountMinusMutez, of: .xtz(), from: newWallet!.address, to: "")
ClientsAndData.shared.tezosNodeClient.estimate(operations: operations, withWallet: newWallet!, receivedSuggestedGas: false) { (result) in
	switch result {
		case .success(let ops):
			
			var operations = ops
			let last = (operations.last as? OperationTransaction)
			let allFees = ops.map({ $0.operationFees.allFees() }).reduce(.zero(), +)
			let newAmount = (XTZAmount(fromRpcAmount: last?.amount ?? "0") ?? .zero()) - allFees
			
			last?.amount = newAmount.rpcRepresentation
			
			if let l = last {
				operations.removeLast()
				operations.append(l)
			}
			
			ClientsAndData.shared.tezosNodeClient.send(operations: operations, withWallet: newWallet!) { (result) in
				switch result {
					case .success(let string):
						print("\n\nAPPLICATION - SEND SUCCESS: \(string)")
						
					case .failure(let error):
						print("\n\nAPPLICATION - SEND FAILURE: \(error)")
				}
			}
			
		case .failure(let error):
			print("\n\nAPPLICATION - ESTIMATE FAILURE: \(error)")
	}
}
*/
