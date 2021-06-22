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
		
		// Currently not working "invalid path 'Sources' for target 'WalletCore'".
		// Need to manually download and build WalletCore as .xcframeworks using `tools/ios-xcframework`. Then include them as binary targets
		//.package(url: "https://github.com/hewigovens/wallet-core-spm", .branch("master")),
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
				"SwiftProtobuf",
				"WalletCore",
				"WalletCoreTypes"
			],
			resources: [
				.copy("Services/External")
			],
			cSettings: [
				.headerSearchPath("include")
			],
			cxxSettings: [
				.headerSearchPath("include")
			],
			linkerSettings: [
				.linkedFramework("SwiftProtobuf"),
				.linkedFramework("WalletCore"),
				.linkedFramework("WalletCoreTypes")
			]
		),
		
        .testTarget(
			name: "KukaiCoreSwiftTests",
			dependencies: ["KukaiCoreSwift"],
			resources: [
				.copy("Stubs")
			]
		),
		
		.binaryTarget(name: "SwiftProtobuf", path: "Binaries/SwiftProtobuf.xcframework"),
		.binaryTarget(name: "WalletCore", path: "Binaries/WalletCore.xcframework"),
		.binaryTarget(name: "WalletCoreTypes", path: "Binaries/WalletCoreTypes.xcframework"),
    ]
)
