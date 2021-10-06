//
//  MockTorus.swift
//  
//
//  Created by Simon Mcloughlin on 12/07/2021.
//

import UIKit
//import TorusSwiftDirectSDK
//import TorusUtils
//import PromiseKit
//import FetchNodeDetails
//import BestLogger

/*
public class MockTorusSwiftDirectSDK: TorusSwiftDirectSDK {
	
	override open func triggerLogin(controller: UIViewController? = nil, browserType: URLOpenerTypes = .sfsafari, modalPresentationStyle: UIModalPresentationStyle = .fullScreen) -> Promise<[String : Any]> {
		guard let verifierType = self.subVerifierDetails.first?.loginProvider else {
			fatalError("can't find verifier")
		}
		
		let (tempPromise, seal) = Promise<[String:Any]>.pending()
		
		if verifierType == .apple  { // Apple
			seal.fulfill([
				"privateKey": MockConstants.linearWalletSecp256k1.privateKey,
				"publicAddress": "0x6A6b215e489Cb563e421fD94E21cBC5178AB72F9",
				"userInfo": [
					"email": "blah@privaterelay.appleid.com",
					"nickname": "blah",
					"picture": "https://www.redditstatic.com/avatars/avatar_default_06_0DD3BB.png",
					"name": "Test McTestface",
					"sub": "apple|blah.blahblahblah.blah",
					"email_verified": "true",
					"updated_at": "2021-07-12T10:48:21.666Z"
				]
			])
			
		} else if verifierType == .twitter { // Twitter
			seal.fulfill([
				"privateKey": MockConstants.linearWalletSecp256k1.privateKey,
				"publicAddress": "0x97cc326c49C288710883D415d20b00D415d20b00",
				"userInfo": [
					"email": "testy@domain.com",
					"picture": "https://www.redditstatic.com/avatars/avatar_default_06_0DD3BB.png",
					"updated_at": "2021-07-12T10:49:56.465Z",
					"sub": "twitter|123456789",
					"name": "Test McTestface",
					"nickname": "testy"
				]
			])
			
		} else if verifierType == .reddit { // Reddit
			seal.fulfill([
				"privateKey": MockConstants.linearWalletSecp256k1.privateKey,
				"publicAddress": "0xf2f31e21fA3D60DC19feF2CB20804EF2CB20804EF",
				"userInfo": [
					"name": "testyMcTestface",
					"icon_img": "https://www.redditstatic.com/avatars/avatar_default_06_0DD3BB.png",
					"updated_at": "2021-07-12T10:49:56.465Z",
				]
			])
			
		} else {
			fatalError("Invalid verifier")
		}
		
		return tempPromise
	}
}

class MockFetchNodeDetails: FetchNodeDetails {
	
	override func getNodeDetails() -> NodeDetails {
		return NodeDetails(_currentEpoch: "13246798", _nodeListAddress: "", _torusNodeEndpoints: [""], _torusIndexes: [123], _torusNodePub: [TorusNodePub(_X: "", _Y: "")], _updated: true)
	}
}

class MockTorusUtils: TorusUtils {
	
	override func getPublicAddress(endpoints: Array<String>, torusNodePubs: Array<TorusNodePub>, verifier: String, verifierId: String, isExtended: Bool) -> Promise<[String : String]> {
		let (tempPromise, seal) = Promise<[String:String]>.pending()
		
		seal.fulfill([
			"pub_key_X": MockConstants.linearWalletSecp256k1.publicKey,
			"pub_key_Y": MockConstants.linearWalletSecp256k1.publicKey
		])
		
		return tempPromise
	}
}
*/
