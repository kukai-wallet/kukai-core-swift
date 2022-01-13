//
//  NFT.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 10/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// An indiviual NFT (not the parent token/collection) holding a URI to an asset somewhere on the internet
public struct NFT: Codable, Hashable {
	
	/// Each NFT of a token has a unique ID
	public let tokenId: Decimal
	
	/// The address of the FA2 contract that created this NFT
	public let parentContract: String
	
	/// Human readbale name (e.g. "Tezos")
	public let name: String
	
	/// Human readbale symbol (e.g. "XTZ")
	public let symbol: String?
	
	/// Human readable description (e.g. "This NFT was created too...")
	public let `description`: String
	
	/// A URI to the asset the NFT is controlling ownership of
	public let artifactURI: String?
	
	/// A URI used to display media of the artifact
	public let displayURI: URL?
	
	/// A smaller thumbnail used to display meda of the artifact
	public let thumbnailURI: URL?
	
	/// The URL to a cached version of the asset
	public var displayURL: URL? = nil
	
	/// The URL to the cached version of the asset
	public var thumbnailURL: URL? = nil
	
	/**
	Create a more developer friednly `NFT` from a generic `BetterCallDevTokenBalance` object
	- parameter fromBcdBalance: An instance of `BetterCallDevTokenBalance` containing data about an NFT
	*/
	public init(fromBcdBalance bcd: BetterCallDevTokenBalance) {
		tokenId = bcd.token_id
		parentContract = bcd.contract
		name = bcd.name ?? ""
		symbol = bcd.symbol ?? ""
		description = bcd.description ?? ""
		artifactURI = bcd.artifact_uri
		displayURI = URL(string: bcd.display_uri ?? "")
		thumbnailURI = URL(string: bcd.thumbnail_uri ?? "")
	}
	
	/**
	 Create a more developer friednly `NFT` from a generic `TzKTBalance` object
	 - parameter fromTzKTBalance: An instance of `TzKTBalance` containing data about an NFT
	 */
	public init(fromTzKTBalance tzkt: TzKTBalance) {
		tokenId = Decimal(string: tzkt.token.tokenId) ?? 0
		parentContract = tzkt.token.contract.address
		name = tzkt.token.metadata.name
		symbol = tzkt.token.metadata.symbol ?? ""
		description = tzkt.token.metadata.description ?? ""
		artifactURI = tzkt.token.metadata.artifactUri
		displayURI = URL(string: tzkt.token.metadata.displayUri ?? "")
		thumbnailURI = URL(string: tzkt.token.metadata.thumbnailUri ?? "")
	}
}

extension NFT: Identifiable {
	public var id: String {
		parentContract + tokenId.description
	}
}
