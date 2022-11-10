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
	
	/// In order to display in a tablview, the element must be hashable. But in cases where you want to show duplciates (e.g. recents), the computed hash needs to be slightly different
	/// This property can be used as a quick hack a copy of the NFT struct slightly different, without affecting the data
	public var duplicateID: Int = 0
	
	/// The address of the FA2 contract that created this NFT
	public let parentContract: String
	
	/// The human readable alias of the parent contract (e.g. "Mooncakes")
	public let parentAlias: String?
	
	/// The FaVersion of the token contrac
	public let faVersion: FaVersion
	
	/// Get the underlying number of decimal places that this token represents
	public var decimalPlaces: Int
	
	/// Number of duplicate items of this NFT
	public let balance: Decimal
	
	/// Human readbale name (e.g. "Tezos")
	public let name: String
	
	/// Human readbale symbol (e.g. "XTZ")
	public let symbol: String?
	
	/// Human readable description (e.g. "This NFT was created too...")
	public let `description`: String
	
	/// A URI to the asset the NFT is controlling ownership of
	public let artifactURI: URL?
	
	/// A URI used to display media of the artifact
	public let displayURI: URL?
	
	/// A smaller thumbnail used to display meda of the artifact
	public let thumbnailURI: URL?
	
	/// The URL to a cached version of the asset
	public var displayURL: URL? = nil
	
	/// The URL to the cached version of the asset
	public var thumbnailURL: URL? = nil
	
	/// The URL to the cached version of the asset
	public var artifactURL: URL? = nil
	
	/// Metadata object containing useful information about the nft and its contents
	public var metadata: TzKTBalanceMetadata? = nil
	
	
	
	/**
	 Create a more developer friednly `NFT` from a generic `TzKTBalance` object
	 - parameter fromTzKTBalance: An instance of `TzKTBalance` containing data about an NFT
	 */
	public init(fromTzKTBalance tzkt: TzKTBalance) {
		tokenId = Decimal(string: tzkt.token.tokenId) ?? 0
		parentContract = tzkt.token.contract.address
		parentAlias = tzkt.token.contract.alias
		faVersion = tzkt.token.standard
		decimalPlaces = tzkt.token.metadata?.decimalsInt ?? 0
		balance = Decimal(string: tzkt.balance) ?? 1
		name = tzkt.token.metadata?.name ?? ""
		symbol = tzkt.token.metadata?.symbol ?? ""
		description = tzkt.token.metadata?.description ?? ""
		artifactURI = URL(string: tzkt.token.metadata?.artifactUri ?? "")
		displayURI = URL(string: tzkt.token.metadata?.displayUri ?? "")
		thumbnailURI = URL(string: tzkt.token.metadata?.thumbnailUri ?? "")
		metadata = tzkt.token.metadata
		
		artifactURL = MediaProxyService.url(fromUri: artifactURI, ofFormat: .raw)
		displayURL = MediaProxyService.url(fromUri: displayURI, ofFormat: .small)
		thumbnailURL = MediaProxyService.url(fromUri: thumbnailURI, ofFormat: .icon)
	}
	
	/// Confomring to Equatable
	public static func == (lhs: NFT, rhs: NFT) -> Bool {
		return lhs.id == rhs.id
	}
	
	/// Conforming to `Hashable`
	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

extension NFT: Identifiable {
	public var id: String {
		parentContract + tokenId.description
	}
}
