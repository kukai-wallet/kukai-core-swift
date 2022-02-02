//
//  SceneDelegate.swift
//  iOS-Example
//
//  Created by Simon Mcloughlin on 22/06/2021.
//

import UIKit
import TorusSwiftDirectSDK
import KukaiCoreSwift
import Sodium
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

	var window: UIWindow?
	var bag = Set<AnyCancellable>()
	var tools: TezToolsClient? = nil

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		// Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
		// If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
		// This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
		guard let _ = (scene as? UIWindowScene) else { return }
	}

	func sceneDidDisconnect(_ scene: UIScene) {
		// Called as the scene is being released by the system.
		// This occurs shortly after the scene enters the background, or when its session is discarded.
		// Release any resources associated with this scene that can be re-created the next time the scene connects.
		// The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
	}

	func sceneDidBecomeActive(_ scene: UIScene) {
		// Called when the scene has moved from an inactive state to an active state.
		// Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
		
		experiment()
	}

	func sceneWillResignActive(_ scene: UIScene) {
		// Called when the scene will move from an active state to an inactive state.
		// This may occur due to temporary interruptions (ex. an incoming phone call).
	}

	func sceneWillEnterForeground(_ scene: UIScene) {
		// Called as the scene transitions from the background to the foreground.
		// Use this method to undo the changes made on entering the background.
	}

	func sceneDidEnterBackground(_ scene: UIScene) {
		// Called as the scene transitions from the foreground to the background.
		// Use this method to save data, release shared resources, and store enough scene-specific state information
		// to restore the scene back to its current state.
	}
	
	func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
		guard let url = URLContexts.first?.url else {
			return
		}
		
		TorusSwiftDirectSDK.handle(url: url)
	}
	
	
	
	
	
	func experiment() {
		
		/*
		ClientsAndData.shared.tezosDomainsClient.getDomainFor(address: "tz1SUrXU6cxioeyURSxTgaxmpSWgQq4PMSov")
			.sink { error in
				print("Error: \(error)")
				
			} onSuccess: { response in
				print("Response - domain: \(response.data?.domain() ?? "-")")
			}
			.store(in: &bag)

		ClientsAndData.shared.tezosDomainsClient.getAddressFor(domain: "crane-cost.gra")
			.sink { error in
				print("Error: \(error)")
				
			} onSuccess: { response in
				print("Response - address: \(response.data?.domain.address ?? "-")")
			}
			.store(in: &bag)
		 */
		
		
		/*
		let didBlockStart = RequestIfService.runBlock({ [weak self] in
			
			guard let bip39Wallet = LinearWallet(withMnemonic: "remember smile trip tumble era cube worry fuel bracket eight kitten inform", passphrase: "") else {
				print("failed to create Bip39 wallet")
				return
			}
			
			guard let bip44Wallet = HDWallet(withMnemonic: "remember smile trip tumble era cube worry fuel bracket eight kitten inform", passphrase: "") else {
				print("failed to create Bip44 wallet")
				return
			}
			
			let operations = OperationFactory.sendOperation(XTZAmount(fromNormalisedAmount: 0.1), of: Token.xtz(), from: bip39Wallet.address, to: bip44Wallet.address)
			ClientsAndData.shared.tezosNodeClient.estimate(operations: operations, withWallet: bip39Wallet) { (result) in
				switch result {
					case .success(let ops):
						print("ops: \(ops)")
					
					case .failure(let error):
						print("error: \(error)")
				}
			}
			
			
		}, ifIntervalHasPassed: RequestIfService.Interval.day, forKey: "")
		
		print("\n\n\n didBlockStart: \(didBlockStart) \n\n\n")
		*/
		
		
		let url = MediaProxyService.url(fromUri: URL(string: "https://mediagateway.sweet.io/media/series/nKbK5rq5/media.mp4"), ofFormat: .gallery)!
		MediaProxyService().getMediaType(fromFormats: [], orURL: url) { result in
			print("Result: \(result)")
		}
	}
}



// Liquidity baking
// Granadanet dex contract: 	KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5
// Granadanet lq token:			KT1AafHA1C1vk959wvHWBispY9Y2f3fxBUUo
// Granadanet tzBTC token:		KT1PWx2mnDueood7fEmfbBDKx1D9BAnnXitn (docs / comment says this one)   or   KT1VqarPDicMFn1ejmQqqshUkUXTCTXwmkCN (tzkt says this one)



/*
ClientsAndData.shared.tezosNodeClient.getLiquidityBakingPoolData(forContract: (address: "KT1TxqZ8QtKvLu3V3JH7Gx58n7Co8pgtpQU5", decimalPlaces: 8)) { [weak self] result in
	switch result {
		case .success(let poolData):
			print("Pooldata: \(poolData)")
			
		case .failure(let error):
			print("Error: \(error)")
	}
}
*/





