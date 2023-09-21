//
//  OperationMetadata.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 20/08/2020.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// Structure representing the metadata needed by `Operation`'s in order to comply with the RPC standards
public struct OperationMetadata: Codable {
	
	/// The public key of the account managing the sender of this `Operation`
	public let managerKey: String?
	
	/// The current counter used by this account on the network. All future `Operation`'s need to be 1 higher
	public let counter: Int
	
	/// The current Tezos network chainID to use for `Operation`'s
	public let chainID: String
	
	/// The current branch used by the head block, used for estiamting and running preapply, to ensure the latest state information is available
	public let branch: String
	
	/// The current Tezos network protocol to use for `Operation`'s
	public let `protocol`: String
	
	/**
	Create an OperationMetadata
	- parameter managerKey: The public key of the account managing the sender of this `Operation`
	- parameter counter: The current counter used by this account on the network. All future `Operation`'s need to be 1 higher
	- parameter blockchainHead: Decoded response of the blockchainHead, containing only the pieces we need
	*/
	public init(managerKey: String?, counter: Int, blockchainHead: BlockchainHead) {
		self.managerKey = managerKey
		self.counter = counter
		self.chainID = blockchainHead.chainID
		self.branch = blockchainHead.hash
		self.protocol = blockchainHead.protocol
	}
}
