// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "KukaiCoreSwift",
	platforms: [
		.iOS("15.0"),
		.macOS(.v11),
	],
	products: [
		.library(name: "KukaiCoreSwift", targets: ["KukaiCoreSwift"]),
	],
	dependencies: [
		.package(name: "KukaiCryptoSwift", url: "https://github.com/kukai-wallet/kukai-crypto-swift", from: "1.0.1"),
		.package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
		
		// Can't upgrade to the latest 2.4.0 of CustomAuth, because it uses a newer version of FetchNodeDetails which has many issues.
		// Remove FetchNodeDetails and change CustomAuth back to a "from: " when the issues are resolved
		.package(name: "FetchNodeDetails", url: "https://github.com/torusresearch/fetch-node-details-swift", .exact("1.3.0")),
		.package(name: "CustomAuth", url: "https://github.com/torusresearch/customauth-swift-sdk", .exact("2.1.0")),
		
		.package(url: "https://github.com/simonmcl/SVGKit", from: "3.0.1"),
		.package(name: "SignalRClient", url: "https://github.com/moozzyk/SignalR-Client-Swift", from: "0.8.0"),
		.package(name: "JWTDecode", url: "https://github.com/auth0/JWTDecode.swift.git", from: "2.6.3")
	],
	targets: [
		.target(
			name: "KukaiCoreSwift",
			dependencies: [
				"KukaiCryptoSwift",
				"Kingfisher",
				"SVGKit",
				"CustomAuth",
				"SignalRClient",
				"JWTDecode",
				"FetchNodeDetails"
			],
			resources: [
				.copy("Services/External")
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