/*
var errors: [String] = []
for i in 0...10000 {
	let wallet = LinearWallet.create(withMnemonicLength: .twelve, passphrase: "", ellipticalCurve: .secp256k1)
	
	print("\(i): \(wallet!.mnemonic)")
}
*/



// tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG

// Metadata url:  https://api.better-call.dev/v1/tokens/florencenet/metadata?contract=KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8
// Metadata url NFT:  https://api.better-call.dev/v1/tokens/florencenet/metadata?contract=KT1DEJEcfiMUWYjn1ZCTbbLokRcP26sx2pTH

// Contract metadata: https://api.better-call.dev/v1/contract/mainnet/KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8


/*
ClientsAndData.shared.bcdClient.contractMetdata(forContractAddress: "KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8") { result in
	
}
*/









/*
guard let bip39Wallet = LinearWallet.create(withMnemonic: "remember smile trip tumble era cube worry fuel bracket eight kitten inform", passphrase: "") else {
	print("failed to create Bip39 wallet")
	return
}

guard let bip44Wallet = HDWallet.create(withMnemonic: "remember smile trip tumble era cube worry fuel bracket eight kitten inform", passphrase: "") else {
	print("failed to create Bip44 wallet")
	return
}

let operations = OperationFactory.sendOperation(XTZAmount(fromNormalisedAmount: 0.1), of: Token.xtz(), from: bip39Wallet.address, to: bip44Wallet.address)
ClientsAndData.shared.tezosNodeClient.estimate(operations: operations, withWallet: bip39Wallet) { [weak self] (result) in
	switch result {
		case .success(let ops):
			
			ClientsAndData.shared.tezosNodeClient.getOperationMetadata(forWallet: bip39Wallet) { [weak self] (innerResult) in
				
				switch innerResult {
					case .success(let metadata):
						
						
						let payload = OperationFactory.operationPayload(fromMetadata: metadata, andOperations: ops, withWallet: bip39Wallet)
						TaquitoService.shared.forge(operationPayload: payload) { forgeResult in
							
							switch forgeResult {
								case .success(let forgedString):
									print("\n\n\n forgedString: \(forgedString) \n\n\n")
									
									
									/*
									TaquitoService.shared.forge(operationPayload: payload) { forgeResult in
										
										switch forgeResult {
											case .success(let forgedString):
												print("\n\n\n forgedString: \(forgedString) \n\n\n")
											
											case .failure(let forgedError):
												print("\n\n\n forgedError: \(forgedError) \n\n\n")
										}
									}
									*/
									
									/*
									TaquitoService.shared.parse(hex: forgedString) { parseResult in
										switch parseResult {
											case .success(let parsedObj):
												print("\n\n\n parsedObj: \(parsedObj.contents.first?.source) \n\n\n")
											
											case .failure(let parsedError):
												print("\n\n\n parsedError: \(parsedError) \n\n\n")
										}
									}
									*/
									
									
									
									
									
									/*
									ClientsAndData.shared.tezosNodeClient.operationService.parse(forgeResult: forgeResult, operationMetadata: metadata, operationPayload: payload) { parseResult in
										
										switch parseResult {
											case .success(let parseString):
												print("\n\n\n parseString: \(parseString) \n\n\n")
												
											case .failure(let parseError):
												print("\n\n\n parseError: \(parseError) \n\n\n")
										}
									}
									*/
									
									
									
									
								case .failure(let forgedError):
									print("\n\n\n forgedError: \(forgedError) \n\n\n")
							}
							
						}
						
						
						
					case .failure(let innerError):
						
						print("\n\nAPPLICATION - SEND FAILURE: \(innerError)")
				}
			}
			
		case .failure(let error):
			print("\n\nAPPLICATION - SEND FAILURE: \(error)")
	}
}
*/




/*
let xtz = Token(icon: nil, name: "Tez", symbol: "XTZ", tokenType: .xtz, balance: XTZAmount.zero(), tokenContractAddress: nil, dexterExchangeAddress: nil)
let delphi_tzBTC = Token(icon: nil, name: "Wrapped BTC", symbol: "tzBTC", tokenType: .fa1_2, balance: TokenAmount.zeroBalance(decimalPlaces: 8), tokenContractAddress: "KT1RQALMs6RhC6y5e2Hbd6YzWchMGRVTYerG", dexterExchangeAddress: "KT1JxpVwbvvcpMs2XnZ8XiQ4p9Lmg2Bka5uP")
let delphi_USDtz = Token(icon: nil, name: "USD Tez", symbol: "USDtz", tokenType: .fa1_2, balance: TokenAmount.zeroBalance(decimalPlaces: 6), tokenContractAddress: "KT1UdHaVbHEq7BUrzq2gWsC2ipsnmttV7GN7", dexterExchangeAddress: "KT1B7U9EfmxKNtTmwzPZjZuRwRy8JCfPW5VS")

let tokens = [xtz, delphi_tzBTC, delphi_USDtz]
*/



