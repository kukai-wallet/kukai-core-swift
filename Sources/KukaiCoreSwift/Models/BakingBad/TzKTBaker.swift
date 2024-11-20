//
//  TzKTBaker.swift
//  
//
//  Created by Simon Mcloughlin on 02/09/2022.
//

import Foundation

/// Whether the baker is actively running or not
public enum TzKTBakerStatus: String, Codable {
	case active
	case closed
	case notResponding = "not_responding"
	case unknown
	
	public init(from decoder: Decoder) throws {
		self = try .init(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
	}
}

/// Object to denote the the setting parameters of the baker. Can be used seperately for both delegation and staking
public struct TzKTBakerSettings: Codable {
    public let enabled: Bool
	public let minBalance: Decimal
	public let fee: Double
	public let capacity: Decimal
	public let freeSpace: Decimal
	public let estimatedApy: Double
}

/// Data representing a baker from TzKT or Baking-Bad
public struct TzKTBaker: Codable, Hashable {
	
	public let address: String
	public let name: String?
    public let status: TzKTBakerStatus
    public let balance: Decimal
    public let delegation: TzKTBakerSettings
    public let staking: TzKTBakerSettings
	
	public var limitOfStakingOverBaking: Decimal?
	public var edgeOfBakingOverStaking: Decimal?
    
    public var logo: URL? {
        get {
            return TzKTClient.avatarURL(forToken: address)
        }
    }
    
	/// Helper to create a TzKTBaker from the data available from the `Account` object
	public init(address: String, name: String?) {
		self.address = address
		self.name = name
        self.status = .active
		self.balance = 0
        self.delegation = TzKTBakerSettings(enabled: true, minBalance: 0, fee: 0, capacity: 0, freeSpace: 0, estimatedApy: 0)
        self.staking = TzKTBakerSettings(enabled: true, minBalance: 0, fee: 0, capacity: 0, freeSpace: 0, estimatedApy: 0)
	}
    
    public init(address: String, name: String?, status: TzKTBakerStatus, balance: Decimal, delegation: TzKTBakerSettings, staking: TzKTBakerSettings) {
		self.address = address
		self.name = name
		self.balance = balance
        self.status = status
        self.delegation = delegation
        self.staking = staking
	}
	
	/// Ghostnet has a different setup for bakers, but we need to display and interact with them the same way.
	/// So this helper extract what it can from the API and creates semi-real baker objects to help users deal with Ghostnet
	public static func fromTestnetArray(_ data: [Any]) -> TzKTBaker? {
		guard data.count == 6,
				let address = data[0] as? String,
				let balance = (data[2] as? NSNumber)?.decimalValue,
				let stakingBalance = (data[3] as? NSNumber)?.decimalValue,
				let limitOfStakingOverBaking = (data[4] as? NSNumber)?.decimalValue,
				let edgeOfBakingOverStaking = (data[5] as? NSNumber)?.decimalValue else {
			return nil
		}
		
		let name = data[1] as? String
		let normalisedBalance = balance/1000000
		let normalisedStakingBal = stakingBalance/1000000
        let delegation = TzKTBakerSettings(enabled: true, minBalance: 0, fee: 0.05, capacity: normalisedStakingBal, freeSpace: normalisedStakingBal, estimatedApy: 0.05)
        let staking = TzKTBakerSettings(enabled: true, minBalance: 0, fee: 0.05, capacity: normalisedStakingBal, freeSpace: normalisedStakingBal, estimatedApy: 0.05)
		
		var baker = TzKTBaker(address: address, name: name, status: .active, balance: normalisedBalance, delegation: delegation, staking: staking)
		baker.limitOfStakingOverBaking = limitOfStakingOverBaking
		baker.edgeOfBakingOverStaking = edgeOfBakingOverStaking
		
        return baker
	}
	
	public func hash(into hasher: inout Hasher) {
		hasher.combine(address)
	}
	
	public static func == (lhs: TzKTBaker, rhs: TzKTBaker) -> Bool {
		return lhs.address == rhs.address
	}
}
