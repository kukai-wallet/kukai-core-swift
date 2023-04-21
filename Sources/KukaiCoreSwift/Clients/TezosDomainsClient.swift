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
	 - parameters url: An optional URL to request, for advanced cases
	 - returns: A Publisher containing a graphQL object or an error
	 */
	public func getDomainFor(address: String, url: URL? = nil) -> AnyPublisher<GraphQLResponse<TezosDomainsDomainResponse>, KukaiError> {
		let queryDict = ["query": "query {reverseRecord(address: \"\(address)\") {id, address, owner, expiresAtUtc, domain { name, address}}}"]
		let data = try? JSONEncoder().encode(queryDict)
		
		return self.networkService.request(url: url ?? self.config.tezosDomainsURL, isPOST: true, withBody: data, forReturnType: GraphQLResponse<TezosDomainsDomainResponse>.self)
	}
	
	/**
	 Request a domain (if it exists) for the given tezos address on both the default mainnet and ghostnet networks
	 - parameters address: A tezos address
	 - returns: A Publisher containing a graphQL object or an error
	 */
	public func getMainAndGhostDomainFor(address: String) -> Future<(mainnet: GraphQLResponse<TezosDomainsDomainResponse>?, ghostnet: GraphQLResponse<TezosDomainsDomainResponse>?), KukaiError> {
		var bag = Set<AnyCancellable>()
		let publishers: [AnyPublisher<Result<GraphQLResponse<TezosDomainsDomainResponse>, KukaiError>, Never>] = [
			getDomainFor(address: address, url: TezosNodeClientConfig.defaultMainnetURLs.tezosDomainsURL).convertToResult(),
			getDomainFor(address: address, url: TezosNodeClientConfig.defaultTestnetURLs.tezosDomainsURL).convertToResult()
		]
		
		return Future<(mainnet: GraphQLResponse<TezosDomainsDomainResponse>?, ghostnet: GraphQLResponse<TezosDomainsDomainResponse>?), KukaiError> { promise in
			Publishers.MergeMany(publishers)
				.collect()
				.sink { error in
					// Never executed, due to `.convertToResult()` returning Never as the error
					
				} onSuccess: { domains in
					var mainnetResult: GraphQLResponse<TezosDomainsDomainResponse>? = nil
					var ghostnetResult: GraphQLResponse<TezosDomainsDomainResponse>? = nil
					
					for res in domains {
						switch res {
							case .success(let gql):
								if gql.data?.reverseRecord?.domain.name.suffix(3) == "tez" {
									mainnetResult = gql
									
								} else if gql.data?.reverseRecord?.domain.name.suffix(3) == "gho" {
									ghostnetResult = gql
								}
								
							case .failure(_):
								let _ = ""
						}
					}
					
					promise(.success((mainnet: mainnetResult, ghostnet: ghostnetResult)))
					bag.removeAll()
				}
				.store(in: &bag)
		}
	}
	
	/**
	 Request a tezos address tied to a tezos-domain
	 - parameters domain: A tezos domain owned by a tezos address
	 - returns: A Publisher containing a graphQL object or an error
	 */
	public func getAddressFor(domain: String) -> AnyPublisher<GraphQLResponse<TezosDomainsAddressResponse>, KukaiError> {
		let queryDict = ["query": "query {domain(name: \"\(domain)\") { name, address }}"]
		let data = try? JSONEncoder().encode(queryDict)
		
		return self.networkService.request(url: self.config.tezosDomainsURL, isPOST: true, withBody: data, forReturnType: GraphQLResponse<TezosDomainsAddressResponse>.self)
	}
	
	/**
	 Similar to `getDomainFor(address: String)` but allows for bulk fetching
	 - parameters addresses: An array of tezos addresses
	 - returns: A Publisher containing a graphQL object or an error
	 */
	public func getDomainsFor(addresses: [String]) -> Future<[String: GraphQLResponse<TezosDomainsDomainResponse>], KukaiError> {
		var bag = Set<AnyCancellable>()
		var publishers: [AnyPublisher<GraphQLResponse<TezosDomainsDomainResponse>, KukaiError>] = []
		for address in addresses {
			publishers.append(self.getDomainFor(address: address))
		}
		
		return Future<[String: GraphQLResponse<TezosDomainsDomainResponse>], KukaiError> { promise in
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
	public func getAddressesFor(domains: [String]) -> Future<[String: String], KukaiError> {
		var bag = Set<AnyCancellable>()
		var publishers: [AnyPublisher<GraphQLResponse<TezosDomainsAddressResponse>, KukaiError>] = []
		for domain in domains {
			publishers.append(self.getAddressFor(domain: domain))
		}
		
		return Future<[String: String], KukaiError> { promise in
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