// ========================================================================
// Better Call Dev Client
// ========================================================================

/*
ClientsAndData.shared.bcdClient.fetchAllBalancesAndMetadata(forAddress: "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG") { result in
	print("\n\n\n Result: \(result) \n\n\n")
}
*/



/*
bcdClient.accountAndTokenBalances(forAddress: "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG", completion: { result in
	switch result {
		case .success(let tokens):
			print("\n\n\n Tokens: \(tokens) \n\n\n")
			
		case .failure(let error):
			print("\n\n\n Error: \(error) \n\n\n")
	}
})
*/

/*
bcdClient.accountTokenCount(forAddress: "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG", completion: { result in
	switch result {
		case .success(let tokens):
			print("\n\n\n Tokens: \(tokens) \n\n\n")
			
		case .failure(let error):
			print("\n\n\n Error: \(error) \n\n\n")
	}
})
*/


/*
ClientsAndData.shared.bcdClient.fetchTokenCountAndBalances(forAddress: "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG") { result in
	switch result {
		case .success(let countAndbalances):
			print("\n\n\n Tokens: \(countAndbalances.balances) \n\n\n")
			
			ClientsAndData.shared.bcdClient.fetchAllTokenMetata(forTokenCount: countAndbalances.count) { innerResult in
				switch innerResult {
					case .success(let metadata):
						print("\n\n\n metadata: \(metadata) \n\n\n")
					
					case .failure(let error):
						print("\n\n\n Error 2: \(error) \n\n\n")
				}
			}
		
		case .failure(let error):
			print("\n\n\n Error 1: \(error) \n\n\n")
	}
}
*/






// Token addresses

// Mainnet
// ETHtz: 		KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8
// kUSD:  		KT1K9gCRgaLRFKTErYt1wVxA3Frb9FjasjTV

// Testnet
// Matrix NFT: 	KT1DEJEcfiMUWYjn1ZCTbbLokRcP26sx2pTH
// ETHtz:		KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8
// HEH:			KT1G1cCRNBgQ48mVDjopHjEmTN5Sbtar8nn9





// Testnet Matrix NFT
/*
bcdClient.tokenMetadata(forTokenAddress: "KT1DEJEcfiMUWYjn1ZCTbbLokRcP26sx2pTH") { result in
	switch result {
		case .success(let tokens):
			print("\n\n\n Tokens: \(tokens) \n\n\n")
			
		case .failure(let error):
			print("\n\n\n Error: \(error) \n\n\n")
	}
}
*/


// Mainnet ETHtz
/*
bcdClient.tokenMetadata(forTokenAddress: "KT19at7rQUvyjxnZ2fBv7D9zc8rkyG7gAoU8") { result in
	switch result {
		case .success(let tokens):
			print("\n\n\n Tokens: \(tokens) \n\n\n")
			
		case .failure(let error):
			print("\n\n\n Error: \(error) \n\n\n")
	}
}
*/

/*
// HEH
bcdClient.tokenMetadata(forTokenAddress: "KT1G1cCRNBgQ48mVDjopHjEmTN5Sbtar8nn9") { result in
	switch result {
		case .success(let tokens):
			print("\n\n\n Tokens: \(tokens) \n\n\n")
			
		case .failure(let error):
			print("\n\n\n Error: \(error) \n\n\n")
	}
}
*/

/*
bcdClient.allTokensOfVersion(.fa2) { result in
	switch result {
		case .success(let tokens):
			print("\n\n\n Tokens: \(tokens) \n\n\n")
			
		case .failure(let error):
			print("\n\n\n Error: \(error) \n\n\n")
	}
}
*/



/*
// ========================================================================
// Activate a faucet account
// ========================================================================

let newWallet = LinearWallet.create(withMnemonic: "", passphrase: "")
print("newWallet: \(newWallet?.address)")

let operations = [OperationActivateAccount(wallet: newWallet!, andSecret: "9b96803476c82f03516388a95c0cac3dc210b247")]
tezosNodeClient.send(operations: operations, withWallet: newWallet!) { [weak self] (result) in
	switch result {
		case .success(let string):
			print("\n\nAPPLICATION - SEND SUCCESS: \(string)")
			
			self?.tezosNodeClient.getBalance(forAddress: newWallet!.address) { (result) in
				print("Activated account balance: \(result)")
			}
			
		case .failure(let error):
			print("\n\nAPPLICATION - SEND FAILURE: \(error)")
	}
}
*/




