//
//  LedgerService.swift
//  
//
//  Created by Simon Mcloughlin on 17/09/2021.
//

import Foundation
import KukaiCryptoSwift
import JavaScriptCore
import CoreBluetooth
import Combine
import os.log



/**
A service class to wrap up all the complicated interactions with CoreBluetooth and the modified version of ledgerjs, needed to communicate with a Ledger Nano X.

Ledger only provide a ReactNative module for third parties to integrate with. The architecture of the module also makes it very difficult to
integrate with native mobile (if it can be packaged up) as it relies heavily on long observable chains passing through many classes and functions.
To overcome this, I copied the base logic from multiple ledgerjs classes into a single typescript file and split the functions up into more of a utility style class, where
each function returns a result, that must be passed into another function. This allowed the creation of a swift class to sit in the middle of these
functions and decide what to do with the responses.

The modified typescript can be found in this file (under a fork of the main repo) https://github.com/simonmcl/ledgerjs/blob/native-mobile/packages/hw-app-tezos/src/NativeMobileTezos.ts .
The containing package also includes a webpack file, which will package up the typescript and its dependencies into mobile friendly JS file, which
needs to be included in the swift project. Usage of the JS can be seen below.

**NOTE:** this modified typescript is Tezos only as I was unable to find a way to simply subclass their `Transport` class, to produce a re-usable
NativeMobile transport. The changes required modifiying the app and other class logic which became impossible to refactor back into the project, without rewriting everything.
*/
public class LedgerService: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate {
	
	// MARK: - Types / Constants
	
	/// Ledger UUID constants
	struct LedgerNanoXConstant {
		static let serviceUUID = CBUUID(string: "13d63400-2c97-0004-0000-4c6564676572")
		static let notifyUUID = CBUUID(string: "13d63400-2c97-0004-0001-4c6564676572")
		static let writeUUID = CBUUID(string: "13d63400-2c97-0004-0002-4c6564676572")
	}
	
	/// Instead of returning data, sometimes ledger returns a code to indicate that so far the message have been received successfully
	public static let successCode = "9000"
	
	/// General Ledger error codes, pulled from the source, and some additional ones added for native swift issues
	public enum GeneralErrorCodes: String, Error, Codable {
		case PIN_REMAINING_ATTEMPTS = "63c0"
		case INCORRECT_LENGTH = "6700"
		case MISSING_CRITICAL_PARAMETER = "6800"
		case COMMAND_INCOMPATIBLE_FILE_STRUCTURE = "6981"
		case SECURITY_STATUS_NOT_SATISFIED = "6982"
		case CONDITIONS_OF_USE_NOT_SATISFIED = "6985"
		case INCORRECT_DATA = "6a80"
		case NOT_ENOUGH_MEMORY_SPACE = "6a84"
		case REFERENCED_DATA_NOT_FOUND = "6a88"
		case FILE_ALREADY_EXISTS = "6a89"
		case INCORRECT_P1_P2 = "6b00"
		case INS_NOT_SUPPORTED = "6d00"
		case CLA_NOT_SUPPORTED = "6e00"
		case TECHNICAL_PROBLEM = "6f00"
		case MEMORY_PROBLEM = "9240"
		case NO_EF_SELECTED = "9400"
		case INVALID_OFFSET = "9402"
		case FILE_NOT_FOUND = "9404"
		case INCONSISTENT_FILE = "9408"
		case ALGORITHM_NOT_SUPPORTED = "9484"
		case INVALID_KCV = "9485"
		case CODE_NOT_INITIALIZED = "9802"
		case ACCESS_CONDITION_NOT_FULFILLED = "9804"
		case CONTRADICTION_SECRET_CODE_STATUS = "9808"
		case CONTRADICTION_INVALIDATION = "9810"
		case CODE_BLOCKED = "9840"
		case MAX_VALUE_REACHED = "9850"
		case GP_AUTH_FAILED = "6300"
		case LICENSING = "6f42"
		case HALTED = "6faa"
		
		case APP_CLOSED = "6e01"
		case DEVICE_LOCKED = "009000"
		case UNKNOWN = "99999999"
		case NO_WRITE_CHARACTERISTIC = "99999996"
	}
	
