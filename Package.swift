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
		
		// TODO: problem with the offical swift-sodium (https://github.com/jedisct1/swift-sodium), using someone elses fork with a bug fix until merged into main repo or SPM bug fixed
		.package(name: "Sodium", url: "https://github.com/junelife/swift-sodium.git", .branch("master")),
		.package(url: "https://github.com/onevcat/Kingfisher.git", from: "6.3.0"),
		.package(name: "WalletCore", url: "https://github.com/hewigovens/wallet-core-spm", .branch("master")),
		.package(name: "TorusSwiftDirectSDK", url: "https://github.com/simonmcl/torus-direct-swift-sdk", .branch("master")),
    ],
    targets: [
        .target(
			name: "KukaiCoreSwift",
			dependencies: [
				//.product(name: "Clibsodium", package: "Sodium"),
				"Sodium",
				"BigInt",
				"Kingfisher",
				"WalletCore",
				"TorusSwiftDirectSDK"
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