/*
let operations = OperationFactory.sendOperation(XTZAmount(fromNormalisedAmount: 5000), of: xtz, from: newWallet!.address, to: "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG")
tezosNodeClient.estimate(operations: operations, withWallet: newWallet!) { [weak self] (result) in
	switch result {
		case .success(let ops):
			
			self?.tezosNodeClient.send(operations: ops, withWallet: newWallet!) { (result) in
				switch result {
					case .success(let string):
						print("\n\nAPPLICATION - SEND SUCCESS: \(string)")
						
					case .failure(let error):
						print("\n\nAPPLICATION - SEND FAILURE: \(error)")
				}
			}
			
		case .failure(let error):
			print("\n\nAPPLICATION - SEND FAILURE: \(error)")
	}
}
*/





// ========================================================================
// TzKT / BetterCallDev / Errors
// ========================================================================

/*
/// tz1XEWeantRAxBYgigRVsnhGsstuXy1V6agD
guard let newWallet = LinearWallet.create(withMnemonic: "beauty income stuff dog north ceiling galaxy flush ghost need adjust quick", passphrase: "") else {
	print("failed to create Bip39 wallet")
	return
}

print("Wallet address: \(newWallet.address)")
print("Wallet mnemonic: \(newWallet.mnemonic)")
*/

/*
tzktClient.refreshTransactionHistory(forAddress: newWallet.address, andSupportedTokens: tokens) { [weak self] in
	let transactions = self?.tzktClient.currentTransactionHistory(filterByToken: nil, orFilterByAddress: nil)
	
	print("\n\n\n")
	let keys = transactions?.keys
	keys?.forEach { (key) in
		print("\n\n\n")
		print("Key: \(key)")
		let txs = transactions?[key]
		txs?.forEach({ (tzktTransaction) in
			print("    \(tzktTransaction)\n")
		})
		print("\n\n\n")
	}
	print("\n\n\n")
	
	
	// Jan 29th
	// 		EXCHANGE	5 USDtz	-> 0.960567 XTZ
	//		EXCHANGE	1 XTZ 	-> 5.174105 USDtz
	// 		SEND		0.1 XTZ		to: tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG
	//		REVEAL
	// 		RECEIEVE 	10 XTZ 		from: tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG
}
*/




/*
// Successful Dexter operation hash (Testnet)
// oo6nzDknLgMEPRnFHxtM4ZtzsZRwDF8HQr7Vodm2QXyMfad4Qvx

// Failed Dexter operation hash (Mainnet)
// oo5XsmdPjxvBAbCyL9kh3x5irUmkWNwUFfi2rfiKqJGKA6Sxjzf


tzktClient.waitForInjection(ofHash: "oo5XsmdPjxvBAbCyL9kh3x5irUmkWNwUFfi2rfiKqJGKA6Sxjzf") { (success, serviceError, operationError) in
	print("Success: \(success)")
	print("ServiceError: \(serviceError)")
	print("OperationError: \(operationError)")
}
*/




// ========================================================================
// Bip44 test
// ========================================================================
/*
print("Bip39 - Start: \(Date())")
guard let bip39Wallet = LinearWallet.create(withMnemonic: "remember smile trip tumble era cube worry fuel bracket eight kitten inform", passphrase: "") else {
	print("failed to create Bip39 wallet")
	return
}

print("Bip39 - address: \(bip39Wallet.address)")	// tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG
print("Bip39 - end: \(Date())\n")


print("Bip44 - Start: \(Date())")
guard let bip44Wallet = HDWallet.create(withMnemonic: "remember smile trip tumble era cube worry fuel bracket eight kitten inform", passphrase: "") else {
	print("failed to create Bip44 wallet")
	return
}

print("Bip44 - address: \(bip44Wallet.address)")	// tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF
print("Bip44 - end: \(Date())\n")



// Try caching and recovering
let walletCacheService = WalletCacheService()
let deleteResult = walletCacheService.deleteCacheAndKeys()
print("DeleteResult: \(deleteResult)\n")

let cacheResult1 = walletCacheService.cache(wallet: bip39Wallet, andPassphrase: nil)
print("CacheResult1: \(cacheResult1)\n")

let cacheResult2 = walletCacheService.cache(wallet: bip44Wallet, andPassphrase: nil)
print("CacheResult2: \(cacheResult2)\n")

let fetchResult = walletCacheService.fetchWallets()
fetchResult?.forEach { (wallet) in
	print("Wallet address: \(wallet.address), \nMnemonic: \(wallet.mnemonic), \nType: \(wallet.type) \n\n")
}
*/


/*
// Send and reveal from Bip39 -> Bip44
let operations = OperationFactory.sendOperation(XTZAmount(fromNormalisedAmount: 0.1), of: xtz, from: bip39Wallet.address, to: bip44Wallet.address)
tezosNodeClient.estimate(operations: operations, withWallet: bip39Wallet) { [weak self] (result) in
	switch result {
		case .success(let ops):
			
			self?.tezosNodeClient.send(operations: ops, withWallet: bip39Wallet) { (result) in
				switch result {
					case .success(let string):
						print("\n\nAPPLICATION - SEND SUCCESS: \(string)")
						
					case .failure(let error):
						print("\n\nAPPLICATION - SEND FAILURE: \(error)")
				}
			}
			
		case .failure(let error):
			print("\n\nAPPLICATION - SEND FAILURE: \(error)")
	}
}
*/

