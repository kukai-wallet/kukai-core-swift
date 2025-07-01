//
//  TaquitoService.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 14/06/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import JavaScriptCore
import os.log

/// Taquito (https://github.com/ecadlabs/taquito) is a popular open source Tezos library written in Typescript and Javascript.
/// Taquito is made up of many separate packages that deal with various aspects of Tezos RPC and Michelson.
/// This serivce class is a wrapper around a small piece of the Taquito library to expose funtionality that would otherwise be time consuming/risky/dangerous to re-implement natively.
/// The JS can now be found on each github release here: https://github.com/ecadlabs/taquito/releases/, by extracting the zip named "taquito-local-forging-vanilla.zip"
public class TaquitoService {
	
	/// Pirvate local copy of a javascript context
	private let jsContext: JSContext
	
	/// Private flag to prevent multiple simultaneous forge's
	private var isForging = false
	
	/// Private flag to prevent multiple simultaneous parse's
	private var isParsing = false
	
	/// Local forger now needs to be aware of the protocol version, so setup can't be done in the init
	/// Setup must be checked at runtime where we can execute an RPC call
	private var isSetup: Bool = false
	
	/// Unique TaquitoService errors
	public enum TaquitoServiceError: Error {
		case alreadyForging
		case alreadyParsing
		case forgerNotSetup
	}
	
	private var lastForgeCompletionHandler: ((Result<String, KukaiError>) -> Void)? = nil
	private var lastParseCompletionHandler: ((Result<OperationPayload, KukaiError>) -> Void)? = nil
	
	/// Public shared instace to avoid having multiple copies of the underlying `JSContext` created
	public static let shared = TaquitoService()
	
	
	
	
	
	// MARK: - Init
	
	/// Private Init to setup the Javascript Context, find and parse the Taquito file, and setup the `LocalForger` object.
	private init() {
		jsContext = JSContext()
		jsContext.exceptionHandler = { [weak self] context, exception in
			Logger.taquitoService.error("Taquito JSContext exception: \(exception?.toString() ?? "")")
			
			if self?.isForging == true, let lastForge = self?.lastForgeCompletionHandler {
				self?.isForging = false
				lastForge(Result.failure(KukaiError.unknown(withString: exception?.toString() ?? "")))
				
			} else if self?.isParsing == true, let lastParse = self?.lastParseCompletionHandler {
				self?.isParsing = false
				lastParse(Result.failure(KukaiError.unknown(withString: exception?.toString() ?? "")))
			}
		}
	}
	
	private func setup(protocolHash: String?) -> Bool {
		guard !isSetup else { return true } // Simply calling logic, allow it to always be called
		guard let hash = protocolHash else { return false }
		
		if let jsSourcePath = Bundle.module.url(forResource: "taquito_local_forging", withExtension: "js") {
			do {
				let jsSourceContents = try String(contentsOf: jsSourcePath)
				self.jsContext.evaluateScript(jsSourceContents)
				self.jsContext.evaluateScript("var forger = new taquito_local_forging.LocalForger(\"\(hash)\");")
				self.isSetup = true
				return true
				
			} catch (let error) {
				Logger.taquitoService.error("Error parsing dexter javascript file: \(error)")
				return false
			}
		}
		
		return false
	}
	
	
	
	
	// MARK: - @taquito/local-forging
	