	/// Dedicated error codes pulled from the Ledger tezos app
	public enum TezosAppErrorCodes: String, Error, Codable {
		case EXC_WRONG_PARAM = "6B00"
		case EXC_WRONG_LENGTH = "6C00"
		case EXC_INVALID_INS = "6D00"
		case EXC_WRONG_LENGTH_FOR_INS = "917E"
		case EXC_REJECT = "6985"
		case EXC_PARSE_ERROR = "9405"
		case EXC_REFERENCED_DATA_NOT_FOUND = "6A88"
		case EXC_WRONG_VALUES = "6A80"
		case EXC_SECURITY = "6982"
		case EXC_HID_REQUIRED = "6983"
		case EXC_CLASS = "6E00"
		case EXC_MEMORY_ERROR = "9200"
	}
	
	/// Used to keep track of what request the user is making to the Ledger, as we have to pass through many many different fucntions / callbacks
	private enum RequestType {
		case address
		case signing
		case none
	}
	
	
	
	
	
	// MARK: - Properties
	
	private let jsContext: JSContext
	private var centralManager: CBCentralManager?
	private var connectedDevice: CBPeripheral?
	private var writeCharacteristic: CBCharacteristic?
	private var notifyCharacteristic: CBCharacteristic?
	
	private var requestedUUID: String? = nil
	private var requestType: RequestType = .none
	private var deviceList: [String: String] = [:] {
		didSet {
			deviceListPublisher.send(deviceList)
		}
	}
	
	/// Be notified when the ledger device returns a success message, part way through the process.
	/// This can be useful to indicate to users that the request has succeed, but s waiting on input on the Ledger device to continue
	@Published public var partialSuccessMessageReceived: Bool = false
	
	@Published private var bluetoothSetup: Bool = false
	
	private var receivedAPDU_statusCode = PassthroughSubject<String, Never>()
	private var receivedAPDU_payload = PassthroughSubject<String, Never>()
	
	private var writeToLedgerSubject = PassthroughSubject<String, Never>()
	private var deviceListPublisher = PassthroughSubject<[String: String], KukaiError>()
	private var deviceConnectedPublisher = PassthroughSubject<Bool, KukaiError>()
	private var addressPublisher = PassthroughSubject<(address: String, publicKey: String), KukaiError>()
	private var signaturePublisher = PassthroughSubject<String, KukaiError>()
	
	private var bag_connection = Set<AnyCancellable>()
	private var bag_writer = Set<AnyCancellable>()
	private var bag_apdu = Set<AnyCancellable>()
	private var bag_addressFetcher = Set<AnyCancellable>()
	private var counter = 0
	
	/// Public shared instace to avoid having multiple copies of the underlying `JSContext` created
	public static let shared = LedgerService()
	
	
	
	
	
	// MARK: - Init
	
	private override init() {
		jsContext = JSContext()
		jsContext.exceptionHandler = { context, exception in
			Logger.ledger.error("Ledger JSContext exception: \(exception?.toString() ?? "")")
		}
		
		
		// Grab the custom ledger tezos app js and load it in
		if let jsSourcePath = Bundle.module.url(forResource: "ledger_app_tezos", withExtension: "js") {
			do {
				let jsSourceContents = try String(contentsOf: jsSourcePath)
				self.jsContext.evaluateScript(jsSourceContents)
				
			} catch (let error) {
				Logger.ledger.error("Error parsing Ledger javascript file: \(error)")
			}
		}
		
		super.init()
		
		
		// Register a native function, to be passed into the js functions, that will write chunks of data to the device
		let nativeWriteHandler: @convention(block) (String, Int) -> Void = { [weak self] (apdu, expectedNumberOfAPDUs) in
			Logger.ledger.info("Inside nativeWriteHandler")
			
			// Keep track of the number of times its called for each request
			self?.counter += 1
			
			
			// Convert the supplied data into an APDU. Returns a single string per ADPU, but broken up into chunks, seperated by spaces for each maximum sized data packet
			guard let sendAPDU = self?.jsContext.evaluateScript("ledger_app_tezos.sendAPDU(\"\(apdu)\", 20)").toString() else {
				self?.deviceConnectedPublisher.send(false)
				return
			}
			
			
			// Add the APDU chunked string to be added to the write subject
			self?.writeToLedgerSubject.send(sendAPDU)
			
			
			// When all messages recieved, call completion to trigger the messages one by one
			if self?.counter == expectedNumberOfAPDUs {
				self?.writeToLedgerSubject.send(completion: .finished)
				self?.counter = 0
			}
		}
		let nativeWriteHandlerBlock = unsafeBitCast(nativeWriteHandler, to: AnyObject.self)
		jsContext.setObject(nativeWriteHandlerBlock, forKeyedSubscript: "nativeWriteData" as (NSCopying & NSObjectProtocol))
		
		
		// Setup a JS ledger tezos app, bound to the nativeWriteHandler
		let _ = jsContext.evaluateScript("""
			var nativeTransport = new ledger_app_tezos.NativeTransport(nativeWriteData)
			var tezosApp = new ledger_app_tezos.Tezos(nativeTransport)
		""")
	}
	
	
	
	
	
