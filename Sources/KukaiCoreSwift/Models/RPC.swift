//
//  RPC.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 19/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import os.log

/**
A generic class representing an RPC call to the Tezos network.
A type must be passed in when creating an instance of this object, this will be used by the network layer to parse the response and detect errors.
*/
public class RPC<T: Decodable> {
	
	// MARK: - Public properties
	
	/// The endpoint that will be added onto the `TezosNodeConfig.primaryNodeURL` to form a full URL for the request
	public let endpoint: String
	
	/// An optional payload for sending HTTP POST requests
	public let payload: Data?
	
	/// The expected response type from the network
	public let responseType: T.Type
	
	/// Computed property to indicate wheter or not this is a POST request
	public var isPost: Bool {
		return payload != nil
	}
	
	
	
	// MARK: - Init
	
	/**
	Init an `RPC` object, to be passed to the network layer to performa  request to the node.
	- parameter endpoint: The endpoint to send the request too.
	- parameter payload: An optional payload for POST requests.
	- parameter responseType: The expected response type from the network.
	*/
	public init(endpoint: String, payload: Data?, responseType: T.Type) {
		self.endpoint = endpoint
		self.payload = payload
		self.responseType = responseType.self
	}
	
	/// Helper function to wrap up `JSONEncoder().encode` and log any errors.
	public static func encodableToData<T: Encodable>(encodable: T) -> Data? {
		do {
			return try JSONEncoder().encode(encodable)
			
		} catch(let error) {
			Logger.kukaiCoreSwift.error("Unable to encode object as string: \(error)")
			return nil
		}
	}
}



// MARK: - Convenience Functions

/// Extension to force a generic type of `String` on a collection of convenience functions, so callers don't need to pass it in
extension RPC where T == String {
	
	/// Creates an RPC to fetch an XTZ balance for a given Address
	public static func xtzBalance(forAddress address: String) -> RPC<String> {
		return RPC<String>(endpoint: "chains/main/blocks/head/context/contracts/\(address)/balance", payload: nil, responseType: String.self)
	}
	
	/// Creates an RPC to fetch a deelgate for a given Address
	public static func getDelegate(forAddress address: String) -> RPC<String> {
		return RPC<String>(endpoint: "chains/main/blocks/head/context/contracts/\(address)/delegate", payload: nil, responseType: String.self)
	}
	
	/// Creates an RPC to fetch the managerKey for a given Address
	public static func managerKey(forAddress address: String) -> RPC<String?> {
		return RPC<String?>(endpoint: "chains/main/blocks/head/context/contracts/\(address)/manager_key", payload: nil, responseType: String?.self)
	}
	
	/// Creates an RPC to fetch the current counter for a given Address
	public static func counter(forAddress address: String) -> RPC<String> {
		return RPC<String>(endpoint: "chains/main/blocks/head/context/contracts/\(address)/counter", payload: nil, responseType: String.self)
	}
	
	/// Creates an RPC to remotely forge an operation
	public static func forge(operationPayload: OperationPayload) -> RPC<String>? {
		guard let payloadData = RPC.encodableToData(encodable: operationPayload) else {
			return nil
		}
		
		return RPC<String>(endpoint: "chains/main/blocks/head/helpers/forge/operations", payload: payloadData, responseType: String.self)
	}
	
	/// Creates an RPC to inject an operation
	public static func inject(signedBytes: String) -> RPC<String>? {
		guard let payloadData = RPC.encodableToData(encodable: signedBytes) else {
			return nil
		}
		
		return RPC<String>(endpoint: "injection/operation", payload: payloadData, responseType: String.self)
	}
}

extension RPC where T == BlockchainHead {
	
	/// Creates an RPC to fetch the HEAD of the blockchain and parse it into an object to extract the pieces we are interested in.
	public static func blockchainHead() -> RPC<BlockchainHead> {
		return RPC<BlockchainHead>(endpoint: "chains/main/blocks/head", payload: nil, responseType: BlockchainHead.self)
	}
	
