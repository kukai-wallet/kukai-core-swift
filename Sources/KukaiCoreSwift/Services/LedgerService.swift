//
//  LedgerService.swift
//  
//
//  Created by Simon Mcloughlin on 17/09/2021.
//

import Foundation
import JavaScriptCore
import CoreBluetooth
import os.log



/**
The main functions in LedgerService return results via completion blocks. But some pieces of data are supplemental, or need to be delivered in a different manner.
This protocol allows a class to receive data on connection status, new devices discovered etc.
*/
public protocol LedgerServiceDelegate: AnyObject {
	
	/**
	Called when a new device is discovered. Parameter will contain all unqiue devices found so far
	*/
	func deviceListUpdated(devices: [String: String])
	
	/**
	Called when a ledger is connected too, or when a connection attempt fails
	*/
	func deviceConnectedStatus(success: Bool)
	
	/**
	Some actions require the user to interact with the Ledger. When the appropriate status code is returned, this function will be called,
	allowing apps to present dialogs informing the user to complete the action.
	*/
	func partialMessageSuccessReceived()
}



/**
A service class to wrap up all the complicated interactions with CoreBluetooth and the modified version of ledgerjs.

Ledger only provide a ReactNative module for third parties to integrate with. The architecture of the module also makes it very difficult to
integrate with native mobile (if it can be packaged up) as it relies heavily on long observable chains passing through many classes and functions.
To overcome this, I copied the base logic from multiple classes into a single file and split the functions up into more of a utility style class, where
each function returns a result and must be passed into another function. This allowed the creation of a swift class to sit in the middle of these
functions and decide what to do with the responses.

The modified typescript can be found in this repo: https://github.com/simonmcl/ledgerjs , under this branch + file:
https://github.com/simonmcl/ledgerjs/blob/native-mobile/packages/hw-app-tezos/src/NativeMobileTezos.ts .
The containing package also includes a webpack file, which will package up the typescript and its dependencies into mobile friendly JS file, which
needs to be included in the swift project. Usage of the JS can be seen below.

**NOTE:** this modified typescript is Tezos only as I was unable to find a way to simply subclass their `Transport` class, to produce a re-usable
NativeMobile transport. The changes required modifiying the app and other class logic which became impossible to refactor back into the project.
*/
public class LedgerService: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate {
	
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
		
		case DEVICE_LOCKED = "00900000"
		case UNKNOWN = "99999999"
		case NO_ADDRESS_CALLBACK = "99999998"
		case NO_SIGN_CALLBACK = "99999997"
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
	
	private let jsContext: JSContext
	private var centralManager: CBCentralManager?
	private var connectedDevice: CBPeripheral?
	private var writeCharacteristic: CBCharacteristic?
	private var notifyCharacteristic: CBCharacteristic?
	
	private var setupCallback: ((Bool) -> Void)? = nil
	private var addressCallback: ((String?, String?, ErrorResponse?) -> Void)? = nil
	private var signCallback: ((String?, ErrorResponse?) -> Void)? = nil
	
	private var deviceList: [String: String] = [:]
	private var requestedUUID: String? = nil
	private var isFetchingAddress = false
	private var isSigningOperation = false
	
	
	/// Public shared instace to avoid having multiple copies of the underlying `JSContext` created
	public static let shared = LedgerService()
	
	/// Delegate to receive status callbacks
	public weak var delegate: LedgerServiceDelegate?
	
	
	
	
	
	// MARK: - Init
	
