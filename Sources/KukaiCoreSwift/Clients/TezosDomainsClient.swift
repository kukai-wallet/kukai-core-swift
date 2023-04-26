//
//  TezosDomainsClient.swift
//  
//
//  Created by Simon Mcloughlin on 15/10/2021.
//

import Foundation

/**
 A client class allowing integration with the tezos domains GraphQL API. See more here: https://tezos.domains/
 */
public class TezosDomainsClient {
	
	/// The networking service used to fire requests
	private let networkService: NetworkService
	
	/// The config used for URL's and logging
	private let config: TezosNodeClientConfig
	
	/// Object to wrap up a response fomr both networks
	public struct BothNetworkReverseRecord {
		var mainnet: TezosDomainsReverseRecord?
		var ghostnet: TezosDomainsReverseRecord?
		
		public init(mainnet: TezosDomainsReverseRecord?, ghostnet: TezosDomainsReverseRecord?) {
			self.mainnet = mainnet
			self.ghostnet = ghostnet
		}
	}
	
	
	
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
	
	
	
	
	
	// MARK: - Public single functions
	
	public func getDomainFor(address: String, url: URL? = nil, completion: @escaping ((Result<GraphQLResponse<TezosDomainsDomainResponse>, KukaiError>) -> Void)) {
		let queryDict = ["query": "query {reverseRecord(address: \"\(address)\") {id, address, owner, expiresAtUtc, domain { name, address}}}"]
		let data = try? JSONEncoder().encode(queryDict)
		
		self.networkService.request(url: url ?? self.config.tezosDomainsURL, isPOST: true, withBody: data, forReturnType: GraphQLResponse<TezosDomainsDomainResponse>.self, completion: completion)
	}
	
	public func getMainAndGhostDomainFor(address: String, completion: @escaping (( BothNetworkReverseRecord ) -> Void)) {
		let dispatchGroup = DispatchGroup()
		dispatchGroup.enter()
		dispatchGroup.enter()
		
		var returnObj = BothNetworkReverseRecord(mainnet: nil, ghostnet: nil)
		
		getDomainFor(address: address, url: TezosNodeClientConfig.defaultMainnetURLs.tezosDomainsURL) { result in
			guard let res = try? result.get() else {
				dispatchGroup.leave()
				return
			}
			
			returnObj.mainnet = res.data?.reverseRecord
			dispatchGroup.leave()
		}
		
		getDomainFor(address: address, url: TezosNodeClientConfig.defaultTestnetURLs.tezosDomainsURL) { result in
			guard let res = try? result.get() else {
				dispatchGroup.leave()
				return
			}
			
			returnObj.ghostnet = res.data?.reverseRecord
			dispatchGroup.leave()
		}
		
		
		dispatchGroup.notify(queue: .main) {
			completion(returnObj)
		}
	}
	
	public func getAddressFor(domain: String, completion: @escaping ((Result<GraphQLResponse<TezosDomainsAddressResponse>, KukaiError>) -> Void)) {
		let queryDict = ["query": "query {domain(name: \"\(domain)\") { name, address }}"]
		let data = try? JSONEncoder().encode(queryDict)
		
		self.networkService.request(url: self.config.tezosDomainsURL, isPOST: true, withBody: data, forReturnType: GraphQLResponse<TezosDomainsAddressResponse>.self, completion: completion)
	}
	
	
	
	// MARK: - Public bulk functions
	
	public func getDomainsFor(addresses: [String], url: URL? = nil, completion: @escaping ((Result<GraphQLResponse<TezosDomainsDomainBulkResponse>, KukaiError>) -> Void)) {
		var addressArray = ""
		for add in addresses {
			addressArray += "\"\(add)\","
		}
		
		let queryDict = ["query": "query { reverseRecords(where: { address: { in: [\(addressArray)] } }) { items { id, address, owner, expiresAtUtc, domain { name, address }}}}"]
		let data = try? JSONEncoder().encode(queryDict)
		
		self.networkService.request(url: url ?? self.config.tezosDomainsURL, isPOST: true, withBody: data, forReturnType: GraphQLResponse<TezosDomainsDomainBulkResponse>.self, completion: completion)
	}
	
	public func getMainAndGhostDomainsFor(addresses: [String], completion: @escaping (( [String: BothNetworkReverseRecord] ) -> Void)) {
		let dispatchGroup = DispatchGroup()
		dispatchGroup.enter()
		dispatchGroup.enter()
		
		var mainResults: GraphQLResponse<TezosDomainsDomainBulkResponse>? = nil
		var ghostResults: GraphQLResponse<TezosDomainsDomainBulkResponse>? = nil
		
		getDomainsFor(addresses: addresses, url: TezosNodeClientConfig.defaultMainnetURLs.tezosDomainsURL) { result in
			guard let res = try? result.get() else {
				dispatchGroup.leave()
				return
			}
			
			mainResults = res
			dispatchGroup.leave()
		}
		
		getDomainsFor(addresses: addresses, url: TezosNodeClientConfig.defaultTestnetURLs.tezosDomainsURL) { result in
			guard let res = try? result.get() else {
				dispatchGroup.leave()
				return
			}
			
			ghostResults = res
			dispatchGroup.leave()
		}
		
		
		// Map the results into a dictionary of [address: (mainnet + ghostnet)] so that its easier for client code to use walletCache update methods
		dispatchGroup.notify(queue: .global(qos: .background)) {
			var returnObj: [String: BothNetworkReverseRecord] = [:]
			
			let mainnetRecords = mainResults?.data?.reverseRecords?.items.reduce(into: [String: TezosDomainsReverseRecord]()) {
				$0[$1.address] = $1
			} ?? [:]
			
			let ghostnetRecords = ghostResults?.data?.reverseRecords?.items.reduce(into: [String: TezosDomainsReverseRecord]()) {
				$0[$1.address] = $1
			} ?? [:]
			
			for add in addresses {
				returnObj[add] = BothNetworkReverseRecord(mainnet: mainnetRecords[add], ghostnet: ghostnetRecords[add])
			}
			
			DispatchQueue.main.async {
				completion(returnObj)
			}
		}
	}
	
	public func getAddressesFor(domains: [String], completion: @escaping ((Result<GraphQLResponse<TezosDomainsAddressBulkResponse>, KukaiError>) -> Void)) {
		var domainsArray = ""
		for dom in domains {
			domainsArray += "\"\(dom)\","
		}
		
		let queryDict = ["query": "query { domains(where: { name: { in: [\(domainsArray)] } }) { items {name, address}}}"]
		let data = try? JSONEncoder().encode(queryDict)
		
		self.networkService.request(url: self.config.tezosDomainsURL, isPOST: true, withBody: data, forReturnType: GraphQLResponse<TezosDomainsAddressBulkResponse>.self, completion: completion)
	}
}
