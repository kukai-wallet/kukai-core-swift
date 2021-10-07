// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "KukaiCoreSwift",
	platforms: [.iOS(.v14)],
	products: [
		.library(name: "KukaiCoreSwift", targets: ["KukaiCoreSwift"]),
	],
	dependencies: [
		.package(url: "https://github.com/attaswift/BigInt.git", from: "5.2.1"),
		.package(name: "Sodium", url: "https://github.com/jedisct1/swift-sodium", from: "0.9.1"),
		.package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
		.package(name: "WalletCore", url: "https://github.com/hewigovens/wallet-core-spm", .branch("master")),
		.package(name: "TorusSwiftDirectSDK", url: "https://github.com/torusresearch/torus-direct-swift-sdk", from: "1.1.1"),
		.package(url: "https://github.com/simonmcl/SVGKit", from: "3.0.1"),
		.package(name: "SignalRClient", url: "https://github.com/moozzyk/SignalR-Client-Swift", from: "0.8.0")
	],
	targets: [
		.target(
			name: "KukaiCoreSwift",
			dependencies: [
				.product(name: "Clibsodium", package: "Sodium"),
				"Sodium",
				"BigInt",
				"Kingfisher",
				"SVGKit",
				"WalletCore",
				"TorusSwiftDirectSDK",
				"SignalRClient"
			],
			resources: [
				.copy("Services/External")
			]
		),
		
		.testTarget(
			name: "KukaiCoreSwiftTests",
			dependencies: ["KukaiCoreSwift"],
			resources: [
				.copy("Stubs"),
				.copy("Services/MockData")
			]
		),
	]
)
