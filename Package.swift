// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "KukaiCoreSwift",
	platforms: [
		.iOS("15.0"),
	],
	products: [
		.library(name: "KukaiCoreSwift", targets: ["KukaiCoreSwift"]),
	],
	dependencies: [
		.package(name: "KukaiCryptoSwift", url: "https://github.com/kukai-wallet/kukai-crypto-swift", from: "1.0.19" /*.branch("feature/")*/),
		.package(name: "CustomAuth", url: "https://github.com/torusresearch/customauth-swift-sdk", from: "10.0.1"),
		.package(name: "SignalRClient", url: "https://github.com/moozzyk/SignalR-Client-Swift", from: "0.8.0"),
		.package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.18.10")
	],
	targets: [
		.target(
			name: "KukaiCoreSwift",
			dependencies: [
				"KukaiCryptoSwift",
				"SDWebImage",
				"CustomAuth",
				"SignalRClient",
			],
			resources: [
				.copy("Services/kukai-dex-calculations.js"),
				.copy("Services/ledger_app_tezos.js"),
				.copy("Services/taquito_local_forging.js"),
				.copy("PrivacyInfo.xcprivacy")
			]
		),
		
		.testTarget(
			name: "KukaiCoreSwiftTests",
			dependencies: [
				"KukaiCoreSwift"
			],
			resources: [
				.copy("Stubs"),
				.copy("Services/MockData")
			]
		),
	]
)