	private override init() {
		jsContext = JSContext()
		jsContext.exceptionHandler = { context, exception in
			os_log("JSContext exception: %@", log: .kukaiCoreSwift, type: .error, exception?.toString() ?? "")
		}
		
		
		// Grab the custom ledger tezos app js and load it in
		if let jsSourcePath = Bundle.module.url(forResource: "ledger_app_tezos", withExtension: "js", subdirectory: "External") {
			do {
				let jsSourceContents = try String(contentsOf: jsSourcePath)
				self.jsContext.evaluateScript(jsSourceContents)
				
			} catch (let error) {
				os_log("Error parsing Ledger javascript file: %@", log: .kukaiCoreSwift, type: .error, "\(error)")
			}
		}
		
		super.init()
		
		
		// Register a native function, to be passed into the js functions, that will write chunks of data to the device
		let nativeWriteHandler: @convention(block) (String) -> Void = { [weak self] (result) in
			os_log("Inside nativeWriteHandler", log: .ledger, type: .debug)
			
			guard let sendAPDU = self?.jsContext.evaluateScript("ledger_app_tezos.sendAPDU(\"\(result)\", 156)").toString() else {
				self?.delegate?.deviceConnectedStatus(success: false)
				return
			}
			
			let components = sendAPDU.components(separatedBy: " ")
			for component in components {
				if component != "" {
					
					let data = Data(hexString: component) ?? Data()
					
					if let char = self?.writeCharacteristic {
						os_log("writing payload", log: .ledger, type: .debug)
						self?.connectedDevice?.writeValue(data, for: char, type: .withResponse)
						
					} else {
						os_log("unable to get writeCharacteristic", log: .ledger, type: .error)
						self?.returnLedgerErrorToCallback(resultCode: GeneralErrorCodes.NO_WRITE_CHARACTERISTIC.rawValue)
					}
				}
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
	public func setupBluetoothConnection(completion: @escaping ((Bool) -> Void)) {
		if centralManager != nil {
			completion(centralManager?.state == .poweredOn)
			return
		}
		
		self.setupCallback = completion
		centralManager = CBCentralManager(delegate: self, queue: nil)
	}
	
	/**
	Start listening for ledger devices, reporting back to the delegate function if found
	*/
	public func listenForDevices() {
		self.centralManager?.scanForPeripherals(withServices: [LedgerNanoXConstant.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
	}
	
	/**
	Stop listen for and reporting new ledger devices found
	*/
	public func stopListening() {
		self.centralManager?.stopScan()
	}
	
	/**
	Connect to a ledger device by a given UUID
	*/
	public func connectTo(uuid: String) {
		self.requestedUUID = uuid
		self.centralManager?.scanForPeripherals(withServices: [LedgerNanoXConstant.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
	}
	
	/**
	Disconnect from the current Ledger device
	*/
	public func disconnectFromDevice() {
		if let device = self.connectedDevice {
			self.centralManager?.cancelPeripheralConnection(device)
		}
	}
	
	/**
	Get a TZ address and public key from the current connected Ledger device
	- parameter forDerivationPath: Optional. The derivation path to use to extract the address from the underlying HD wallet
	- parameter curve: Optional. The `EllipticalCurve` to use to extract the address
	- parameter verify: Whether or not to ask the ledger device to prompt the user to show them what the TZ address should be, to ensure the mobile matches
	- parameter completion: A completion block called with either address and publicKey, or an error indicating an issue
	*/
	public func getAddress(forDerivationPath derivationPath: String = HDWallet.defaultDerivationPath, curve: EllipticalCurve = .ed25519, verify: Bool, completion: @escaping ((String?, String?, Error?) -> Void)) {
		self.addressCallback = completion
		self.isFetchingAddress = true
		self.isSigningOperation = false
		
		var selectedCurve = 0
		switch curve {
			case .ed25519:
				selectedCurve = 0
				
			case .secp256k1:
				selectedCurve = 1
		}
		
		let _ = jsContext.evaluateScript("tezosApp.getAddress(\"\(derivationPath)\", {verify: \(verify), curve: \(selectedCurve)})")
	}
	
	/**
	Sign an operation payload with the underlying secret key, returning the signature
	- parameter hex: An operation converted to JSON, forged and watermarked, converted to a hex string. (Note: there are some issues with the ledger app signing batch transactions. May simply return no result at all)
	- parameter forDerivationPath: Optional. The derivation path to use to extract the address from the underlying HD wallet
	- parameter completion: A completion block called with either a hex signature, or an error indicating an issue
	*/
	public func sign(hex: String, forDerivationPath derivationPath: String = HDWallet.defaultDerivationPath, completion: @escaping ((String?, ErrorResponse?) -> Void)) {
		self.signCallback = completion
		self.isSigningOperation = true
		self.isFetchingAddress = false
		
		let _ = jsContext.evaluateScript("tezosApp.signOperation(\"\(derivationPath)\", \"\(hex)\")")
	}
	
	
	
	
	
	// MARK: - Bluetooth
	
	public func centralManagerDidUpdateState(_ central: CBCentralManager) {
		os_log("centralManagerDidUpdateState", log: .ledger, type: .debug)
		
		guard let callback = self.setupCallback else {
			return
		}
		
		callback(central.state == .poweredOn)
		self.setupCallback = nil
	}
	
	public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		
		// If we have been requested to connect to a speicific UUID, only listen for that one and connect immediately if found
		if let requested = self.requestedUUID, peripheral.identifier.uuidString == requested {
			os_log("Found requested ledger UUID, connecting ...", log: .ledger, type: .debug)
			
			self.connectedDevice = peripheral
			self.centralManager?.connect(peripheral, options: ["requestMTU": 156])
			self.centralManager?.stopScan()
		
		// Else if we haven't been requested to find a specific one, store each unique device and fire a delegate callback, until scan stopped manually
		} else if self.requestedUUID == nil, deviceList[peripheral.identifier.uuidString] == nil {
			os_log("Found a new ledger device. Name: %@, UUID: %@", log: .ledger, type: .debug, peripheral.name ?? "-", peripheral.identifier.uuidString)
			
			deviceList[peripheral.identifier.uuidString] = peripheral.name ?? ""
			self.delegate?.deviceListUpdated(devices: deviceList)
		}
	}
	
	public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		os_log("Connected to %@, %@", log: .ledger, type: .debug, peripheral.name ?? "", peripheral.identifier.uuidString)
		
		// record the connected device and set LedgerService as the delegate. Don't report successfully connected to ledgerService.delegate until
		// we have received the callbacks for services and characteristics. Otherwise we can't use the device
		self.connectedDevice = peripheral
		self.connectedDevice?.delegate = self
		self.connectedDevice?.discoverServices([LedgerNanoXConstant.serviceUUID])
	}
	
	public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
		os_log("Failed to connect to %@, %@", log: .ledger, type: .debug, peripheral.name ?? "", peripheral.identifier.uuidString)
		self.connectedDevice = nil
		self.delegate?.deviceConnectedStatus(success: false)
	}
	
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let services = peripheral.services else {
			os_log("Unable to locate services for: %@, %@. Error: %@", log: .ledger, type: .debug, peripheral.name ?? "", peripheral.identifier.uuidString, "\(String(describing: error))")
			self.connectedDevice = nil
			self.delegate?.deviceConnectedStatus(success: false)
			return
		}
		
		for service in services {
			if service.uuid == LedgerNanoXConstant.serviceUUID {
				peripheral.discoverCharacteristics(nil, for: service)
				return
			}
		}
	}
	
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		guard let characteristics = service.characteristics else {
			os_log("Unable to locate characteristics for: %@, %@. Error: %@", log: .ledger, type: .debug, peripheral.name ?? "", peripheral.identifier.uuidString, "\(String(describing: error))")
			self.connectedDevice = nil
			self.delegate?.deviceConnectedStatus(success: false)
			return
		}
		
		for characteristic in characteristics {
			if characteristic.uuid == LedgerNanoXConstant.writeUUID {
				os_log("Located write characteristic", log: .ledger, type: .debug)
				writeCharacteristic = characteristic
				
			} else if characteristic.uuid == LedgerNanoXConstant.notifyUUID {
				os_log("Located notify characteristic", log: .ledger, type: .debug)
				notifyCharacteristic = characteristic
			}
			
			if let _ = writeCharacteristic, let notify = notifyCharacteristic {
				os_log("Registering for notifications on notify characteristic", log: .ledger, type: .debug)
				peripheral.setNotifyValue(true, for: notify)
				
				self.delegate?.deviceConnectedStatus(success: true)
			}
		}
	}
	
	public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		if let err = error {
			os_log("Error during write: %@", log: .ledger, type: .debug, "\(String(describing: error))")
			if self.isFetchingAddress, let callback = self.addressCallback {
				callback(nil, nil, ErrorResponse.lederError(code: GeneralErrorCodes.UNKNOWN.rawValue, type: err))
				
			} else if let callback = self.signCallback {
				callback(nil, ErrorResponse.lederError(code: GeneralErrorCodes.UNKNOWN.rawValue, type: err))
			}
		} else {
			os_log("Successfully wrote to write characteristic", log: .ledger, type: .debug)
		}
	}
	
	public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		guard characteristic.uuid == LedgerNanoXConstant.notifyUUID else {
			return
		}
		
		os_log("Receiveing value from notify characteristic", log: .ledger, type: .debug)
		
		
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
			isFetchingAddress = false
			isSigningOperation = false
			returnLedgerErrorToCallback(resultCode: GeneralErrorCodes.UNKNOWN.rawValue)
			return
		}
		
		
		// Some operations require mutiple data packets, and the user to approve/verify something on the actual device
		// When this happens, the ldeger will return a success/ok message to denote the data was received successfully
		// but its not ready to return the response at the minute.
		// We can use this oppertunity to let users know, in the app, that they need to check their ledger device
		if resultString == LedgerService.successCode {
			os_log("Received Success/Ok APDU", log: .ledger, type: .debug)
			self.delegate?.partialMessageSuccessReceived()
			return
			
		} else if resultString.count == 4 {
			returnLedgerErrorToCallback(resultCode: resultString)
			return
		}
		
		
		os_log("Received non partial success response: %@", log: .ledger, type: .debug, resultString)
		
		
		// Else, try to parse the response into an address/public key or a signature
		if isFetchingAddress {
			isFetchingAddress = false
			
			guard let dict = jsContext.evaluateScript("ledger_app_tezos.convertAPDUtoAddress(\"\(resultString)\")").toObject() as? [String: String] else {
				os_log("Didn't receive address object", log: .ledger, type: .error)
				returnLedgerErrorToCallback(resultCode: GeneralErrorCodes.UNKNOWN.rawValue)
				return
			}
			
			guard let address = dict["address"], let publicKey = dict["publicKey"] else {
				if let err = dict["error"] {
					os_log("Internal script error: %@", log: .ledger, type: .error, err)
					returnLedgerErrorToCallback(resultCode: GeneralErrorCodes.UNKNOWN.rawValue)
					
				} else {
					os_log("Unknown error", log: .ledger, type: .error)
					returnLedgerErrorToCallback(resultCode: GeneralErrorCodes.UNKNOWN.rawValue)
				}
				return
			}
			
			guard let callback = addressCallback else {
				os_log("No address callback", log: .ledger, type: .error)
				returnLedgerErrorToCallback(resultCode: GeneralErrorCodes.NO_ADDRESS_CALLBACK.rawValue)
				return
			}
			
			callback(address, publicKey, nil)
			
		} else if isSigningOperation {
			self.isSigningOperation = false
			
			guard let resultHex = jsContext.evaluateScript("ledger_app_tezos.convertAPDUtoSignature(\"\(resultString)\").signature").toString() else {
				os_log("Didn't receive signature", log: .ledger, type: .error)
				returnLedgerErrorToCallback(resultCode: GeneralErrorCodes.UNKNOWN.rawValue)
				return
			}
			
			if resultHex != "" && resultHex != "undefined" {
				if let callback = signCallback {
					callback(resultHex, nil)
					
				} else {
					os_log("No sign callback", log: .ledger, type: .error)
					returnLedgerErrorToCallback(resultCode: GeneralErrorCodes.NO_SIGN_CALLBACK.rawValue)
				}
				
			} else {
				os_log("Unknown error. APDU: %@", log: .ledger, type: .error, resultHex)
				returnLedgerErrorToCallback(resultCode: GeneralErrorCodes.UNKNOWN.rawValue)
			}
		}
	}
	
	
	
	
	
	// MARK: - Private helpers
	
	/**
	A helper to take an error code , returned from an APDU, and fire it back into whichever completion callback is being tracked
	*/
	private func returnLedgerErrorToCallback(resultCode: String) {
		os_log("Error parsing data. Result code: %@", log: .ledger, type: .error, resultCode)
		
		var code = GeneralErrorCodes.UNKNOWN.rawValue
		var type: Error = GeneralErrorCodes.UNKNOWN
		
		if let tezosCode = TezosAppErrorCodes(rawValue: resultCode) {
			code = tezosCode.rawValue
			type = tezosCode
			
		} else if let generalCode = GeneralErrorCodes(rawValue: resultCode) {
			code = generalCode.rawValue
			type = generalCode
		}
		
		
		if isFetchingAddress, let callback = addressCallback {
			callback(nil, nil, ErrorResponse.lederError(code: code, type: type))
			
		} else if let callback = signCallback {
			callback(nil, ErrorResponse.lederError(code: code, type: type))
		}
	}
}
