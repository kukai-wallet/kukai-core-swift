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


// Default message before data written:  0e80000000

// Error message:
//		0e67000000
//		0e01000000

// Receive APDU error codes:
// 		Needs to be unlocked	009000


public protocol LedgerServiceDelegate: AnyObject {
	func bluetoothIsDisabled()
	func deviceListUpdated(devices: [String: (name: String, peripheral: CBPeripheral)])
	func connectedStatus(success: Bool)
	func connectedWalletAddress(address: String)
	func requestReturnedError(error: String)
}

public class LedgerService: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate {
	
	struct LedgerNanoXConstant {
		static let serviceUUID = CBUUID(string: "13d63400-2c97-0004-0000-4c6564676572")
		static let notifyUUID = CBUUID(string: "13d63400-2c97-0004-0001-4c6564676572")
		static let writeUUID = CBUUID(string: "13d63400-2c97-0004-0002-4c6564676572")
	}
	
	private let jsContext: JSContext
	private var centralManager: CBCentralManager?
	private var connectedDevice: CBPeripheral?
	private var writeCharacteristic: CBCharacteristic?
	private var notifyCharacteristic: CBCharacteristic?
	
	private var deviceList: [String: (name: String, peripheral: CBPeripheral)] = [:]
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
		
		// Print the avaialble high level keys to console as a test
		let transportKeys = jsContext.evaluateScript("""
			Object.keys(ledger_app_tezos)
		""")
		
		print("\n\n\n")
		print("ledger_app_tezos - Keys: \(transportKeys?.toString() ?? "")")
		print("\n\n\n")
		
		
		// Register a native function, to be passed into the js functions, that will write chunks of data to the device
		let nativeWriteHandler: @convention(block) (String) -> Void = { [weak self] (result) in
			os_log("Inside nativeWriteHandler", log: .ledger, type: .debug)
			
			guard let sendAPDU = self?.jsContext.evaluateScript("ledger_app_tezos.sendAPDU(\"\(result)\", 156)").toString() else {
				self?.delegate?.requestReturnedError(error: "Unbale to format request")
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
	
	public func listenForDevices() {
		centralManager = CBCentralManager(delegate: self, queue: nil)
	}
	
	public func stopListening() {
		self.centralManager?.stopScan()
	}
	
	public func connectToDevice(peripheral: CBPeripheral) {
		self.centralManager?.connect(peripheral, options: ["requestMTU": 156])
	}
	
	public func disconnectFRomDevice() {
		if let device = self.connectedDevice {
			self.centralManager?.cancelPeripheralConnection(device)
		}
	}
	
	public func getAddress(forDerivationPath derivationPath: String = "44'/1729'/0'/0'") {
		self.isFetchingAddress = true
		let _ = jsContext.evaluateScript("tezosApp.getAddress(\"\(derivationPath)\")")
	}
	
	
	
	
	
	// MARK: - Bluetooth
	
	public func centralManagerDidUpdateState(_ central: CBCentralManager) {
		os_log("centralManagerDidUpdateState", log: .ledger, type: .debug)
		
		if central.state != .poweredOn {
			os_log("Bluetooth is turned off", log: .ledger, type: .debug)
			self.delegate?.bluetoothIsDisabled()
			
		} else {
			os_log("Bluetooth is turned on. Scanning ...", log: .ledger, type: .debug)
			centralManager?.scanForPeripherals(withServices: [LedgerNanoXConstant.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
		}
	}
	
	public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		if deviceList[peripheral.identifier.uuidString] == nil {
			os_log("Found a new ledger device. Name: %@, UUID: %@", log: .ledger, type: .debug, peripheral.name ?? "-", peripheral.identifier.uuidString)
			
			deviceList[peripheral.identifier.uuidString] = (name: peripheral.name ?? "", peripheral: peripheral)
			self.delegate?.deviceListUpdated(devices: deviceList)
		}
	}
	
	public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		os_log("Connected to %@, %@", log: .ledger, type: .debug, peripheral.name ?? "", peripheral.identifier.uuidString)
		
		self.connectedDevice = peripheral
		self.connectedDevice?.delegate = self
		self.connectedDevice?.discoverServices([LedgerNanoXConstant.serviceUUID])
	}
	
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		guard let services = peripheral.services else {
			os_log("Unable to locate services for: %@, %@. Error: %@", log: .ledger, type: .debug, peripheral.name ?? "", peripheral.identifier.uuidString, "\(String(describing: error))")
			self.delegate?.connectedStatus(success: false)
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
			self.delegate?.connectedStatus(success: false)
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
				
				self.delegate?.connectedStatus(success: true)
			}
		}
	}
	
	public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		if error == nil {
			os_log("Successfully wrote to write characteristic", log: .ledger, type: .debug)
		} else {
			os_log("Error during write: %@", log: .ledger, type: .debug, "\(String(describing: error))")
		}
	}
	
	public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		guard characteristic.uuid == LedgerNanoXConstant.notifyUUID else {
			return
		}
		
		os_log("Receiveing value from notify characteristic", log: .ledger, type: .debug)
		
		let hexString = characteristic.value?.toHexString() ?? "-"
		let receivedResult = jsContext.evaluateScript("""
			var result = ledger_app_tezos.receiveAPDU(\"\(hexString)\")
			
			if (result.error === "null") {
				result.data
			} else {
				"Error: " + result.error
			}
		""")
		
		guard let resultString = receivedResult?.toString() else {
			self.delegate?.requestReturnedError(error: "Unknown")
			return
		}
		
		guard String(resultString.prefix(5)) != "Error" else {
			self.delegate?.requestReturnedError(error: resultString)
			return
		}
		
		
		if isFetchingAddress {
			let resultHex = jsContext.evaluateScript("ledger_app_tezos.convertAPDUtoAddress(\"\(resultString)\")")
			let obj = resultHex?.toObject() as? [String: String] ?? [:]
			
			self.delegate?.connectedWalletAddress(address: obj["address"] ?? "-")
			
		} else if isSigningOperation {
			
		}
	}
}
