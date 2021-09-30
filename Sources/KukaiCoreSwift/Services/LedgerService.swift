//
//  File.swift
//  
//
//  Created by Simon Mcloughlin on 17/09/2021.
//

import Foundation
import JavaScriptCore
import CoreBluetooth
import os.log



public protocol LedgerServiceDelegate: AnyObject {
	func deviceListUpdated(devices: [String: String])
	func deviceConnectedStatus(success: Bool)
	func partialMessageSuccessReceived()
}

public class LedgerService: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate {
	
	struct LedgerNanoXConstant {
		static let serviceUUID = CBUUID(string: "13d63400-2c97-0004-0000-4c6564676572")
		static let notifyUUID = CBUUID(string: "13d63400-2c97-0004-0001-4c6564676572")
		static let writeUUID = CBUUID(string: "13d63400-2c97-0004-0002-4c6564676572")
	}
	
	public static let successCode = "9000"
	public static let generalErrorCodes = [
		"63c0": "PIN_REMAINING_ATTEMPTS",
		"6700": "INCORRECT_LENGTH",
		"6800": "MISSING_CRITICAL_PARAMETER",
		"6981": "COMMAND_INCOMPATIBLE_FILE_STRUCTURE",
		"6982": "SECURITY_STATUS_NOT_SATISFIED",
		"6985": "CONDITIONS_OF_USE_NOT_SATISFIED",
		"6a80": "INCORRECT_DATA",
		"6a84": "NOT_ENOUGH_MEMORY_SPACE",
		"6a88": "REFERENCED_DATA_NOT_FOUND",
		"6a89": "FILE_ALREADY_EXISTS",
		"6b00": "INCORRECT_P1_P2",
		"6d00": "INS_NOT_SUPPORTED",
		"6e00": "CLA_NOT_SUPPORTED",
		"6f00": "TECHNICAL_PROBLEM",
		"9240": "MEMORY_PROBLEM",
		"9400": "NO_EF_SELECTED",
		"9402": "INVALID_OFFSET",
		"9404": "FILE_NOT_FOUND",
		"9408": "INCONSISTENT_FILE",
		"9484": "ALGORITHM_NOT_SUPPORTED",
		"9485": "INVALID_KCV",
		"9802": "CODE_NOT_INITIALIZED",
		"9804": "ACCESS_CONDITION_NOT_FULFILLED",
		"9808": "CONTRADICTION_SECRET_CODE_STATUS",
		"9810": "CONTRADICTION_INVALIDATION",
		"9840": "CODE_BLOCKED",
		"9850": "MAX_VALUE_REACHED",
		"6300": "GP_AUTH_FAILED",
		"6f42": "LICENSING",
		"6faa": "HALTED",
	]
	public static let tezosErrorCodes = [
		"6B00": "EXC_WRONG_PARAM",
		"6C00": "EXC_WRONG_LENGTH",
		"6D00": "EXC_INVALID_INS",
		"917E": "EXC_WRONG_LENGTH_FOR_INS",
		"6985": "EXC_REJECT",
		"9405": "EXC_PARSE_ERROR",
		"6A88": "EXC_REFERENCED_DATA_NOT_FOUND",
		"6A80": "EXC_WRONG_VALUES",
		"6982": "EXC_SECURITY",
		"6983": "EXC_HID_REQUIRED",
		"6E00": "EXC_CLASS",
		"9200": "EXC_MEMORY_ERROR"
	]
	
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
	public weak var delegate: LedgerServiceDelegate?
	
	
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
				//self?.delegate?.requestReturnedError(error: "Unbale to format request")
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
	
	public func setupBluetoothConnection(completion: @escaping ((Bool) -> Void)) {
		if centralManager != nil {
			completion(centralManager?.state == .poweredOn)
			return
		}
		
		self.setupCallback = completion
		centralManager = CBCentralManager(delegate: self, queue: nil)
	}
	
	public func listenForDevices() {
		self.centralManager?.scanForPeripherals(withServices: [LedgerNanoXConstant.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
	}
	
	public func stopListening() {
		self.centralManager?.stopScan()
	}
	
	public func connectTo(uuid: String) {
		self.requestedUUID = uuid
		self.centralManager?.scanForPeripherals(withServices: [LedgerNanoXConstant.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
	}
	
	public func disconnectFromDevice() {
		if let device = self.connectedDevice {
			self.centralManager?.cancelPeripheralConnection(device)
		}
	}
	
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
		if error == nil {
			os_log("Successfully wrote to write characteristic", log: .ledger, type: .debug)
		} else {
			os_log("Error during write: %@", log: .ledger, type: .debug, "\(String(describing: error))")
			
			if self.isFetchingAddress, let callback = self.addressCallback {
				callback(nil, nil, ErrorResponse.lederError(code: "UNKNOWN", type: "\(error)"))
			} else if let callback = self.signCallback {
				callback(nil, ErrorResponse.lederError(code: "UNKNOWN", type: "\(error)"))
			}
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
			returnLedgerErrorToCallback(code: "UNKNOWN", type: "unknown")
			return
		}
		
		
		// Some operations require mutiple data packets, and the user to approve/verify something on the actual device
		// When this happens, the ldeger will return a success/ok message to denote the data was received successfully
		// but its not ready to return the response at the minute.
		// We can use this oppertunity to let users know, in the app, that they need to check their ledger device
		if resultString == LedgerService.successCode {
			os_log("Received Success/Ok APDU", log: .ledger, type: .debug)
			self.delegate?.partialMessageSuccessReceived()
			
		} else if resultString.count == 4 {
			var type = LedgerService.tezosErrorCodes[resultString]
			
			if type == nil {
				type = LedgerService.generalErrorCodes[resultString]
			}
			
			returnLedgerErrorToCallback(code: resultString, type: type ?? "unknown")
			return
		}
		
		
		// Else, try to parse the response into an address/public key or a signature
		if isFetchingAddress {
			let resultHex = jsContext.evaluateScript("ledger_app_tezos.convertAPDUtoAddress(\"\(resultString)\")")
			let obj = resultHex?.toObject() as? [String: String] ?? [:]
			
			isFetchingAddress = false
			if let callback = addressCallback, let address = obj["address"], let publicKey = obj["publicKey"] {
				callback(address, publicKey, nil)
				
			} else {
				returnLedgerErrorToCallback(code: "UNKNOWN", type: "APDU - \(resultString)")
			}
			
		} else if isSigningOperation {
			let resultHex = jsContext.evaluateScript("""
				ledger_app_tezos.convertAPDUtoSignature(\"\(resultString)\").signature
			""")
			
			
			if resultHex?.toString() != "" && resultHex?.toString() != "undefined" {
				self.isSigningOperation = false
				
				if let callback = signCallback, let signature = resultHex?.toString() {
					callback(signature, nil)
					
				} else {
					returnLedgerErrorToCallback(code: "UNKNOWN", type: "APDU - \(resultString)")
				}
			}
		}
	}
	
	private func returnLedgerErrorToCallback(code: String, type: String) {
		os_log("Error parsing data: %@, %@", log: .ledger, type: .error, code, type)
		
		if isFetchingAddress, let callback = addressCallback {
			callback(nil, nil, ErrorResponse.lederError(code: code, type: type))
			
		} else if let callback = signCallback {
			callback(nil, ErrorResponse.lederError(code: code, type: type))
		}
	}
}
