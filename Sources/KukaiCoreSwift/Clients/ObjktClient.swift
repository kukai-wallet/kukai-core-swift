//
//  ObjktClient.swift
//  
//
//  Created by Simon Mcloughlin on 25/05/2023.
//

import Foundation

public class ObjktClient {
	
	/// The networking service used to fire requests
	private let networkService: NetworkService
	
	/// The config used for URL's and logging
	private let config: TezosNodeClientConfig
	
	private let collectionsQuery_maxPage = 500
	private var collectionsQuery_pageCount = 0
	
	private static let collectionCacheKey = "objkt-collection-cache-key"
	private static let tokenCacheKey = "objkt-token-cache-key"
	
	public var collections: [String: ObjktCollection]
	public var tokens: [String: ObjktTokenReponse]
	
	
	
	
	// MARK: - Init
	
	/**
	 Init a `ObjktClient` with a `NetworkService` and a `TezosNodeClientConfig`.
	 - parameter networkService: `NetworkService` used to manage network communication.
	 - parameter config: `TezosNodeClientConfig` used to apss in settings.
	 */
	public init(networkService: NetworkService, config: TezosNodeClientConfig) {
		self.networkService = networkService
		self.config = config
		
		collections = DiskService.read(type: [String: ObjktCollection].self, fromFileName: ObjktClient.collectionCacheKey) ?? [:]
		tokens = DiskService.read(type: [String: ObjktTokenReponse].self, fromFileName: ObjktClient.collectionCacheKey) ?? [:]
	}
	
	
	
	// MARK: - Public single functions
	
	public func unresolvedCollections(addresses: [String]) -> [String] {
		var unresolved: [String] = []
		for add in addresses {
			if collections[add] == nil {
				unresolved.append(add)
			}
		}
		
		return unresolved
	}
	
	public func resolveCollectionsAll(addresses: [String], completion: @escaping ((Result<Bool, KukaiError>) -> Void)) {
		let leftOfSearch = (collectionsQuery_pageCount * collectionsQuery_maxPage)
		var rightOfSearch = (leftOfSearch + collectionsQuery_maxPage)
		if rightOfSearch > addresses.count {
			rightOfSearch = addresses.count
		}
		
		let addressSlice = addresses[leftOfSearch..<rightOfSearch]
		
		resolveCollectionsPage(addresses: addressSlice) { [weak self] result in
			guard let res = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			self?.processCollectionsIntoCache(res: res)
			
			let limit = self?.collectionsQuery_maxPage ?? 500
			let adjustedPageCount = (self?.collectionsQuery_pageCount ?? 0) + 1
			
			if addresses.count > (limit * adjustedPageCount) {
				self?.collectionsQuery_pageCount += 1
				self?.resolveCollectionsAll(addresses: addresses, completion: completion)
				
			} else {
				self?.collectionsQuery_pageCount = 0
				let _ = DiskService.write(encodable: self?.collections, toFileName: ObjktClient.collectionCacheKey)
				completion(Result.success(true))
			}
		}
	}
	
	private func processCollectionsIntoCache(res: GraphQLResponse<ObjktCollections>) {
		guard let data = res.data else {
			return
		}
		
		for item in data.fa {
			collections[item.contract] = item
		}
	}
	
	
	// MARK: - Public single functions
	
	public func resolveCollectionsPage(addresses: ArraySlice<String>, completion: @escaping ((Result<GraphQLResponse<ObjktCollections>, KukaiError>) -> Void)) {
		var addressArray = ""
		for add in addresses {
			addressArray += "\"\(add)\","
		}
		
		let queryDict = ["query": "query { fa(where: {contract: {_in: [\(addressArray)] }}) { contract, name, logo }}"]
		let data = try? JSONEncoder().encode(queryDict)
		
		self.networkService.request(url: self.config.objktApiURL, isPOST: true, withBody: data, forReturnType: GraphQLResponse<ObjktCollections>.self, completion: completion)
	}
	
	public func resolveToken(address: String, tokenId: Int, completion: @escaping ((Result<GraphQLResponse<ObjktTokenReponse>, KukaiError>) -> Void)) {
		var query = """
		query {
			token(where: {fa_contract: {_eq: "\(address)"}, token_id: {_eq: "\(tokenId)"}}) {
				highest_offer,
				lowest_ask,
				metadata,
				name,
				attributes {
					attribute {
						name,
						value,
						attribute_counts(where: {fa_contract: {_eq: "\(address)"}}) {
							editions
						}
					}
				}
			}
			event(
				where: {token: {fa_contract: {_eq: "\(address)"}, token_id: {_eq: "\(tokenId)"}}}
				order_by: {level: asc, timestamp: desc}
				limit: 1
			) {
				price_xtz
			}
			fa(where: {contract: {_eq: "\(address)"}}) {
				editions,
				floor_price
			}
		}
		"""
		
		query = query.replacingOccurrences(of: "\n", with: "")
		query = query.replacingOccurrences(of: "\t", with: "")
		
		let data = try? JSONEncoder().encode(["query": query])
		
		
		self.networkService.request(url: self.config.objktApiURL, isPOST: true, withBody: data, forReturnType: GraphQLResponse<ObjktTokenReponse>.self) { [weak self] result in
			guard let res = try? result.get() else {
				completion(Result.failure(result.getFailure()))
				return
			}
			
			self?.tokens["\(address):\(tokenId)"] = res.data
			let _ = DiskService.write(encodable: self?.tokens, toFileName: ObjktClient.tokenCacheKey)
			completion(Result.success(res))
		}
	}
	
	public func tokenResponse(forAddress: String, tokenId: Int) -> ObjktTokenReponse? {
		return tokens["\(forAddress):\(tokenId)"]
	}
	
	public func deleteCache() {
		self.collections = [:]
		self.tokens = [:]
		
		let _ = DiskService.delete(fileName: ObjktClient.collectionCacheKey)
		let _ = DiskService.delete(fileName: ObjktClient.tokenCacheKey)
	}
}