	/**
	Wrapper around the node package @taquito/local-forging's forge method. Giving the ability to locally forge an `OperationPayload` without using an RPC, and avoiding the need to do an RPC parse against a second server.
	Note: Currently only one forge can take place at a time. Multiple simultaneous calls will result in an error being returned.
	See package: https://github.com/ecadlabs/taquito/tree/master/packages/taquito-local-forging, and docs: https://tezostaquito.io/typedoc/modules/_taquito_local_forging.html
	- parameter operationPayload: The payload to forge. Can be constructed using `OperationFactory.operationPayload(...)`.
	- parameter protocolHash: The payload has an optional slot for protocol, however the RPC will return an error on some RPCs, if its included due to strict JSON rules. So we need to duplicate this field as forging is too early in the process
	- parameter completion: The underlying javascript code uses a Promise. In order to wrap this up into native Swift, we need to provide a completion callback to return the resulting hex string.
	*/
	public func forge(operationPayload: OperationPayload, protocolHash: String, completion: @escaping((Result<String, KukaiError>) -> Void)) {
		if !setup(protocolHash: protocolHash) {
			completion(Result.failure(KukaiError.internalApplicationError(error: TaquitoServiceError.forgerNotSetup)))
			return
		}
		
		if isForging {
			// To avoid setting up a delgate pattern for something that should be synchronous, we only include 1 set of success/errors handlers inside the code at any 1 time
			// Calling it multiple times at the same time could result in strange behaviour
			completion(Result.failure(KukaiError.internalApplicationError(error: TaquitoServiceError.alreadyForging)))
			return
		}
		
		lastForgeCompletionHandler = completion
		isForging = true
		
		// Assign callback handlers for internal JS promise success and error states
		let forgeSuccessHandler: @convention(block) (String) -> Void = { [weak self] (result) in
			Logger.taquitoService.info("JavascriptContext forge successful")
			self?.isForging = false
			self?.lastForgeCompletionHandler = nil
			completion(Result.success(result))
			return
		}
		let forgeSuccessBlock = unsafeBitCast(forgeSuccessHandler, to: AnyObject.self)
		jsContext.setObject(forgeSuccessBlock, forKeyedSubscript: "forgeSuccessHandler" as (NSCopying & NSObjectProtocol))
		
		let forgeErrorHandler: @convention(block) (String) -> Void = { [weak self] (result) in
			Logger.taquitoService.error("JavascriptContext forge error: \(result)")
			self?.isForging = false
			self?.lastForgeCompletionHandler = nil
			completion(Result.failure(KukaiError.unknown(withString: result)))
			return
		}
		let forgeErrorBlock = unsafeBitCast(forgeErrorHandler, to: AnyObject.self)
		jsContext.setObject(forgeErrorBlock, forKeyedSubscript: "forgeErrorHandler" as (NSCopying & NSObjectProtocol))
		
		
		do {
			// Convert payload into JSON string
			let jsonData = try JSONEncoder().encode(operationPayload)
			let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
			
			// Wrap up the internal call to the forger and pass the promises back to the swift handler blocks
			let _ = jsContext.evaluateScript("""
				forger.forge(\(jsonString)).then(
					function(value) { forgeSuccessHandler(value) },
					function(error) { forgeErrorHandler( JSON.stringify(error) ) }
				);
				""")
			
		} catch (let error) {
			Logger.taquitoService.error("JavascriptContext forge error: \(error)")
			isForging = false
			lastForgeCompletionHandler = nil
			completion(Result.failure(KukaiError.internalApplicationError(error: error)))
			return
		}
	}
	
	/**
	Wrapper around the node package @taquito/local-forging's prase method. Giving the ability to locally parse a hex string back into an `OperationPayload`, without the need to use an RPC on a tezos node.
	Note: Currently only one parse can take place at a time. Multiple simultaneous calls will result in an error being returned
	See package: https://github.com/ecadlabs/taquito/tree/master/packages/taquito-local-forging, and docs: https://tezostaquito.io/typedoc/modules/_taquito_local_forging.html
	- parameter hex: The string that needs to be parsed into an `OperationPayload`.
	- parameter completion: The underlying javascript code uses a Promise. In order to wrap this up into native Swift, we need to provide a completion callback to return the resulting object
	*/
	public func parse(hex: String, completion: @escaping((Result<OperationPayload, KukaiError>) -> Void)) {
		if !isSetup {
			completion(Result.failure(KukaiError.internalApplicationError(error: TaquitoServiceError.forgerNotSetup)))
			return
		}
		
		if isParsing {
			// To avoid setting up a delgate pattern for something that should be synchronous, we only include 1 set of success/errors handlers inside the code at any 1 time
			// Calling it multiple times at the same time could result in strange behaviour
			completion(Result.failure(KukaiError.internalApplicationError(error: TaquitoServiceError.alreadyParsing)))
			return
		}
		
		lastParseCompletionHandler = completion
		isParsing = true
		
		// Assign callback handlers for internal JS promise success and error states
		let parseSuccessHandler: @convention(block) (String) -> Void = { [weak self] (result) in
			Logger.taquitoService.info("JavascriptContext parse successful")
			self?.lastParseCompletionHandler = nil
			self?.isParsing = false
			
			if let obj = try? JSONDecoder().decode(OperationPayload.self, from: result.data(using: .utf8) ?? Data()) {
				completion(Result.success(obj))
			} else {
				completion(Result.failure(KukaiError.unknown()))
			}
			
			return
		}
		let parseSuccessBlock = unsafeBitCast(parseSuccessHandler, to: AnyObject.self)
		jsContext.setObject(parseSuccessBlock, forKeyedSubscript: "parseSuccessHandler" as (NSCopying & NSObjectProtocol))
		
		let parseErrorHandler: @convention(block) (String) -> Void = { [weak self] (result) in
			Logger.taquitoService.error("JavascriptContext parse error: \(result)")
			self?.lastParseCompletionHandler = nil
			self?.isParsing = false
			completion(Result.failure(KukaiError.unknown(withString: result)))
			return
		}
		let praseErrorBlock = unsafeBitCast(parseErrorHandler, to: AnyObject.self)
		jsContext.setObject(praseErrorBlock, forKeyedSubscript: "parseErrorHandler" as (NSCopying & NSObjectProtocol))
		
		
		// Wrap up the internal call to the forger and pass the promises back to the swift handler blocks
		let _ = jsContext.evaluateScript("""
			forger.parse('\(hex)').then(
				function(value) { parseSuccessHandler( JSON.stringify(value) ) },
				function(error) { parseErrorHandler(error) }
			);
			""")
	}
}
