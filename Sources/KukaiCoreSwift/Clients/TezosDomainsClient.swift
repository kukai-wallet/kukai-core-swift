//
//  TezosDomainsClient.swift
//  
//
//  Created by Simon Mcloughlin on 15/10/2021.
//

import Foundation
import Combine

/**
 A client class allowing integration with the tezos domains GraphQL API. See more here: https://tezos.domains/
 */
public class TezosDomainsClient {
	
	/// The networking service used to fire requests
	private let networkService: NetworkService
	
	/// The config used for URL's and logging
	private let config: TezosNodeClientConfig
	
	
	
	
	
	// MARK: - Init
	
	/**
	Init a `TezosDomainsClient` with a `NetworkService` and a `TezosNodeClientConfig`.
	- parameter networkService: `NetworkService` used to manage network communication.
	- parameter config: `TezosNodeClientConfig` used to apss in settings.
	*/
	public init(networkService: NetworkService, config: TezosNodeClientConfig) {
		self.networkService = networkService
		self.config = config
	}
	
	
	
	
	
	// MARK: - Public functions
	
	/**
	 Request a domain (if it exists) for the given tezos address
	 - parameters address: A tezos address
	 - returns: A Publisher containing a graphQL object or an error
	 */
	public func getDomainFor(address: String) -> AnyPublisher<GraphQLResponse<TezosDomainsDomainResponse>, ErrorResponse> {
		let queryDict = ["query": "query {reverseRecord(address: \"\(address)\") {id, address, owner, expiresAtUtc, domain { name, address}}}"]
		let data = try? JSONEncoder().encode(queryDict)
		var url = self.config.tezosDomainsURL
		
		// Temp workaround to make stubbing easier, as only 2 GraphQL requests in package
		if Thread.main.isRunningXCTest {
			url.appendPathComponent("domain")
		}
		
		return self.networkService.request(url: url, isPOST: true, withBody: data, forReturnType: GraphQLResponse<TezosDomainsDomainResponse>.self)
	}
	
	/**
	 Request a tezos address tied to a tezos-domain
	 - parameters domain: A tezos domain owned by a tezos address
	 - returns: A Publisher containing a graphQL object or an error
	 */
	public func getAddressFor(domain: String) -> AnyPublisher<GraphQLResponse<TezosDomainsAddressResponse>, ErrorResponse> {
		let queryDict = ["query": "query {domain(name: \"\(domain)\") { name, address }}"]
		let data = try? JSONEncoder().encode(queryDict)
		var url = self.config.tezosDomainsURL
		
		// Temp workaround to make stubbing easier, as only 2 GraphQL requests in package
		if Thread.main.isRunningXCTest {
			url.appendPathComponent("address")
		}
		
		return self.networkService.request(url: url, isPOST: true, withBody: data, forReturnType: GraphQLResponse<TezosDomainsAddressResponse>.self)
	}
	
	/**
	 Similar to `getDomainFor(address: String)` but allows for bulk fetching
	 - parameters addresses: An array of tezos addresses
	 - returns: A Publisher containing a graphQL object or an error
	 */
	public func getDomainsFor(addresses: [String]) -> Future<[String: GraphQLResponse<TezosDomainsDomainResponse>], ErrorResponse> {
		var bag = Set<AnyCancellable>()
		var publishers: [AnyPublisher<GraphQLResponse<TezosDomainsDomainResponse>, ErrorResponse>] = []
		for address in addresses {
			publishers.append(self.getDomainFor(address: address))
		}
		
		return Future<[String: GraphQLResponse<TezosDomainsDomainResponse>], ErrorResponse> { promise in
			Publishers.MergeMany(publishers)
				.collect()
				.sink { error in
					promise(.failure(error))
					
				} onSuccess: { domains in
					var dict: [String: GraphQLResponse<TezosDomainsDomainResponse>] = [:]
					for domain in domains {
						guard let address = domain.data?.reverseRecord?.address else {
							continue
						}
						
						dict[address] = domain
					}
					
					promise(.success(dict))
					bag.removeAll()
				}
				.store(in: &bag)
		}
	}
	
	/**
	 Similar to `getAddressFor(domain: String)` but allows for bulk fetching
	 - parameters domains: An array of tezos domain owned by a tezos addresses
	 - returns: A Publisher containing a graphQL object or an error
	 */
	public func getAddressesFor(domains: [String]) -> Future<[String: String], ErrorResponse> {
		var bag = Set<AnyCancellable>()
		var publishers: [AnyPublisher<GraphQLResponse<TezosDomainsAddressResponse>, ErrorResponse>] = []
		for domain in domains {
			publishers.append(self.getAddressFor(domain: domain))
		}
		
		return Future<[String: String], ErrorResponse> { promise in
			Publishers.MergeMany(publishers)
				.collect()
				.sink { error in
					promise(.failure(error))
					
				} onSuccess: { domains in
					var dict: [String: String] = [:]
					for domain in domains {
						guard let dom = domain.data?.domain.name, let address = domain.data?.domain.address else {
							continue
						}
						
						dict[dom] = address
					}
					
					promise(.success(dict))
					bag.removeAll()
				}
				.store(in: &bag)
		}
	}
}