/*
// Send and reveal from Bip44 -> Bip39
let operations = OperationFactory.sendOperation(XTZAmount(fromNormalisedAmount: 0.1), of: xtz, from: bip44Wallet.address, to: bip39Wallet.address)
tezosNodeClient.estimate(operations: operations, withWallet: bip44Wallet) { [weak self] (result) in
	switch result {
		case .success(let ops):
			
			self?.tezosNodeClient.send(operations: ops, withWallet: bip44Wallet) { (result) in
				switch result {
					case .success(let string):
						print("\n\nAPPLICATION - SEND SUCCESS: \(string)")
						
					case .failure(let error):
						print("\n\nAPPLICATION - SEND FAILURE: \(error)")
				}
			}
			
		case .failure(let error):
			print("\n\nAPPLICATION - SEND FAILURE: \(error)")
	}
}
*/







// ========================================================================
// Secure enclave tests
// ========================================================================

//let walletCacheService = WalletCacheService()

/*
let loaded = walletCacheService.loadOrCreateKeys()

if !loaded {
	print("Error: Keys not loaded!")
}

do {
	let ciphertext = try walletCacheService.encrypt("Testing awesome secure enclave or keychain encryption")
	let plaintext = try walletCacheService.decrypt(ciphertext)
	
	print("ciphertext returned: \( ciphertext.toHexString() )")
	print("Plaintext returned: \(plaintext)")
	
	/*
	let encryptedSample = Data(hexString: "04c1a944c32ca48c092a162ecf457f02901bc61b23c187d6a87e91111d2a4b167202429e5d622845fae828776a763460d93e74c51064dfaa9156c685c02c4308686c482a3a8312db0106c9e96cb046fbda2f85dfc8a9f6f2687359eaba04174021f9e6e8f1f7a383699e8d8742639f9a524291f6c7191bcfb520e579366ede40ea85ff25043e") ?? Data()
	let plaintext = try walletCacheService.decrypt(encryptedSample)
	
	print("Plaintext returned: \(plaintext)")
	*/
	
} catch (let error) {
	print("Error: \(error)")
}
*/


/*
let walletCacheItem1 = WalletCacheItem(address: "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG", mnemonic: "remember smile trip tumble era cube worry fuel bracket eight kitten inform", passphrase: nil, sortIndex: 0, type: .linear)
let walletCacheItem2 = WalletCacheItem(address: "tz1bQnUB6wv77AAnvvkX5rXwzKHis6RxVnyF", mnemonic: "remember smile trip tumble era cube worry fuel bracket eight kitten inform", passphrase: nil, sortIndex: 1, type: .hd)
let walletCacheItem3 = WalletCacheItem(address: "tz1W6pmz5w2txuFh5Y2Qzjju8U86EAKW6Kvq", mnemonic: "remember smile trip tumble era cube worry fuel bracket eight kitten inform", passphrase: "superStrongPassword", sortIndex: 2, type: .hd)


let saveResult = walletCacheService.save(walletItems: [walletCacheItem1, walletCacheItem2, walletCacheItem3])
print("saveResult: \(saveResult)")

let loadResult = walletCacheService.load()

loadResult.forEach { (wallet) in
	print("Wallet address: \(wallet.address), \nMnemonic: \(wallet.mnemonic), \nType: \(wallet.type) \n\n")
}
*/




// ========================================================================
// Performance test of creating / re-creating wallet
// ========================================================================

/*
print("Start 1: \(Date())")
Wallet.create(withMnemonicOfLength: .twelve) { (wallet) in
	print("End 1: \(Date())")
	print("wallet.address 1: \(wallet?.address ?? "")\n")
	
	DispatchQueue.main.asyncAfter(deadline: .now()+3) {
		print("Start 2: \(Date())")
		let wallet = Wallet.restoreFromKeychain()
		print("End 2: \(Date())")
		print("wallet.address 2: \(wallet?.address ?? "")")
	}
}
*/

// tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG
/*
Wallet.create(withMnemonic: "remember smile trip tumble era cube worry fuel bracket eight kitten inform", writeToKeychain: true) { (wallet) in
	guard let wallet = wallet else {
		print("Error creating wallet")
		return
	}
	
	print("successfully created wallet: \(wallet.address)")
}
*/



/*
// ========================================================================
// Fetching balances
// ========================================================================


tezosNodeClient.getBalance(forTokens: tokens, forAddress: "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG") { errors in
	print("Balances: ")
	
	print("Errors: \(errors ?? [])\n")
	
	for token in tokens {
		print("\(token.symbol): \(token.balance.normalisedRepresentation)")
	}
}
*/




