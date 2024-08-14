//
//  File.swift
//  
//
//  Created by Simon Mcloughlin on 14/11/2023.
//

import Foundation

/// Container to store groups of WalletMetadata based on type
public class WalletMetadataList: Codable, Hashable {
	public var socialWallets: [WalletMetadata]
	public var hdWallets: [WalletMetadata]
	public var linearWallets: [WalletMetadata]
	public var ledgerWallets: [WalletMetadata]
	public var watchWallets: [WalletMetadata]
	
	public init(socialWallets: [WalletMetadata], hdWallets: [WalletMetadata], linearWallets: [WalletMetadata], ledgerWallets: [WalletMetadata], watchWallets: [WalletMetadata]) {
		self.socialWallets = socialWallets
		self.hdWallets = hdWallets
		self.linearWallets = linearWallets
		self.ledgerWallets = ledgerWallets
		self.watchWallets = watchWallets
	}
	
	public func isEmpty() -> Bool {
		return socialWallets.isEmpty && hdWallets.isEmpty && linearWallets.isEmpty && ledgerWallets.isEmpty && watchWallets.isEmpty
	}
	
	public func firstMetadata() -> WalletMetadata? {
		if socialWallets.count > 0 {
			return socialWallets.first
			
		} else if hdWallets.count > 0 {
			return hdWallets.first
			
		} else if linearWallets.count > 0 {
			return linearWallets.first
			
		} else if ledgerWallets.count > 0 {
			return ledgerWallets.first
			
		} else if watchWallets.count > 0 {
			return watchWallets.first
		}
		
		return nil
	}
	
	public func metadata(forAddress address: String) -> WalletMetadata? {
		for metadata in socialWallets {
			if metadata.address == address { return metadata }
		}
		
		for metadata in hdWallets {
			if metadata.address == address { return metadata }
			
			for childMetadata in metadata.children {
				if childMetadata.address == address { return childMetadata }
			}
		}
		
		for metadata in linearWallets {
			if metadata.address == address { return metadata }
		}
		
		for metadata in ledgerWallets {
			if metadata.address == address { return metadata }
			
			for childMetadata in metadata.children {
				if childMetadata.address == address { return childMetadata }
			}
		}
		
		for metaData in watchWallets {
			if metaData.address == address { return metaData }
		}
		
		return nil
	}
	
	public func parentMetadata(forChildAddress address: String) -> WalletMetadata? {
		for metadata in hdWallets {
			for childMetadata in metadata.children {
				if childMetadata.address == address { return metadata }
			}
		}
		
		return nil
	}
	
	public func update(address: String, with newMetadata: WalletMetadata) -> Bool {
		for (index, metadata) in socialWallets.enumerated() {
			if metadata.address == address { socialWallets[index] = newMetadata; return true }
		}
		
		for (index, metadata) in hdWallets.enumerated() {
			if metadata.address == address { hdWallets[index] = newMetadata; return true }
			
			for (childIndex, childMetadata) in metadata.children.enumerated() {
				if childMetadata.address == address {  hdWallets[index].children[childIndex] = newMetadata; return true }
			}
		}
		
		for (index, metadata) in linearWallets.enumerated() {
			if metadata.address == address { linearWallets[index] = newMetadata; return true }
		}
		
		for (index, metadata) in ledgerWallets.enumerated() {
			if metadata.address == address { ledgerWallets[index] = newMetadata; return true }
			
			for (childIndex, childMetadata) in metadata.children.enumerated() {
				if childMetadata.address == address {  hdWallets[index].children[childIndex] = newMetadata; return true }
			}
		}
		
		for (index, metadata) in watchWallets.enumerated() {
			if metadata.address == address { watchWallets[index] = newMetadata; return true }
		}
		
		return false
	}
	
	public func set(mainnetDomain: TezosDomainsReverseRecord?, ghostnetDomain: TezosDomainsReverseRecord?, forAddress address: String) -> Bool {
		let meta = metadata(forAddress: address)
		
		if let mainnet = mainnetDomain {
			meta?.mainnetDomains = [mainnet]
		}
		
		if let ghostnet = ghostnetDomain {
			meta?.ghostnetDomains = [ghostnet]
		}
		
		if let meta = meta, update(address: address, with: meta) {
			return true
		}
		
		return false
	}
	
	public func set(nickname: String?, forAddress address: String) -> Bool {
		let meta = metadata(forAddress: address)
		meta?.walletNickname = nickname
		
		if let meta = meta, update(address: address, with: meta) {
			return true
		}
		
		return false
	}
	
	public func set(hdWalletGroupName: String, forAddress address: String) -> Bool {
		let meta = metadata(forAddress: address)
		meta?.hdWalletGroupName = hdWalletGroupName
		
		if let meta = meta, update(address: address, with: meta) {
			return true
		}
		
		return false
	}
	
	public func count() -> Int {
		var total = (socialWallets.count + linearWallets.count + watchWallets.count)
		
		for wallet in hdWallets {
			total += (1 + wallet.children.count)
		}
		
		for wallet in ledgerWallets {
			total += (1 + wallet.children.count)
		}
		
		return total
	}
	
