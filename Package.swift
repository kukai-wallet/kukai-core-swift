// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "KukaiCoreSwift",
	platforms: [.iOS("15.0")],
	products: [
		.library(name: "KukaiCoreSwift", targets: ["KukaiCoreSwift"]),
	],
	dependencies: [
		.package(url: "https://github.com/attaswift/BigInt.git", from: "5.2.1"),
		.package(name: "Sodium", url: "https://github.com/jedisct1/swift-sodium", from: "0.9.1"),
		.package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
		.package(name: "WalletCore", url: "https://github.com/trustwallet/wallet-core", .exact("2.6.34")),
		.package(name: "CustomAuth", url: "https://github.com/torusresearch/customauth-swift-sdk", from: "2.1.0"),
		.package(url: "https://github.com/simonmcl/SVGKit", from: "3.0.1"),
		.package(name: "SignalRClient", url: "https://github.com/moozzyk/SignalR-Client-Swift", from: "0.8.0"),
		.package(name: "JWTDecode", url: "https://github.com/auth0/JWTDecode.swift.git", from: "2.6.3"),
		
		// Temporary until Argent / CustomAuth fix the target name collision
		.package(name:"web3.swift", url: "https://github.com/argentlabs/web3.swift", .exact("0.8.2")),
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
				"CustomAuth",
				"SignalRClient",
				"JWTDecode",
				
				// Temporary until Argent / CustomAuth fix the target name collision
				"web3.swift"
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