/*
// ========================================================================
// Blockchain Operation
// ========================================================================

tezosNodeClient.getDexterPoolData(forToken: delphi_USDtz, completion: { (poolData) in
	print("xtzPool: \(poolData.xtzPool), tokenPool: \(poolData.tokenPool)")
})
*/






/*
// ========================================================================
// InDEXTerService tests
// ========================================================================

tezosNodeClient.inDEXTerService.fa12Balance(forToken: delphi_USDtz, andOwner: "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG") { (tokenAmount, error) in
	print("InDEXTer - Balance:")
	print("TokenAmount: \(tokenAmount?.description ?? "nil")")
	print("Error: \(String(describing: error))\n")
}

tezosNodeClient.inDEXTerService.fa12Allowance(forToken: delphi_USDtz, owner: "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG", spender: delphi_USDtz.dexterExchangeAddress ?? "") { (tokenAmount, error) in
	print("InDEXTer - Allowance:")
	print("TokenAmount: \(tokenAmount?.description ?? "nil")")
	print("Error: \(String(describing: error))\n")
}
*/





// ========================================================================
// Test estimating and sending XTZ, FA1.2 or dexter swaps
// ========================================================================

/*
guard let bip39Wallet = LinearWallet.create(withMnemonic: "remember smile trip tumble era cube worry fuel bracket eight kitten inform", passphrase: "") else {
	print("failed to create Bip39 wallet")
	return
}

guard let bip44Wallet = HDWallet.create(withMnemonic: "remember smile trip tumble era cube worry fuel bracket eight kitten inform", passphrase: "") else {
	print("failed to create Bip44 wallet")
	return
}


// Send XTZ
let operations = OperationFactory.sendOperation(XTZAmount(fromNormalisedAmount: 0.1), of: Token.xtz(), from: bip39Wallet.address, to: bip44Wallet.address)

// Send USDtz
//let operations = OperationFactory.sendOperation(TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 6), of: delphiUSDtz, from: wallet.address, to: "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG")

// Dexter xtzToToken
//let operations = OperationFactory.dexterXtzToToken(xtzAmount: XTZAmount(fromNormalisedAmount: 1), minTokenAmount: TokenAmount(fromNormalisedAmount: 1, decimalPlaces: 6), token: tokens[2], wallet: newWallet, timeout: 60*20)

// Dexter tokenToXTZ
//let operations = OperationFactory.dexterTokenToXTZ(tokenAmount: TokenAmount(fromNormalisedAmount: 5, decimalPlaces: 6), minXTZAmount: XTZAmount(fromNormalisedAmount: 0.000001), token: tokens[2], currentAllowance: TokenAmount(fromNormalisedAmount: 0, decimalPlaces: 6), wallet: newWallet, timeout: 60*20)

// Force RPC error, invalid destination address
//let operations = OperationFactory.sendOperation(XTZAmount(fromNormalisedAmount: 0.1), of: Token.xtz(), from: newWallet.address, to: "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzABC")

// Force RPC error, insufficient funds
//let operations = OperationFactory.sendOperation(XTZAmount(fromNormalisedAmount: 10000000), of: Token.xtz(), from: newWallet.address, to: "tz1T3QZ5w4K11RS3vy4TXiZepraV9R5GzsxG")

print("operations: \(operations)")

ClientsAndData.shared.tezosNodeClient.estimate(operations: operations, withWallet: bip39Wallet) { (result) in
	switch result {
		case .success(let ops):
			
			ClientsAndData.shared.tezosNodeClient.send(operations: ops, withWallet: bip39Wallet) { (result) in
				switch result {
					case .success(let string):
						print("\n\nAPPLICATION - SEND SUCCESS: \(string)")
					
					case .failure(let error):
						print("\n\nAPPLICATION - SEND FAILURE: \(error)")
				}
			}
		
		case .failure(let error):
			print("\n\nAPPLICATION - SEND FAILURE: \(error)")
	}
}
*/


// ========================================================================
// Full Dexter operation, without any metadata hardcoded
// ========================================================================

/*
// Get a refrence to our wallet
guard let wallet = Wallet.restoreFromKeychain() else {
	print("Error creating wallet")
	return
}
*/

//	xtzToToken