	/// Creates an RPC to fetch the HEAD of 3 blocks previous and parse it into an object to extract the pieces we are interested in.
	public static func blockchainHeadMinus3() -> RPC<BlockchainHead> {
		return RPC<BlockchainHead>(endpoint: "chains/main/blocks/head~3", payload: nil, responseType: BlockchainHead.self)
	}
}

extension RPC where T == NetworkVersion {
	
	/// Creates an RPC to fetch the details about the version of the network running on the given server.
	public static func networkVersion() -> RPC<NetworkVersion> {
		return RPC<NetworkVersion>(endpoint: "version", payload: nil, responseType: NetworkVersion.self)
	}
}

extension RPC where T == NetworkConstants {
	
	/// Creates an RPC to fetch the network constants for the given server, such as how much mutez it costs per byte of storage, or the maximum allowed gas amount
	public static func networkConstants() -> RPC<NetworkConstants> {
		return RPC<NetworkConstants>(endpoint: "chains/main/blocks/head/context/constants", payload: nil, responseType: NetworkConstants.self)
	}
}

extension RPC where T == [OperationPayload] {
	
	/// Creates an RPC to remotely parse an operation to verify its contents. Function takes in a hash, as it is returned from the forge call. This function will do all the necessary parsing and formatting
	public static func parse(hashToParse: String, metadata: OperationMetadata) -> RPC<[OperationPayload]>? {
		
		// Remove first 32 bytes (64 characters), to remove branch and block hash
		let stringIndex = hashToParse.index(hashToParse.startIndex, offsetBy: 64)
		let stripped = hashToParse[stringIndex..<hashToParse.endIndex]

		// Add 128 zeros (64 zero bytes) for empty signature (its not checked)
		let padded = String(stripped).appending(String(repeating: "0", count: 128))
		
		
		let jsonDictionary = ["operations": [ ["data": padded, "branch": metadata.branch] ]]
		guard let payloadData = RPC.encodableToData(encodable: jsonDictionary) else {
			return nil
		}
		
		return RPC<[OperationPayload]>(endpoint: "chains/main/blocks/head/helpers/parse/operations", payload: payloadData, responseType: [OperationPayload].self)
	}
}

extension RPC where T == [OperationResponse] {
	
	/// Creates an RPC to preapply an operation. This `OperationPayload` must have had its signature and protocol set
	public static func preapply(operationPayload: OperationPayload) -> RPC<[OperationResponse]>? {
		if operationPayload.signature == nil || operationPayload.protocol == nil {
			Logger.kukaiCoreSwift.error("RPC preapply was passed an operationPayload without a signature and/or protocol")
			return nil
		}
		
		guard let payloadData = RPC.encodableToData(encodable: [operationPayload]) else {
			return nil
		}
		
		return RPC<[OperationResponse]>(endpoint: "chains/main/blocks/head/helpers/preapply/operations", payload: payloadData, responseType: [OperationResponse].self)
	}
}

extension RPC where T == OperationResponse {
	
	/// Creates an RPC to estimate an operation
	public static func runOperation(runOperationPayload: RunOperationPayload) -> RPC<OperationResponse>? {
		guard let payloadData = RPC.encodableToData(encodable: runOperationPayload) else {
			return nil
		}
		
		return RPC<OperationResponse>(endpoint: "chains/main/blocks/head/helpers/scripts/run_operation", payload: payloadData, responseType: OperationResponse.self)
	}
}

extension RPC where T == Data {
	
	/// Creates an RPC to fetch a contracts Michelson storage
	public static func contractStorage(contractAddress: String) -> RPC<Data> {
		return RPC<Data>(endpoint: "chains/main/blocks/head/context/contracts/\(contractAddress)/storage", payload: nil, responseType: Data.self)
	}
	
	/// Creates an RPC to fetch the contents of the given big map
	public static func bigMap(id: String) -> RPC<Data> {
		return RPC<Data>(endpoint: "chains/main/blocks/head/context/big_maps/\(id)", payload: nil, responseType: Data.self)
	}
}
