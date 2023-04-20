//
//  TezosDomains.swift
//  
//
//  Created by Simon Mcloughlin on 15/10/2021.
//

import Foundation

/// Response object wrapper for querying an address
public struct TezosDomainsAddressResponse: Codable {
	
	/// Domain object containing details about the domain
	public let domain: TezosDomainsDomain
	
	/// Default init
	public init(domain: TezosDomainsDomain) {
		self.domain = domain
	}
}

/// Domain object containing details about the domain
public struct TezosDomainsDomain: Codable {
	
	/// The domain name e.g. example.tez
	public let name: String
	
	/// The Tezos address that the domain points too
	public let address: String
	
	/// Default init
	public init(name: String, address: String) {
		self.name = name
		self.address = address
	}
}

/// Response object wrapper for querying a reverse record
public struct TezosDomainsDomainResponse: Codable {
	
	/// Object containing all the info of the record
	public let reverseRecord: TezosDomainsReverseRecord?
	
	/// Helper to extract the domain name more easily
	public func domain() -> String? {
		guard let domain = reverseRecord?.domain.name else {
			return nil
		}
		
		return domain
	}
	
	/// Default init
	public init(reverseRecord: TezosDomainsReverseRecord?) {
		self.reverseRecord = reverseRecord
	}
}

/// Object containing all the info of the tezos domains record
public struct TezosDomainsReverseRecord: Codable {
	
	/// Uniquie id of the domain
	public let id: String
	
	/// The address that the domain points too
	public let address: String
	
	/// The address that owns the domain
	public let owner: String
	
	/// Expiration date
	public let expiresAtUtc: String
	
	/// The domain object continaing the name and address
	public let domain: TezosDomainsDomain
	
	/// Default init
	public init(id: String, address: String, owner: String, expiresAtUtc: String, domain: TezosDomainsDomain) {
		self.id = id
		self.address = address
		self.owner = owner
		self.expiresAtUtc = expiresAtUtc
		self.domain = domain
	}
}