/*
// Get the latest Dexter poolData
tezosNodeClient.getDexterPoolData(forToken: delphi_USDtz) { [weak self] (poolData) in
	guard poolData.xtzPool.toNormalisedDecimal() != 0 && poolData.tokenPool.toNormalisedDecimal() != 0 else {
		print("Pool data returned something empty")
		return
	}
	
	
	// Ask user to enter the amount they want to sell, and choose their perferred slippage and max timeout
	let xtzToSell = XTZAmount(fromNormalisedAmount: 2.5)
	let usersMaxSlippage = 0.02 // 2%
	let usersMaxTimeout: TimeInterval = 60*20 // 20 minutes
	
	
	// Create the calculations for each type of trade
	let dexCalcs = DexterCalculationService.shared
	
	guard let xtzToTokenCalculations = dexCalcs.calculateXtzToToken(xtzToSell: xtzToSell, dexterXtzPool: poolData.xtzPool, dexterTokenPool: poolData.tokenPool, maxSlippage: usersMaxSlippage) else {
		print("Unable to calculate trade")
		return
	}
	
	
	// Create Dexter xtzToToken operation
	let xtzToTokenOperations = OperationFactory.dexterXtzToToken(xtzAmount: xtzToSell, minTokenAmount: xtzToTokenCalculations.minimum, token: delphi_USDtz, wallet: wallet, timeout: usersMaxTimeout)
	
	
	// Estimate and send
	self?.tezosNodeClient.estimate(operations: xtzToTokenOperations, withWallet: wallet) { [weak self] (result) in
		switch result {
			case .success(let ops):
				
				self?.tezosNodeClient.send(operations: ops, withWallet: wallet) { (result) in
					switch result {
						case .success(let string):
							print("\n\nAPPLICATION - SEND SUCCESS: \(string)")
							
						case .failure(let error):
							print("\n\nAPPLICATION - SEND FAILURE: \(error)")
					}
				}
				
			case .failure(let error):
				print("\n\nAPPLICATION - SEND FAILURE: \(error)")
		}
	}
}
*/



//	tokenToXtz

/*
// Get the latest Dexter poolData
tezosNodeClient.getDexterPoolData(forToken: delphi_USDtz) { [weak self] (poolData) in
	guard poolData.xtzPool.toNormalisedDecimal() != 0 && poolData.tokenPool.toNormalisedDecimal() != 0 else {
		print("Pool data returned something empty")
		return
	}
	
	
	// Ask user to enter the amount they want to sell, and choose their perferred slippage and max timeout
	let tokenToSell = TokenAmount(fromNormalisedAmount: 2.5, decimalPlaces: delphi_USDtz.decimalPlaces)
	let usersMaxSlippage = 0.02 // 2%
	let usersMaxTimeout: TimeInterval = 60*20 // 20 minutes
	
	
	// Create the calculations for each type of trade
	let dexCalcs = DexterCalculationService.shared
	
	guard let tokenToXtzCalculations = dexCalcs.calcualteTokenToXTZ(tokenToSell: tokenToSell, dexterXtzPool: poolData.xtzPool, dexterTokenPool: poolData.tokenPool, maxSlippage: usersMaxSlippage),
		  let minimumAsXtzAmount = tokenToXtzCalculations.minimum as? XTZAmount else {
		print("Unable to calculate trade")
		return
	}
	
	
	// Create Dexter tokenToXTZ operation
	
	// Requires fetching the current allowance first
	self?.tezosNodeClient.inDEXTerService.fa12Allowance(forToken: delphi_USDtz, owner: wallet.address, spender: delphi_USDtz.dexterExchangeAddress ?? "") { (tokenAmount, error) in
		guard let allowance = tokenAmount else {
			print("Could not fetch allowance: \(String(describing: error))")
			return
		}
	
		// Create operation
		let tokenToXtzOperations = OperationFactory.dexterTokenToXTZ(tokenAmount: tokenToSell, minXTZAmount: minimumAsXtzAmount, token: delphi_USDtz, currentAllowance: allowance, wallet: wallet, timeout: usersMaxTimeout)
		
		
		// Estimate and send
		self?.tezosNodeClient.estimate(operations: tokenToXtzOperations, withWallet: wallet) { [weak self] (result) in
			switch result {
				case .success(let ops):
					
					self?.tezosNodeClient.send(operations: ops, withWallet: wallet) { (result) in
						switch result {
							case .success(let string):
								print("\n\nAPPLICATION - SEND SUCCESS: \(string)")
								
							case .failure(let error):
								print("\n\nAPPLICATION - SEND FAILURE: \(error)")
						}
					}
					
				case .failure(let error):
					print("\n\nAPPLICATION - SEND FAILURE: \(error)")
			}
		}
	}
}
*/








// ========================================================================
// Fetching balance
// ========================================================================

/*
tezosNodeClient.getBalance(forAddress: "tz1e4hAp7xpjekmXnYe4677ELGA3UxR79EFb") { (result) in
	switch result {
		case .success(let balance):
			print("\n\n\n Success: \(balance) \n\n\n")
		
		case .failure(let error):
			print("\n\n\n Failure: \(error) \n\n\n")
	}
}
*/













// Test Token object

