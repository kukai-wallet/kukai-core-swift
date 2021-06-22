//
//  WalletCacheItem.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 21/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation

/// A model to represent a `Wallet` in the encrypted cache
public class WalletCacheItem: Codable {
	
	
	// MARK: - Properties
	
	/// The wallets TZ1 or TZ2 address
	public var address: String
	
	/// A string contianing the mnemonic used to create the wallet
	public var mnemonic: String
	
	/// A string contianing the passphrase used to create the wallet
	public var passphrase: String?
	
	/// The index the wallet should appear in when returned by the cache service. Pureply for UI purposes and continuatity
	public var sortIndex: Int
	
	/// The underlying `WalletType`
	public var type: WalletType
	
	/// The ellipcatcal curve used to genreate the wallet
	public var ellipticalCurve: EllipticalCurve
	
	/// Opitional derivation path, if the `type == .hd`
	public var derivationPath: String?
	
	
	
	// MARK: - Init, decode, encode
	
	/// The Codable CodingKeys
	enum CodingKeys: String, CodingKey {
		case address
		case mnemonic
		case passphrase
		case sortIndex
		case type
		case ellipticalCurve
		case derivationPath
	}
	
	/**
	Create a `WalletCacheItem`
	- Parameter address: String containing TZ1 or TZ2 address of the `Wallet`
	- Parameter mnemonic: String containing the mnemonic used to create the `Wallet`
	- Parameter passphrase: String containing the passphrase used to create the `Wallet`
	- Parameter sortIndex: The sort index the wallet should appear in, when returned
	- Parameter type: The underlying `WalletType` of the stored `Wallet`
	- Parameter ellipticalCurve: The `EllipticalCurve` used to create the wallet
	- Parameter derivationPath: An optional derivationPath is `type == .hd`
	*/
	public init(address: String, mnemonic: String, passphrase: String?, sortIndex: Int, type: WalletType, ellipticalCurve: EllipticalCurve, derivationPath: String?) {
		self.address = address
		self.mnemonic = mnemonic
		self.passphrase = passphrase
		self.sortIndex = sortIndex
		self.type = type
		self.ellipticalCurve = ellipticalCurve
		self.derivationPath = derivationPath
	}
	
	/// Codable: init fromDecoder
	public required init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		address = try container.decode(String.self, forKey: .address)
		mnemonic = try container.decode(String.self, forKey: .mnemonic)
		passphrase = try container.decodeIfPresent(String.self, forKey: .passphrase)
		sortIndex = try container.decode(Int.self, forKey: .sortIndex)
		type = try container.decode(WalletType.self, forKey: .type)
		ellipticalCurve = try container.decode(EllipticalCurve.self, forKey: .ellipticalCurve)
		derivationPath = try container.decodeIfPresent(String.self, forKey: .derivationPath)
	}
	
	/// Codable: encode toEncoder
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(address, forKey: .address)
		try container.encode(mnemonic, forKey: .mnemonic)
		try container.encodeIfPresent(passphrase, forKey: .passphrase)
		try container.encode(sortIndex, forKey: .sortIndex)
		try container.encode(type, forKey: .type)
		try container.encode(ellipticalCurve, forKey: .ellipticalCurve)
		try container.encodeIfPresent(derivationPath, forKey: .derivationPath)
	}
	
	/// Scrub the memory of any sensitive data
	deinit {
		address = String(repeating: "0", count: address.count)
		mnemonic = String(repeating: "0", count: mnemonic.count)
		passphrase = String(repeating: "0", count: passphrase?.count ?? 0)
	}
}
