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
		.package(name: "Sodium", url: "https://github.com/jedisct1/swift-sodium.git", from: "0.9.1"),
		.package(name: "secp256k1", url: "https://github.com/Boilertalk/secp256k1.swift.git", from: "0.1.4"),
		.package(url: "https://github.com/onevcat/Kingfisher.git", from: "6.3.0"),
		.package(name: "WalletCore", url: "https://github.com/hewigovens/wallet-core-spm", .branch("master")),
    ],
    targets: [
        .target(
			name: "KukaiCoreSwift",
			dependencies: [
				"BigInt",
				"Sodium",
				.product(name: "Clibsodium", package: "Sodium"),
				"secp256k1",
				"Kingfisher",
				"WalletCore",
			],
			resources: [
				.copy("Services/External")
			]
		),
		
        .testTarget(
			name: "KukaiCoreSwiftTests",
			dependencies: ["KukaiCoreSwift"],
			resources: [
				.copy("Stubs")
			]
		),
    ]
)