	// MARK: - Public functions
	
	/**
	Setup the bluetooth manager, ready to scan or connect to devices
	*/
	private func setupBluetoothConnection() -> Future<Bool, Never> {
		if centralManager != nil {
			return Just(true).asFuture()
		}
		
		centralManager = CBCentralManager(delegate: self, queue: nil)
		return $bluetoothSetup.dropFirst().asFuture()
	}
	
	/**
	Start listening for ledger devices
	 - returns: Publisher with a dictionary of `[UUID: deviceName]` or an `KukaiError`
	*/
	public func listenForDevices() -> AnyPublisher<[String: String], KukaiError> {
		self.deviceListPublisher = PassthroughSubject<[String: String], KukaiError>()
		
		self.setupBluetoothConnection()
			.sink { [weak self] value in
				if !value {
					self?.deviceListPublisher.send(completion: .failure(KukaiError.unknown()))
				}
				
				self?.centralManager?.scanForPeripherals(withServices: [LedgerNanoXConstant.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
				self?.bag_connection.removeAll()
			}
			.store(in: &self.bag_connection)
		
		return self.deviceListPublisher.eraseToAnyPublisher()
	}
	
	/**
	Stop listening for and reporting new ledger devices found
	*/
	public func stopListening() {
		self.centralManager?.stopScan()
		self.deviceList = [:]
		self.deviceListPublisher.send(completion: .finished)
	}
	
	/**
	Connect to a ledger device by a given UUID
	 - returns: Publisher which will indicate true / false, or return an `KukaiError` if it can't connect to bluetooth
	*/
	public func connectTo(uuid: String) -> AnyPublisher<Bool, KukaiError> {
		if self.connectedDevice != nil, self.connectedDevice?.identifier.uuidString == uuid, self.connectedDevice?.state == .connected {
			return AnyPublisher.just(true)
		}
		
		self.setupBluetoothConnection()
			.sink { [weak self] value in
				if !value {
					self?.deviceConnectedPublisher.send(completion: .failure(KukaiError.unknown()))
				}
				
				self?.requestedUUID = uuid
				self?.centralManager?.scanForPeripherals(withServices: [LedgerNanoXConstant.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
				self?.bag_connection.removeAll()
			}
			.store(in: &self.bag_connection)
		
		return self.deviceConnectedPublisher.eraseToAnyPublisher()
	}
	
	/**
	Disconnect from the current Ledger device
	 - returns: A Publisher with a boolean, or `KukaiError` if soemthing goes wrong
	*/
	public func disconnectFromDevice() {
		if let device = self.connectedDevice {
			self.centralManager?.cancelPeripheralConnection(device)
		}
		
		requestedUUID = nil
	}
	
	/**
	Get the UUID of the connected device
	 - returns: a string if it can be found
	*/
	public func getConnectedDeviceUUID() -> String? {
		if self.connectedDevice?.state == .connected {
			return self.connectedDevice?.identifier.uuidString
		} else {
			return nil
		}
	}
	
	/**
	Get a TZ address and public key from the current connected Ledger device
	- parameter forDerivationPath: Optional. The derivation path to use to extract the address from the underlying HD wallet
	- parameter curve: Optional. The `EllipticalCurve` to use to extract the address
	- parameter verify: Whether or not to ask the ledger device to prompt the user to show them what the TZ address should be, to ensure the mobile matches
	- returns: A publisher which will return a tuple containing the address and publicKey, or an `KukaiError`
	*/
	public func getAddress(forDerivationPath derivationPath: String = HD.defaultDerivationPath, curve: EllipticalCurve = .ed25519, verify: Bool) -> AnyPublisher<(address: String, publicKey: String), KukaiError> {
		self.setupWriteSubject()
		self.requestType = .address
		
		var selectedCurve = 0
		switch curve {
			case .ed25519:
				selectedCurve = 0
				
			case .secp256k1:
				selectedCurve = 1
		}
		
		let _ = jsContext.evaluateScript("tezosApp.getAddress(\"\(derivationPath)\", {verify: \(verify), curve: \(selectedCurve)})")
		
		// return the addressPublisher, but listen for the returning of values and use this as an oppertunity to clean up the lingering cancellables, as it only returns one at a time
		return addressPublisher.onReceiveOutput({ _ in
			self.bag_apdu.removeAll()
			self.bag_writer.removeAll()
		}).eraseToAnyPublisher()
	}
	
	/**
	 Get a TZ address and public key from the current connected Ledger device
	 - parameter forDerivationPath: Optional. The derivation path to use to extract the address from the underlying HD wallet
	 - parameter curve: Optional. The `EllipticalCurve` to use to extract the address
	 - parameter verify: Whether or not to ask the ledger device to prompt the user to show them what the TZ address should be, to ensure the mobile matches
	 - returns: An async `Result` object, allowing code to be triggered via while loops more easily
	 */
	public func getAddress(forDerivationPath derivationPath: String = HD.defaultDerivationPath, curve: EllipticalCurve = .ed25519, verify: Bool) async -> Result<(address: String, publicKey: String), KukaiError> {
		return await withCheckedContinuation({ continuation in
			var cancellable: AnyCancellable!
			cancellable = getAddress(forDerivationPath: derivationPath, curve: curve, verify: verify)
				.sink(onError: { error in
					continuation.resume(returning: Result.failure(error))
				}, onSuccess: { addressObj in
					continuation.resume(returning: Result.success(addressObj))
				}, onComplete: { [weak self] in
					self?.bag_addressFetcher.remove(cancellable)
				})
			
			cancellable.store(in: &bag_addressFetcher)
		})
	}
	
	/**
	Sign an operation payload with the underlying secret key, returning the signature
	- parameter hex: An operation converted to JSON, forged and watermarked, converted to a hex string. (Note: there are some issues with the ledger app signing batch transactions. May simply return no result at all. Can't run REVEAL and TRANSACTION together for example)
	- parameter forDerivationPath: Optional. The derivation path to use to extract the address from the underlying HD wallet
	- parameter parse: Ledger can parse non-hashed (blake2b) hex data and display operation data to user (e.g. transfer 1 XTZ to TZ1abc, for fee: 0.001). There are many limitations around what can be parsed. Frequnetly it will require passing in false
	- returns: A Publisher which will return a string containing the hex signature, or an `KukaiError`
	*/
	public func sign(hex: String, forDerivationPath derivationPath: String = HD.defaultDerivationPath, parse: Bool) -> AnyPublisher<String, KukaiError>  {
		self.setupWriteSubject()
		self.signaturePublisher = PassthroughSubject<String, KukaiError>()
		self.requestType = .signing
		
		let _ = jsContext.evaluateScript("tezosApp.signOperation(\"\(derivationPath)\", \"\(hex)\", \(parse))")
		
		// return the addressPublisher, but listen for the returning of values and use this as an oppertunity to clean up the lingering cancellables, as it only returns one at a time
		return signaturePublisher.onReceiveOutput({ _ in
			self.bag_apdu.removeAll()
			self.bag_writer.removeAll()
		}).eraseToAnyPublisher()
	}
	
	
	
	
	
	// MARK: - Bluetooth
	
	/// CBCentralManagerDelegate function, must be marked public because of protocol definition
	public func centralManagerDidUpdateState(_ central: CBCentralManager) {
		Logger.ledger.info("centralManagerDidUpdateState")
		self.bluetoothSetup = (central.state == .poweredOn)
	}
	
	/// CBCentralManagerDelegate function, must be marked public because of protocol definition
	public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		
		// If we have been requested to connect to a speicific UUID, only listen for that one and connect immediately if found
		if let requested = self.requestedUUID, peripheral.identifier.uuidString == requested {
			Logger.ledger.info("Found requested ledger UUID, connecting ...")
			
			self.connectedDevice = peripheral
			self.centralManager?.connect(peripheral, options: ["requestMTU": 156])
			self.centralManager?.stopScan()
		
		// Else if we haven't been requested to find a specific one, store each unique device and fire a delegate callback, until scan stopped manually
		} else if self.requestedUUID == nil, deviceList[peripheral.identifier.uuidString] == nil {
			Logger.ledger.info("Found a new ledger device. Name: \(peripheral.name ?? "-"), UUID: \(peripheral.identifier.uuidString)")
			
			self.deviceList[peripheral.identifier.uuidString] = peripheral.name ?? ""
		}
	}
	
	/// CBCentralManagerDelegate function, must be marked public because of protocol definition
	public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		Logger.ledger.info("Connected to \(peripheral.name ?? ""), \(peripheral.identifier.uuidString)")
		
		// record the connected device and set LedgerService as the delegate. Don't report successfully connected to ledgerService.delegate until
		// we have received the callbacks for services and characteristics. Otherwise we can't use the device
		self.connectedDevice = peripheral
		self.connectedDevice?.delegate = self
		self.connectedDevice?.discoverServices([LedgerNanoXConstant.serviceUUID])
	}
	
	/// CBCentralManagerDelegate function, must be marked public because of protocol definition
	public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		Logger.ledger.info("Failed to connect to \(peripheral.name ?? ""), \(peripheral.identifier.uuidString)")
		self.connectedDevice = nil
		self.requestedUUID = nil
		self.notifyCharacteristic = nil
		self.writeCharacteristic = nil
		self.deviceConnectedPublisher.send(false)
	}
	
	/// CBCentralManagerDelegate function, must be marked public because of protocol definition
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let services = peripheral.services else {
			Logger.ledger.info("Unable to locate services for: \(peripheral.name ?? ""), \(peripheral.identifier.uuidString). Error: \(error)")
			self.connectedDevice = nil
			self.requestedUUID = nil
			self.notifyCharacteristic = nil
			self.writeCharacteristic = nil
			self.deviceConnectedPublisher.send(false)
			return
		}
		
		for service in services {
			if service.uuid == LedgerNanoXConstant.serviceUUID {
				peripheral.discoverCharacteristics(nil, for: service)
				return
			}
		}
	}
	
