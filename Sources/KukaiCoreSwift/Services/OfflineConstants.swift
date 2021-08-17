//
//  OfflineConstants.swift
//  
//
//  Created by Simon Mcloughlin on 13/08/2021.
//

import Foundation

public enum DAppCategory {
	case marketplace
	case exchange
	case collectible
}

public enum DAppAccessType {
	case all
	case directAuthOnly
	case none
}

public struct DApp {
	let name: String
	let symbol: String
	let parentContractAddress: [String]
	let thumbnailURL: URL?
	let website: URL?
	let category: DAppCategory?
	let accessType: DAppAccessType
}

public struct OfflineConstants {
	
	static let dApps: [TezosChainName: [DApp]] = [
		.mainnet: [
			DApp(
				name: "Hic et Nunc (HEN)",
				symbol: "hen",
				parentContractAddress: ["KT1AFA2mwNUMNd4SsujE1YYp29vd8BZejyKW", "KT1RJ6PbjHpwc3M5rw5s2Nbmefwbuwbdxton", "KT1M2JnD1wsg7w2B4UXJXtKQPuDUpU2L7cJH"],
				thumbnailURL: URL(string: "https://dashboard-assets.dappradar.com/document/7357/hicetnunc-dapp-marketplaces-tezos-logo-166x166_88a66b54787c555ea5237fa002586ae5.png")!,
				website: URL(string: "https://www.hicetnunc.xyz/")!,
				category: .marketplace,
				accessType: .all
			),
			DApp(
				name: "QuipuSwap",
				symbol: "",
				parentContractAddress: [],
				thumbnailURL: URL(string: "https://dashboard-assets.dappradar.com/document/7360/quipuswap-dapp-exchanges-tezos-logo-166x166_f8f472a49e3f3d6b591a13dbd979a857.png")!,
				website: URL(string: "https://quipuswap.com/")!,
				category: .exchange,
				accessType: .all
			),
			DApp(
				name: "Minterpop",
				symbol: "",
				parentContractAddress: ["KT1AaaBSo5AE6Eo8fpEN5xhCD4w3kHStafxk"],
				thumbnailURL: URL(string: "https://minterpop.com/_next/static/images/logo-ac73543744326030947adf91a3dad06c.svg")!,
				website: URL(string: "https://minterpop.com/")!,
				category: .collectible,
				accessType: .directAuthOnly
			),
			DApp(
				name: "Kalamint",
				symbol: "",
				parentContractAddress: ["KT1EpGgjQs73QfFJs9z7m1Mxm5MTnpC2tqse"],
				thumbnailURL: URL(string: "https://dashboard-assets.dappradar.com/document/7358/kalamint-dapp-marketplaces-tezos-logo-166x166_3157752c764b72d1e7759b1b005b07d7.png")!,
				website: URL(string: "https://kalamint.io/")!,
				category: .marketplace,
				accessType: .all
			),
			DApp(
				name: "Interpop Comics",
				symbol: "InterpopComics",
				parentContractAddress: ["KT1UxMVVrK2pbYYEtwes1zKYdpYnzoZ6yPKC"],
				thumbnailURL: URL(string: "https://dev.interpopcomics.com/interpop_logo.png")!,
				website: URL(string: "https://interpopcomics.com/")!,
				category: .collectible,
				accessType: .directAuthOnly
			),
			DApp(
				name: "Bazaar Market",
				symbol: "",
				parentContractAddress: ["KT1PKvHNWuWDNVDtqjDha4AostLrGDu4G1jy"],
				thumbnailURL: URL(string: "https://dashboard-assets.dappradar.com/document/7444/bazaarmarket-dapp-marketplaces-tezos-logo-166x166_eeff309690a4abe4d06e78922012d985.png")!,
				website: URL(string: "https://bazaarnft.xyz/")!,
				category: .marketplace,
				accessType: .all
			),
			DApp(
				name: "TzColors",
				symbol: "",
				parentContractAddress: ["KT1FyaDqiMQWg7Exo7VUiXAgZbd2kCzo3d4s"],
				thumbnailURL: URL(string: "https://dashboard-assets.dappradar.com/document/7361/tzcolors-dapp-marketplaces-tezos-logo-166x166_4731835687c8ad06edf1d8c140905e12.png")!,
				website: URL(string: "https://www.tzcolors.io/")!,
				category: .collectible,
				accessType: .all
			),
			DApp(
				name: "PixelPotus",
				symbol: "PixelPotus",
				parentContractAddress: ["KT1WGDVRnff4rmGzJUbdCRAJBmYt12BrPzdD"],
				thumbnailURL: URL(string: "https://www.pixelpotus.com/img/eagle-right.d1840b0b.png")!,
				website: URL(string: "https://www.pixelpotus.com/")!,
				category: .collectible,
				accessType: .all
			),
			DApp(
				name: "SalsaDao Tacoshop & Casino",
				symbol: "SalsaDaoTacoshop",
				parentContractAddress: ["KT1UmxSSUQ5716tRa2RLNSAkiSG6TWbzZ7GL", "KT1JYWuC4eWqYkNC1Sh6BiD89vZzytVoV2Ae", "KT1NvPaecvj8g7SbDs8E5s2jxbEBKHxZssP1", "KT1LhNu3v6rCa3Ura3bompAAJZD9io5VRaWZ", "KT1VHd7ysjnvxEzwtjBAmYAmasvVCfPpSkiG"],
				thumbnailURL: URL(string: "https://dashboard-assets.dappradar.com/document/7837/salsadao-dapp-other-tezos-logo-166x166_d4625f93b4fa3858c32b15b36c99617e.png")!,
				website: URL(string: "https://tezostaco.shop/#/")!,
				category: .collectible,
				accessType: .none
			),
			DApp(
				name: "Truesy",
				symbol: "",
				parentContractAddress: ["KT197APGtQ8mk2svRSpDkqXLzHedRtkJ7Hjr", "KT1CTqQ4vg2zyG1AQmDLVeJ473ueoy2Rw8t1", "KT1QE4nZiAXbpuDCu4P5QTNibQSx6FFW3y2W", "KT1QbzLyzwXB9JTevvjT3B24BzgWfMzFfBHt"],
				thumbnailURL: URL(string: "https://wallet.kukai.app/assets/img/spinner/truesy.svg")!,
				website: nil,
				category: nil,
				accessType: .none
			),
			DApp(
				name: "NBA",
				symbol: "",
				parentContractAddress: ["KT1LqKWDtzUh4CXNqfJQMcATv4PdZxBjPJjH"],
				thumbnailURL: nil,
				website: nil,
				category: nil,
				accessType: .none
			),
			DApp(
				name: "BUA",
				symbol: "",
				parentContractAddress: ["KT1WN9yWqV9pEm1ANR56ExJZbnVukWN31fTY", "KT1WBXFKW1sozV7ZLBHvw5eks6Pb8KSoVmLq", "KT1KWNNBtb7z8pejNUNigaRWSTkTQL4DEcf8", "KT1D6CNSXcftRTArCF73Jpsh95dwgEwAy6qZ", "KT1R87j2qFxtPZE3EmmeSoubg2mZkk3j4X8y", "KT1HRCc359qXshgMpBygY3VwqTnV7fc7nYfp", "KT1MU8Pb9DFjnVpEULyWDrqPLjedZPNHFrEN", "KT1FPfsRVWVju2mH1r2iFg5jfzWj7RDCb6ia", "KT19AqSn4m3NtvztPXuETjCzoQ75bKDd1Pyi", "KT1PcYxsFmXuoxcJpcfRSCcQQeSDLERSMzsW", "KT1KSYCk8zjdhgzDDRsmb2ygAfanjBx25Wto"],
				thumbnailURL: nil,
				website: nil,
				category: nil,
				accessType: .none
			),
			DApp(
				name: "OpenMinter",
				symbol: "",
				parentContractAddress: ["KT1QcxwB4QyPKfmSwjH1VRxa6kquUjeDWeEy"],
				thumbnailURL: URL(string: "https://openminter.com/static/media/header-logo.a9dd48a8.svg")!,
				website: nil,
				category: nil,
				accessType: .none
			)
		]
	]
	
	static func dappDisplayName(forContractAddress address: String, onChain chain: TezosChainName) -> (name: String, thumbnail: URL?) {
		guard let networkList = dApps[chain] else {
			return (name: address, thumbnail: nil)
		}
		
		for dapp in networkList {
			for contract in dapp.parentContractAddress {
				if contract == address {
					return (name: dapp.name, thumbnail: dapp.thumbnailURL)
				}
			}
		}
		
		return (name: address, thumbnail: nil)
	}
}