	public func addresses() -> [String] {
		var temp: [String] = []
		
		for metadata in socialWallets {
			temp.append(metadata.address)
		}
		
		for metadata in hdWallets {
			temp.append(metadata.address)
			
			for childMetadata in metadata.children {
				temp.append(childMetadata.address)
			}
		}
		
		for metadata in linearWallets {
			temp.append(metadata.address)
		}
		
		for metadata in ledgerWallets {
			temp.append(metadata.address)
			
			for childMetadata in metadata.children {
				temp.append(childMetadata.address)
			}
		}
		
		for metadata in watchWallets {
			temp.append(metadata.address)
		}
		
		return temp
	}
	
	public func allMetadata(onlySeedBased: Bool = false) -> [WalletMetadata] {
		var temp: [WalletMetadata] = []
		
		if !onlySeedBased {
			for metadata in socialWallets {
				temp.append(metadata)
			}
		}
		
		for metadata in hdWallets {
			temp.append(metadata)
		}
		
		for metadata in linearWallets {
			temp.append(metadata)
		}
		
		if !onlySeedBased {
			for metadata in ledgerWallets {
				temp.append(metadata)
			}
		}
		
		if !onlySeedBased {
			for metadata in watchWallets {
				temp.append(metadata)
			}
		}
		
		return temp
	}
	
	public static func == (lhs: WalletMetadataList, rhs: WalletMetadataList) -> Bool {
		return lhs.socialWallets == rhs.socialWallets &&
		lhs.hdWallets == rhs.hdWallets &&
		lhs.linearWallets == rhs.linearWallets &&
		lhs.ledgerWallets == rhs.ledgerWallets &&
		lhs.watchWallets == rhs.watchWallets
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(socialWallets)
		hasher.combine(hdWallets)
		hasher.combine(linearWallets)
		hasher.combine(ledgerWallets)
		hasher.combine(watchWallets)
	}
}





/// Object to store UI related info about wallets, seperated from the wallet object itself to avoid issues merging together
public class WalletMetadata: Codable, Hashable {
	public var address: String
	public var hdWalletGroupName: String?
	public var walletNickname: String?
	public var socialUsername: String?
	public var socialUserId: String?
	public var mainnetDomains: [TezosDomainsReverseRecord]?
	public var ghostnetDomains: [TezosDomainsReverseRecord]?
	public var socialType: TorusAuthProvider?
	public var type: WalletType
	public var children: [WalletMetadata]
	public var isChild: Bool
	public var isWatchOnly: Bool
	public var bas58EncodedPublicKey: String
	public var backedUp: Bool
	public var customDerivationPath: String?
	
	public func hasMainnetDomain() -> Bool {
		return (mainnetDomains ?? []).count > 0
	}
	
	public func hasGhostnetDomain() -> Bool {
		return (ghostnetDomains ?? []).count > 0
	}
	
	public func hasDomain(onNetwork network: TezosNodeClientConfig.NetworkType) -> Bool {
		if network == .mainnet {
			return hasMainnetDomain()
		} else {
			return hasGhostnetDomain()
		}
	}
	
	public func primaryMainnetDomain() -> TezosDomainsReverseRecord? {
		if let domains = mainnetDomains {
			return domains.first
		}
		
		return nil
	}
	
	public func primaryGhostnetDomain() -> TezosDomainsReverseRecord? {
		if let domains = ghostnetDomains {
			return domains.first
		}
		
		return nil
	}
	
	public func primaryDomain(onNetwork network: TezosNodeClientConfig.NetworkType) -> TezosDomainsReverseRecord? {
		if network == .mainnet {
			return primaryMainnetDomain()
		} else {
			return primaryGhostnetDomain()
		}
	}
	
	public func childCountExcludingCustomDerivationPaths() -> Int {
		let excluded = children.filter { $0.customDerivationPath == nil }
		return excluded.count
	}
	
	public init(address: String, hdWalletGroupName: String?, walletNickname: String? = nil, socialUsername: String? = nil, socialUserId: String? = nil, mainnetDomains: [TezosDomainsReverseRecord]? = nil, ghostnetDomains: [TezosDomainsReverseRecord]? = nil, socialType: TorusAuthProvider? = nil, type: WalletType, children: [WalletMetadata], isChild: Bool, isWatchOnly: Bool, bas58EncodedPublicKey: String, backedUp: Bool, customDerivationPath: String?) {
		self.address = address
		self.hdWalletGroupName = hdWalletGroupName
		self.walletNickname = walletNickname
		self.socialUsername = socialUsername
		self.socialUserId = socialUserId
		self.mainnetDomains = mainnetDomains
		self.ghostnetDomains = ghostnetDomains
		self.socialType = socialType
		self.type = type
		self.children = children
		self.isChild = isChild
		self.isWatchOnly = isWatchOnly
		self.bas58EncodedPublicKey = bas58EncodedPublicKey
		self.backedUp = backedUp
		self.customDerivationPath = customDerivationPath
	}
	
	public static func == (lhs: WalletMetadata, rhs: WalletMetadata) -> Bool {
		return lhs.address == rhs.address &&
			lhs.isChild == rhs.isChild &&
			lhs.isWatchOnly == rhs.isWatchOnly
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(address)
		hasher.combine(isChild)
		hasher.combine(isWatchOnly)
	}
}