	public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
		Logger.ledger.info("Disconnected: \(peripheral.name ?? ""), \(peripheral.identifier.uuidString). Error: \(error)")
		self.connectedDevice = nil
		self.requestedUUID = nil
		self.notifyCharacteristic = nil
		self.writeCharacteristic = nil
		self.deviceConnectedPublisher.send(false)
	}
	
	public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: (any Error)?) {
		Logger.ledger.info("Disconnected: \(peripheral.name ?? ""), \(peripheral.identifier.uuidString). Error: \(error)")
		self.connectedDevice = nil
		self.requestedUUID = nil
		self.notifyCharacteristic = nil
		self.writeCharacteristic = nil
		self.deviceConnectedPublisher.send(false)
	}
	
	/// CBCentralManagerDelegate function, must be marked public because of protocol definition
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		guard let characteristics = service.characteristics else {
			Logger.ledger.info("Unable to locate characteristics for: \(peripheral.name ?? ""), \(peripheral.identifier.uuidString). Error: \(error)")
			self.connectedDevice = nil
			self.requestedUUID = nil
			self.notifyCharacteristic = nil
			self.writeCharacteristic = nil
			self.deviceConnectedPublisher.send(false)
			return
		}
		
		for characteristic in characteristics {
			if characteristic.uuid == LedgerNanoXConstant.writeUUID {
				Logger.ledger.info("Located write characteristic")
				writeCharacteristic = characteristic
				
			} else if characteristic.uuid == LedgerNanoXConstant.notifyUUID {
				Logger.ledger.info("Located notify characteristic")
				notifyCharacteristic = characteristic
			}
			
			if let _ = writeCharacteristic, let notify = notifyCharacteristic {
				Logger.ledger.info("Registering for notifications on notify characteristic")
				peripheral.setNotifyValue(true, for: notify)
				
				self.deviceConnectedPublisher.send(true)
				return
			}
		}
	}
	
	/// CBCentralManagerDelegate function, must be marked public because of protocol definition
	public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		if let err = error {
			Logger.ledger.error("Error during write: \(err)")
			returnErrorToPublisher(statusCode: GeneralErrorCodes.UNKNOWN.rawValue)
			
		} else {
			Logger.ledger.info("Successfully wrote to write characteristic")
		}
	}
	
	/// CBCentralManagerDelegate function, must be marked public because of protocol definition
	public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		guard characteristic.uuid == LedgerNanoXConstant.notifyUUID else {
			return
		}
		
		Logger.ledger.info("Receiveing value from notify characteristic")
		
		
		// Extract the payload, convert it to an APDU so the result can be extracted
		let hexString = characteristic.value?.toHexString() ?? "-"
		let receivedResult = jsContext.evaluateScript("""
			var result = ledger_app_tezos.receiveAPDU(\"\(hexString)\")
			
			if (result.error === "null") {
				result.data
			} else {
				"Error: " + result.error
			}
		""")
		
		
		// Check for issues
		guard let resultString = receivedResult?.toString(), String(resultString.prefix(5)) != "Error" else {
			returnErrorToPublisher(statusCode: GeneralErrorCodes.UNKNOWN.rawValue)
			return
		}
		
		
		if resultString.count <= 6 {
			Logger.ledger.info("Received APDU Status code")
			receivedAPDU_statusCode.send(resultString)
			
			if resultString == LedgerService.successCode {
				partialSuccessMessageReceived = true
			}
			
			return
			
		} else {
			Logger.ledger.info("Received APDU Payload")
			receivedAPDU_payload.send(resultString)
			return
		}
	}
	
	
	
	
	
	// MARK: - Private helpers
	
	/// Setup the listeners to the `writeToLedgerSubject` that will ultimately return results to the developers code
	private func setupWriteSubject() {
		self.writeToLedgerSubject = PassthroughSubject<String, Never>()
		self.addressPublisher = PassthroughSubject<(address: String, publicKey: String), KukaiError>()
		self.signaturePublisher = PassthroughSubject<String, KukaiError>()
		
		// Tell write subject to wait for completion message
		self.writeToLedgerSubject
			.collect()
			.sink { [weak self] apdus in
				guard let self = self, let writeChar = self.writeCharacteristic else {
					Logger.ledger.error("setupWriteSubject - couldn't find self/write")
					return
					
				}
				
				
				// go through APDU chunked strings and convert into Deferred Futures, that don't execute any code until subscribed too
				var futures: [Deferred<Future<String?, KukaiError>>] = []
				for apdu in apdus {
					futures.append(self.sendAPDU(apdu: apdu, writeCharacteristic: writeChar))
				}
				
				
				// Convert array of deferred futures into a single concatenated publisher.
				// When subscribed too, it will wait for one piblisher to finish, before assigning subscriber to next.
				// This allows us to run the code for + send each APDU and wait a response from the device, before moving to the next APDU.
				// This allows us to catch errors when they first occur, and return immeidately, instead of firing error for each APDU packet, causing UI issues
				guard let concatenatedPublishers = futures.concatenatePublishers() else {
					Logger.ledger.error("setupWriteSubject - unable to create concatenatedPublishers")
					return
				}
				
				
				// Get the result of the concatenated publisher, whether it be successful payload, or error
				concatenatedPublishers
					.last()
					.convertToResult()
					.sink { concatenatedResult in
						
						guard let res = try? concatenatedResult.get() else {
							let error = (try? concatenatedResult.getError()) ?? KukaiError.unknown()
							Logger.ledger.error("setupWriteSubject - received error: \(error)")
							self.returnKukaiErrorToPublisher(kukaiError: error)
							return
						}
						
						Logger.ledger.info("setupWriteSubject - received value: \(res)")
						switch self.requestType {
							case .address:
								self.convertAPDUToAddress(payload: res)
								
							case .signing:
								self.convertAPDUToSignature(payload: res)
							
							case .none:
								Logger.ledger.error("Received a value, but no request type set")
						}
					}
					.store(in: &self.bag_writer)
			}
			.store(in: &bag_writer)
	}
	
	/// Create a Deferred Future to send a single APDU and respond with a success / failure based on the result of the notify characteristic
	private func sendAPDU(apdu: String, writeCharacteristic: CBCharacteristic) -> Deferred<Future<String?, KukaiError>> {
		return Deferred {
			Future<String?, KukaiError> { [weak self] promise in
				guard let self = self else {
					Logger.ledger.error("sendAPDU - couldn't find self")
					promise(.failure(KukaiError.unknown()))
					return
				}
				
				// String is split by spaces, write each componenet seperately to the bluetooth queue
				let components = apdu.components(separatedBy: " ")
				for component in components {
					if component != "" {
						let data = Data(hexString: component) ?? Data()
						
						Logger.ledger.info("sendAPDU - writing payload")
						self.connectedDevice?.writeValue(data, for: writeCharacteristic, type: .withResponse)
					}
				}
				
				
				// Listen for responses
				self.receivedAPDU_statusCode.sink { statusCode in
					if statusCode == LedgerService.successCode {
						Logger.ledger.info("sendAPDU - received success statusCode")
						promise(.success(nil))
						
					} else {
						Logger.ledger.error("sendAPDU - received error statusCode: \(statusCode)")
						promise(.failure( self.kukaiErrorFrom(statusCode: statusCode) ))
						
					}
				}
				.store(in: &self.bag_apdu)
				
				
				self.receivedAPDU_payload.sink { payload in
					Logger.ledger.info("sendAPDU - received payload: \(payload)")
					promise(.success(payload))
				}
				.store(in: &self.bag_apdu)
			}
		}
	}
	
	/// Take in a payload string from an APDU, and call the necessary JS function to convert it to an address / publicKey. Also will fire to the necessary publisher
	private func convertAPDUToAddress(payload: String?) {
		guard let payload = payload else {
			returnErrorToPublisher(statusCode: GeneralErrorCodes.UNKNOWN.rawValue)
			return
		}
		
		guard let dict = jsContext.evaluateScript("ledger_app_tezos.convertAPDUtoAddress(\"\(payload)\")").toObject() as? [String: String] else {
			Logger.ledger.error("Didn't receive address object")
			returnErrorToPublisher(statusCode: GeneralErrorCodes.UNKNOWN.rawValue)
			return
		}
		
		guard let address = dict["address"], let publicKey = dict["publicKey"] else {
			if let err = dict["error"] {
				Logger.ledger.error("Internal script error: \(err)")
				returnErrorToPublisher(statusCode: GeneralErrorCodes.UNKNOWN.rawValue)
				
			} else {
				Logger.ledger.error("Unknown error")
				returnErrorToPublisher(statusCode: GeneralErrorCodes.UNKNOWN.rawValue)
			}
			return
		}
		
		self.addressPublisher.send((address: address, publicKey: publicKey))
	}
	
	/// Take in a payload string from an APDU, and call the necessary JS function to convert it to a signature. Also will fire to the necessary publisher
	private func convertAPDUToSignature(payload: String?) {
		guard let payload = payload else {
			returnErrorToPublisher(statusCode: GeneralErrorCodes.UNKNOWN.rawValue)
			return
		}
		
		guard let resultHex = jsContext.evaluateScript("ledger_app_tezos.convertAPDUtoSignature(\"\(payload)\").signature").toString() else {
			Logger.ledger.error("Didn't receive signature")
			returnErrorToPublisher(statusCode: GeneralErrorCodes.UNKNOWN.rawValue)
			return
		}
		
		if resultHex != "" && resultHex != "undefined" {
			self.signaturePublisher.send(resultHex)
			self.signaturePublisher.send(completion: .finished)
			
		} else {
			Logger.ledger.error("Unknown error. APDU: \(resultHex)")
			returnErrorToPublisher(statusCode: GeneralErrorCodes.UNKNOWN.rawValue)
		}
	}
	
	/// Create and error response from a statusCode
	private func kukaiErrorFrom(statusCode: String) -> KukaiError {
		Logger.ledger.error("Error parsing data. statusCode: \(statusCode)")
		
		var code = GeneralErrorCodes.UNKNOWN.rawValue
		var type: Error = GeneralErrorCodes.UNKNOWN
		
		if let tezosCode = TezosAppErrorCodes(rawValue: statusCode) {
			code = tezosCode.rawValue
			type = tezosCode
			
		} else if let generalCode = GeneralErrorCodes(rawValue: statusCode) {
			code = generalCode.rawValue
			type = generalCode
		}
		
		Logger.ledger.error("Ledger error code: \(code)")
		return KukaiError.internalApplicationError(error: type)
	}
	
	/// A helper to take an error code , returned from an APDU, and fire it back into whichever publisher is currently being listened too
	private func returnErrorToPublisher(statusCode: String) {
		let kukaiError = kukaiErrorFrom(statusCode: statusCode)
		returnKukaiErrorToPublisher(kukaiError: kukaiError)
	}
	
	/// Send the error into the appropriate publisher
	private func returnKukaiErrorToPublisher(kukaiError: KukaiError) {
		switch requestType {
			case .address:
				self.addressPublisher.send(completion: .failure(kukaiError))
			
			case .signing:
				self.signaturePublisher.send(completion: .failure(kukaiError))
			
			case .none:
				Logger.ledger.error("Requesting error for unknown requestType: \(kukaiError)")
		}
	}
}
