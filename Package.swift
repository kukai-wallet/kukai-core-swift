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
		.package(name: "KukaiCryptoSwift", url: "https://github.com/kukai-wallet/kukai-crypto-swift", from: "1.0.6"),
		//.package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.6.2"),
		.package(url: "https://github.com/simonmcl/Kingfisher.git", from: "1.0.0"),
		.package(name: "CustomAuth", url: "https://github.com/torusresearch/customauth-swift-sdk", from: "5.0.0"),
		.package(url: "https://github.com/simonmcl/SVGKit", from: "3.0.2"),
		.package(name: "SignalRClient", url: "https://github.com/moozzyk/SignalR-Client-Swift", from: "0.8.0"),
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
			],
			resources: [
				.copy("Services/External-js")
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
