//
//  TezosDomainsDomainResponse.swift
//  
//
//  Created by Simon Mcloughlin on 15/10/2021.
//

import Foundation

public struct TezosDomainsDomainResponse: Codable {
	public let reverseRecord: TezosDomainsReverseRecord?
	
	public func domain() -> String? {
		guard let domain = reverseRecord?.domain.name else {
			return nil
		}
		
		return domain
	}
}

public struct TezosDomainsReverseRecord: Codable {
	public let id: String
	public let address: String
	public let owner: String
	public let expiresAtUtc: String
	public let domain: TezosDomainsDomain
}
