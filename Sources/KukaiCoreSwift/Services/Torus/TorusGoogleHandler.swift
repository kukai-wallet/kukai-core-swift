//
//  TorusGoogleHandler.swift
//  
//
//  Created by Simon Mcloughlin on 04/07/2022.
//

import Foundation
import OSLog



/*
 Notes:
 
 - getLoginURL is called, and that url is opened (in safari for example)
 - SDK listens for the callback, and strips all the parameters off the url, passes those into getUserInfo
 - getUserInfo calls handleLogin
 
	- absolutely no need whatsoever to have a protocol list getUserInfo and handleLogin. First is only always used as a wrapper for the second
 
 - The parameters from handleLogin are ultiamtely passed into getTorsKey or getAggregateKey
 */


public struct TorusGoogleHandler: TorusLoginHandler {
	
	private let nonce: String
	private let state: String?
	private let verifier: TorusVerifier
	
	init(verifier: TorusVerifier) {
		self.nonce = TorusLoginHandler.generateNonce(ofLength: 10)
		self.redirectURL = verifier.redirectURL
		
		let tempState = ["nonce": self.nonce, "redirectUri": self.verifier.redirectURL.absoluteString, "redirectToAndroid": "true"]
		if let jsonData = try? JSONSerialization.data(withJSONObject: tempState, options: .fragmentsAllowed), let str = String(data: jsonData, encoding: .utf8) {
			self.state =  str.toBase64URL()
			
		} else {
			os_log("Unable to create url state variable", log: .torus, type: .error)
			self.state = nil
		}
	}
	
	public func getLoginURL() -> URL? {
		guard let url = URL(string: "https://accounts.google.com/o/oauth2/v2/auth"), let state = self.state else {
			os_log("Unable to create url, either base URL invalid or state variable wasn't created", log: .torus, type: .error)
			return nil
		}
		
		url.appendQueryItem(name: "response_type", value: "id_token+token")
		url.appendQueryItem(name: "client_id", value: self.verifier.clientId)
		url.appendQueryItem(name: "nonce", value: self.nonce)
		url.appendQueryItem(name: "redirect_uri", value: self.verifier.redirectURL)
		url.appendQueryItem(name: "scope", value: "profile+email+openid")
		url.appendQueryItem(name: "state", value: state)
		
		return url
	}
	
	public func handleLogin(responseURL: URL, networkService: NetworkService, completion: @escaping ((Result<[String: Any], KukaiError>))) {
		guard let params = responseURL.queryParams(), let accessToken = params["access_token"], let idToken = params["id_token"], let url = URL(string: "https://www.googleapis.com/userinfo/v2/me") else {
			completion(Result.failure(KukaiError.internalApplicationError(error: TorusLoginError.handleLoginRecievedInvalidParams)))
			return
		}
		
		// re-build networkService so that I can get back the raw data and convert it to [String: Any] for JSON parsing
		networkService.request(url: url, isPOST: false, headers: ["Authorization": "Bearer \(accessToken)"] withBody: nil, forReturnType: [String:], completion: <#T##((Result<Decodable, KukaiError>) -> Void)##((Result<Decodable, KukaiError>) -> Void)##(Result<Decodable, KukaiError>) -> Void#>)
		
		/*
		if let accessToken = responseParameters["access_token"], let idToken = responseParameters["id_token"]{
			var request = makeUrlRequest(url: "https://www.googleapis.com/userinfo/v2/me", method: "GET")
			request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
			self.urlSession.dataTask(.promise, with: request).map{
				try JSONSerialization.jsonObject(with: $0.data) as? [String:Any]
			}.done{ data in
				self.userInfo =  data!
				var newData:[String:Any] = ["userInfo": self.userInfo as Any]
				newData["tokenForKeys"] = idToken
				newData["verifierId"] = self.getVerifierFromUserInfo()
				seal.fulfill(newData)
			}.catch{err in
				seal.reject(CASDKError.accessTokenAPIFailed)
			}
		}else{
			seal.reject(CASDKError.getUserInfoFailed)
		}
		*/
	}
}