/*
let xtz = Token.xtz()
let xtz2 = Token.xtz()
let xtz3 = Token.xtz()

let usdtz = Token(icon: nil, name: "USD Tez", symbol: "USDtz", tokenType: .fa1_2, decimalPlaces: 8, tokenContractAddress: "", dexterExchangeAddress: "")
usdtz.setBalance(fromRpcAmount: "290000000")

print("1.1: \(xtz.description)")
print("1.2: \(xtz.rpcRepresentation)")
print("1.3: \(xtz.normalisedRepresentation)")
print("1.4: \(xtz.formatNormalisedRepresentation(locale: Locale(identifier: "en-us")) ?? "error")")
print("1.5: \(xtz.formatNormalisedRepresentation(locale: Locale(identifier: "ru_MD")) ?? "error")")
print("1.6: \(xtz.toRpcDecimal() ?? -1)")
print("1.7: \(xtz.toNormalisedDecimal() ?? -1)")


print("\n\n")
xtz2.setBalance(fromRpcAmount: "1000000") // 1 XTZ

print("2.1: \(xtz2.description)")
print("2.2: \(xtz2.rpcRepresentation)")
print("2.3: \(xtz2.normalisedRepresentation)")
print("2.4: \(xtz2.formatNormalisedRepresentation(locale: Locale(identifier: "en-us")) ?? "error")")
print("2.5: \(xtz2.formatNormalisedRepresentation(locale: Locale(identifier: "ru_MD")) ?? "error")")
print("2.6: \(xtz2.toRpcDecimal() ?? -1)")
print("2.7: \(xtz2.toNormalisedDecimal() ?? -1)")


print("\n\n")
xtz3.setBalance(fromNormalisedAmount: 1.47)

print("3.1: \(xtz3.description)")
print("3.2: \(xtz3.rpcRepresentation)")
print("3.3: \(xtz3.normalisedRepresentation)")
print("3.4: \(xtz3.formatNormalisedRepresentation(locale: Locale(identifier: "en-us")) ?? "error")")
print("3.5: \(xtz3.formatNormalisedRepresentation(locale: Locale(identifier: "ru_MD")) ?? "error")")
print("3.6: \(xtz3.toRpcDecimal() ?? -1)")
print("3.7: \(xtz3.toNormalisedDecimal() ?? -1)")


print("\n\n")
let addedTogether = (xtz + xtz2 + xtz3)
print("added together: \(addedTogether.toNormalisedDecimal() ?? -1)")


print("\n\n")
let multiplied = addedTogether * 0.42
print("Multiplied by a dollar value: \(multiplied.description)") // 1.0374



print("\n\n")
usdtz.setBalance(fromRpcAmount: "290000000")

print("4.1: \(usdtz.description)")
print("4.2: \(usdtz.rpcRepresentation)")
print("4.3: \(usdtz.normalisedRepresentation)")
print("4.4: \(usdtz.formatNormalisedRepresentation(locale: Locale(identifier: "en-us")) ?? "error")")
print("4.5: \(usdtz.formatNormalisedRepresentation(locale: Locale(identifier: "ru_MD")) ?? "error")")
print("4.6: \(usdtz.toRpcDecimal() ?? -1)")
print("4.7: \(usdtz.toNormalisedDecimal() ?? -1)")
*/






/*
LedgerService.shared.listenForDevices().sink { completion in
	print("Completion: \(completion)")
	
} receiveValue: { devices in
	print("Devices: \(devices)")
}.store(in: &bag)
*/



/*
LedgerService.shared.connectTo(uuid: "")
	.flatMap({ success -> AnyPublisher<(address: String, publicKey: String), ErrorResponse> in
		if success {
			return LedgerService.shared.getAddress(verify: false)
		} else {
			return AnyPublisher.fail(with: ErrorResponse.unknownError())
		}
	})
	.convertToResult()
	.sink(receiveValue: { addressResult in
		guard let addObj = try? addressResult.get() else {
			let error = (try? addressResult.getError()) ?? ErrorResponse.unknownError()
			print("Error: \(error)")
			return
		}
		
		print("addressObject: \(addObj)")
	})
	.store(in: &bag)
*/


/*
LedgerService.shared.connectTo(uuid: "")
	.flatMap { _ -> AnyPublisher<String, ErrorResponse> in
		return LedgerService.shared.sign(hex: "62fdbc13ff81a3c0ad2cddd581ca6af17813207a76676be04cf336c60b9b906e", parse: false)
	}
	.sink(onError: { error in
		print("Error: \(error)")
		
	}, onSuccess: { signature in
		print("Signature: \(signature)")
	})
	.store(in: &bag)
*/


/*
LedgerService.shared.connectTo(uuid: "")
	.flatMap({ _ in
		return LedgerService.shared.getAddress(verify: false)
	})
	.flatMap({ _ in
		return LedgerService.shared.getAddress(verify: true)
	})
	.sink(receiveCompletion: { completion in
		print("completion: \(completion)")
		
	}, receiveValue: { [weak self] addressObj in
		print("addressObj: \(addressObj)")
		
	})
	.store(in: &bag)
*/
