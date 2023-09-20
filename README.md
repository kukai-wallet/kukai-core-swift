# Kukai Core Swift

[![Platforms](https://img.shields.io/badge/Platforms-iOS-blue)](https://img.shields.io/badge/Platforms-iOS-blue)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/kukai-wallet/kukai-core-swift/blob/main/LICENSE)


Kukai Core Swift is a native Swift library for interacting with the Tezos blockchain and other applications in the Tezos ecosystem, such as the Tezos Node RPC, the indexer [TzKT](https://tzkt.io), the smart contract explorer [Better Call Dev](https://better-call.dev/), the API from the NFT marketplace [OBJKT.com](https://objkt.com) etc.

The purpose of this SDK is not to provide a complete feature set for every aspect of Tezos, instead it is the base building block for the Kukai iOS mobile app, that we open source and make avaialble for anyone looking for similar functionality. We are open to accepting PR's and discussing changes/features. However if its not related to the kuaki mobile app, such work is likely better suited in a standalone package, with this as a dependency.

<br/>

Feature set includes:

- Create Regular and HD wallets
- A service to cache and retrieve encrypted wallet details from disk, using the secure enclave
- Fetching a wallet's XTZ balance, all FA token balances, owned NFT's grouped together by type, all in a single function call
- Fetching transaction history, including token transfers
- Remote forging using a second node or Local forging via [@taquito/local-forging](https://github.com/ecadlabs/taquito/tree/master/packages/taquito-local-forging)
  - Using a "vanilla" javascript version of the local-forging package specifically. These JS files can be found under the taquito github releases, under assets, named `taquito-local-forging-vanilla.zip`. e.g. [here](https://github.com/ecadlabs/taquito/releases/tag/17.2.0)
  - Created using [this webpack config](https://github.com/simonmcl/taquito/tree/feature/mobile_friendly_webpack/packages/taquito-local-forging) as a starting point
- Estimating Gas, Storage and Fees for operations
- Fetch Tezos domains from addresses, and addresses from domains
- Media proxy tools for dealing with collectible and token images
- Helpers for dealing with Michelson JSON
- Helpers for parsing contents of Operations
- Helpers for parsing errors
- Dex fee + return calculation



<br/>
<br/>

# Install

Kukai Core Swift supports the Swift Package Manager. Either use the Xcode editor to add to your project by clicking `File` -> `Swift Packages` -> `Add Package Dependency`, search for the git repo `https://github.com/kukai-wallet/kukai-core-swift.git` and choose from version `x.x.x` (see tags for latest).

Or add it to your `Package.swift` dependencies like so:

```
dependencies: [
    .package(url: "https://github.com/kukai-wallet/kukai-core-swift", from: "x.x.x")
]
```



<br/>
<br/>

# How to use

Wallets are created using dedicated classes for each type, conforming to the `Wallet` protocol. Wallets are created using `Mnemonic` objects, see [Kukai Crypto Swift](https://github.com/kukai-wallet/kukai-crypto-swift) for more details on those

- [RegularWallet](https://kukai-core-swift.kukai.app/RegularWallet/)
  - Created using a `Mnemonic`, an optional passphrase, and optionally specify the `EllipticalCurve` you want (`ed25519` for TZ1..., `secp256k1` for TZ2...)
- [HDWallet](https://kukai-core-swift.kukai.app/HDWallet/)
  - Created using a `Mnemonic`, an optional passphrase, and an optional BIP 44 derivation path

<br/>

The main functionality centres around client classes and a factory:

- [TezosNodeClient](https://kukai-core-swift.kukai.app/TezosNodeClient/)
  - Query details about the node
  - Estimate fees via the node RPC
  - Send operations
- [TzKTClient](https://kukai-core-swift.kukai.app/TzKTClient/)
  - Fetching balances
  - Transaction history
  - Determining if an operation has been successfully injected
- [OperationFactory](https://kukai-core-swift.kukai.app/OperationFactory/)
  - Helper methods to create arrays of operations needed for common tasks


<br/>

For working example, see the kukai mobile ios app [here](https://github.com/kukai-wallet/kukai-mobile-ios)



<br/>
<br/>

# Documentation

Compiled Swift Doc's can be found [here](https://kukai-core-swift.kukai.app/)
