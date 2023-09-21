//
//  SignalrStructs.swift
//  
//
//  Created by Simon Mcloughlin on 26/08/2021.
//

import Foundation

/// Object for sending a request through SignalR to listen to operations for a given account
public struct OperationSubscription: Codable {
	let address: String
	let types: String
}

/// Object received through SingnalR when an operation has been recevied
struct OperationSubscriptionResponse: Decodable {
	let type: Int
	let state: Int
	let data: [TzKTTransaction]?
}

/// Object for sending a request through SignalR to listen to changes to a given acocunt (e.g. XTZ balance changes, delegation changes etc)
struct AccountSubscription: Codable {
	let addresses: [String]
}

/// Object received through SingnalR when an account change has been received
struct AccountSubscriptionResponse: Decodable {
	let type: Int
	let state: Int
	let data: [AccountSubscriptionAccount]?
}

/// (temporary) Inner Object received through SingnalR when an account change has been received
struct AccountSubscriptionAccount: Decodable {
	let type: String
	let address: String
}
