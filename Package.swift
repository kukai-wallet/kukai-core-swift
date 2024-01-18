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
		.package(name: "KukaiCryptoSwift", url: "https://github.com/kukai-wallet/kukai-crypto-swift", from: "1.0.18" /*.branch("feature/")*/),
		//.package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.6.2"),
		//.package(url: "https://github.com/simonmcl/Kingfisher.git", from: "1.0.0"),
		.package(name: "CustomAuth", url: "https://github.com/torusresearch/customauth-swift-sdk", from: "6.0.0"),
		//.package(url: "https://github.com/simonmcl/SVGKit", from: "3.0.3"),
		.package(name: "SignalRClient", url: "https://github.com/moozzyk/SignalR-Client-Swift", from: "0.8.0"),
		.package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.18.10")
	],
	targets: [
		.target(
			name: "KukaiCoreSwift",
			dependencies: [
				"KukaiCryptoSwift",
				//"Kingfisher",
				//"SVGKit",
				"SDWebImage",
				"CustomAuth",
				"SignalRClient",
			],
			resources: [
				.copy("Services/kukai-dex-calculations.js"),
				.copy("Services/ledger_app_tezos.js"),
				.copy("Services/taquito_local_forging.js")
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
