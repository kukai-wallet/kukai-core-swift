# Kukai Core Swift

[![Platforms](https://img.shields.io/badge/Platforms-iOS-blue)](https://img.shields.io/badge/Platforms-iOS-blue)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/kukai-wallet/kukai-core-swift/blob/main/LICENSE)


Kukai Core Swift is a native Swift library for interacting with the Tezos blockchain and other applications in the Tezos ecosystem, such as the indexer [TzKT](https://tzkt.io) and the smart contract explorer [Better Call Dev](https://better-call.dev/). It leverages [WalletCore](https://github.com/trustwallet/wallet-core) the open source library built by [TrustWallet](https://trustwallet.com/), for key and wallet creation.

<br/>

Feature set includes:

- Create Linear or HD Wallets
- A service to cache and retrieve encrypted wallet details from disk, using the secure enclave
- Fetching a wallet's XTZ balance, all FA token balances, owned NFT's grouped together by type, all in a single function call
- Fetching and caching token metadata
- Fetching transaction history
- Remote forging using a second node or Local forging via [@taquito/local-forging](https://github.com/ecadlabs/taquito/tree/master/packages/taquito-local-forging)
- Estimating Gas, Storage and Fees for operations
- Parsing Michelson JSON into a Swift object using Codable
- Wait for an operation to be injected



<br/>
<br/>

# Install

Kukai Core Swift supports the Swift Package Manager. Either use the Xcode editor to add to your project by clicking `File` -> `Swift Packages` -> `Add Package Dependency`, search for the git repo `https://github.com/kukai-wallet/kukai-core-swift.git` and choose from version `0.1.0`.

Or add it to your `Package.swift` dependencies like so:

```
dependencies: [
    .package(url: "https://github.com/kukai-wallet/kukai-core-swift", from: "0.1.0")
]
```



<br/>
<br/>

# How to use

Wallets are created using dedicated classes for each type, conforming to the `Wallet` protocol.

- [LinearWallet](https://kukai.app/kukai-core-swift/LinearWallet/)
  - Created using a BIP 39 mnemonic and optional passphrase
- [HDWallet](https://kukai.app/kukai-core-swift/HDWallet/)
  - Created using a BIP 39 mnemonic, optional passphrase, and a BIP 44 derivation path

<br/>

The main functionality centres around client classes and a factory:

- [TezosNodeClient](https://kukai.app/kukai-core-swift/TezosNodeClient/)
  - Query details about the node
  - Estimate fees via the node RPC
  - Send operations
- [BetterCallDevClient](https://kukai.app/kukai-core-swift/BetterCallDevClient/)
  - Fetching balances
  - Fetching metadata
  - Detailed operation errors
- [TzKTClient](https://kukai.app/kukai-core-swift/TzKTClient/)
  - Transaction history
  - Determining if an operation has been successfully injected
- [OperationFactory](https://kukai.app/kukai-core-swift/OperationFactory/)
  - Helper methods to create arrays of operations needed for common tasks


<br/>

You can see some of this functionality inside the repo's example iOS-Example project. The app is a simple tableview, with the first section responsible for creating and caching wallets. The rest of the sections will load the cached wallet and use its details to fetch/display balances or estiamte/send operations.



<br/>
<br/>

# Documentation

Compiled Swift Doc's can be found [here](https://kukai.app/kukai-core-swift/)
