//
//  File.swift
//  
//
//  Created by Simon Mcloughlin on 17/09/2021.
//

import Foundation
import JavaScriptCore
import CoreBluetooth
import WalletCore
import Sodium
import os.log

public class LedgerService: NSObject, CBPeripheralDelegate, CBCentralManagerDelegate {
	
	private var centralManager: CBCentralManager!
	private var connectedDevice: CBPeripheral!
	private var writeCharacteristic: CBCharacteristic?
	private var notifyCharacteristic: CBCharacteristic?
	
	private var deviceList: [String: String] = [:]
	
	struct LedgerNanoXConstant {
		static let serviceUUID = CBUUID(string: "13d63400-2c97-0004-0000-4c6564676572")
		static let notifyUUID = CBUUID(string: "13d63400-2c97-0004-0001-4c6564676572")
		static let writeUUID = CBUUID(string: "13d63400-2c97-0004-0002-4c6564676572")
	}
	
	
	private let jsContext: JSContext
	private var intermediataryJSvalue: JSValue!
	
	
	
	
	/// Public shared instace to avoid having multiple copies of the underlying `JSContext` created
	public static let shared = LedgerService()
	
	
	private override init() {
		jsContext = JSContext()
		jsContext.exceptionHandler = { context, exception in
			os_log("JSContext exception: %@", log: .kukaiCoreSwift, type: .error, exception?.toString() ?? "")
		}
		
		if let jsSourcePath = Bundle.module.url(forResource: "ledger_transport", withExtension: "js", subdirectory: "External") {
			do {
				let jsSourceContents = try String(contentsOf: jsSourcePath)
				self.jsContext.evaluateScript(jsSourceContents)
				
			} catch (let error) {
				os_log("Error parsing Ledger javascript file: %@", log: .kukaiCoreSwift, type: .error, "\(error)")
			}
		}
		
		if let jsSourcePath = Bundle.module.url(forResource: "ledger_app_tezos", withExtension: "js", subdirectory: "External") {
			do {
				let jsSourceContents = try String(contentsOf: jsSourcePath)
				self.jsContext.evaluateScript(jsSourceContents)
				
			} catch (let error) {
				os_log("Error parsing Ledger javascript file: %@", log: .kukaiCoreSwift, type: .error, "\(error)")
			}
		}
		
		if let jsSourcePath = Bundle.module.url(forResource: "ledger_device_apdu", withExtension: "js", subdirectory: "External") {
			do {
				let jsSourceContents = try String(contentsOf: jsSourcePath)
				self.jsContext.evaluateScript(jsSourceContents)
				
			} catch (let error) {
				os_log("Error parsing Ledger javascript file: %@", log: .kukaiCoreSwift, type: .error, "\(error)")
			}
		}
	}
	
	public func test() {
		
		/*
		guard let outer = jsContext.objectForKeyedSubscript("ledger_transport"),
			  let inner = outer.objectForKeyedSubscript("Transport"),
			  let result = inner.call(withArguments: [xtz, xPool, tPool]) else {
			return nil
		}
		*/
		
		/*
		jsContext.evaluateScript("""
			var transport = ledgerjs.Transport.create();
		""")
		*/
		
		
		/*
		let result = jsContext.evaluateScript("""
			Object.keys("ledger_transport")
		""")
		
		print("result: \(result?.toString())")
		*/
		
		
		let transportKeys = jsContext.evaluateScript("""
			Object.keys(ledger_transport)
		""")
		
		let appKeys = jsContext.evaluateScript("""
			Object.keys(ledger_app_tezos)
		""")
		let apduKeys = jsContext.evaluateScript("""
			Object.keys(ledger_device_apdu)
		""")
		
		
		print("\n\n\n")
		print("transportKeys: \(transportKeys?.toString())")
		print("appKeys: \(appKeys?.toString())")
		print("apduKeys: \(apduKeys?.toString())")
		print("\n\n\n")
		
		
		
		
		
		
		let nativeWriteHandler: @convention(block) (String) -> Void = { [weak self] (result) in
			print("inside write block with: \(result)")
			if result == "inside constructor" { return }
				
			
			let components = result.components(separatedBy: " ")
			for component in components {
				if component != "" {
					let data = Data(hexString: component) ?? Data()
					print("sending chunk: \(data) \n\n\n")
					
					if let char = self?.writeCharacteristic {
						self?.connectedDevice.writeValue(data, for: char, type: .withResponse)
					} else {
						print("unable to get writeCharacteristic")
					}
				}
			}
		}
		let nativeWriteHandlerBlock = unsafeBitCast(nativeWriteHandler, to: AnyObject.self)
		jsContext.setObject(nativeWriteHandlerBlock, forKeyedSubscript: "nativeWriteData" as (NSCopying & NSObjectProtocol))
		
		
		
		
		
		let nativeInstrunctionHandler: @convention(block) (String) -> Void = { [weak self] (result) in
			print("Inside instruction hander: \(result)")
			if result == "inside constructor" { return }
			
			let instrunction = "ledger_device_apdu.sendAPDU(nativeWriteData, \"\(result)\", 153)"
			print("instrunction: \(instrunction)")
			
			self?.intermediataryJSvalue = self?.jsContext.evaluateScript("""
				ledger_device_apdu.sendAPDU(nativeWriteData, \"\(result)\", 153)
			""")
		}
		let nativeInstrunctionHandlerBlock = unsafeBitCast(nativeInstrunctionHandler, to: AnyObject.self)
		jsContext.setObject(nativeInstrunctionHandlerBlock, forKeyedSubscript: "nativeInstructionHandler" as (NSCopying & NSObjectProtocol))
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		do {
			
			// Wrap up the internal call to the forger and pass the promises back to the swift handler blocks
			let _ = jsContext.evaluateScript("""
				
				var nativeTransport = new ledger_transport.NativeTransport(nativeInstructionHandler)
				var tezosApp = new ledger_app_tezos.tezos(nativeTransport)
				
				tezosApp.getAddress("44'/1729'/0'/0'")
				
				
				//ledger_device_apdu.sendAPDU(nativeInstructionHandler, "8002000011048000002c800006c18000000080000000", 153)
				""")
			
		} catch (let error) {
			os_log("JavascriptContext forge error: %@", log: .taquitoService, type: .error, "\(error)")
			return
		}
	}
	
	
	
	
	
	
	public func testNative() {
		centralManager = CBCentralManager(delegate: self, queue: nil)
	}
	
	
	
	
	
	// MARK: - Bluetooth
	
	public func centralManagerDidUpdateState(_ central: CBCentralManager) {
		print("Central state update")
		if central.state != .poweredOn {
			print("Central is not powered on")
			
		} else {
			centralManager.scanForPeripherals(withServices: [LedgerNanoXConstant.serviceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
		}
	}
	
	public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		if deviceList[peripheral.identifier.uuidString] == nil {
			deviceList[peripheral.identifier.uuidString] = peripheral.name
			
			print("Found: '\(peripheral.name ?? "")', with id: \(peripheral.identifier.uuidString)")
			self.connectedDevice = peripheral
			
			self.centralManager.stopScan()
			self.centralManager.connect(self.connectedDevice, options: ["requestMTU": 156])
		}
	}
	
	public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		if peripheral == self.connectedDevice {
			print("Connected to Ledger: \(peripheral.name ?? "")")
			
			peripheral.delegate = self
			peripheral.discoverServices([LedgerNanoXConstant.serviceUUID])
		}
	}
	
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
		if let services = peripheral.services {
			
			for service in services {
				print("\nFound a service: \(service.uuid.uuidString)")
				
				
				if service.uuid == LedgerNanoXConstant.serviceUUID {
					print("Found leder service: \(service)")
					
					peripheral.discoverCharacteristics(nil, for: service)
					
					return
				}
			}
		}
	}
	
	public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
		print("\ndidDiscoverCharacteristicsFor: \(service)")
		
		if let err = error {
			print("Error: \(err)")
		}
		
		if let characteristics = service.characteristics {
			for characteristic in characteristics {
				print("characteristic: \(characteristic.uuid.uuidString), properties: \(characteristic.properties), value: \(String(describing: characteristic.value))")
				
				if characteristic.uuid == LedgerNanoXConstant.writeUUID {
					writeCharacteristic = characteristic
					
					print("\n found write characteristic \n")
					
				} else if characteristic.uuid == LedgerNanoXConstant.notifyUUID {
					notifyCharacteristic = characteristic
					
					print("\n found notify characteristic \n")
				}
				
				
				if let write = writeCharacteristic, let notify = notifyCharacteristic {
					print("testing a write")
					
					peripheral.setNotifyValue(true, for: write)
					peripheral.setNotifyValue(true, for: notify)
					
					test()
				}
			}
		}
	}
	
	public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
		print("\n\n\n didWriteValueFor: char: \( characteristic.uuid == LedgerNanoXConstant.writeUUID ? "WriteChar" : "UnknownChar" )")
		print("didWriteValueFor: error: \( error )")
	}
	
	public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
		print("\n\n\n didUpdateNotificationStateFor:")
	}
	
	public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
		print("\n\n\n didUpdateValueFor:")
		
		if characteristic.uuid == LedgerNanoXConstant.notifyUUID {
			print("is notification UUID")
			
			let raw = characteristic.value
			let hexString = characteristic.value?.toHexString() ?? "-"
			let base64String = characteristic.value?.base64EncodedString() ?? "-"
			
			print("Value raw: \( raw )")
			print("Value hex: \( hexString )")
			print("\n\n\n")
			
			
			
			let resultHex = jsContext.evaluateScript("""
					ledger_app_tezos.convertNativeAddress(\"\(hexString)\")
				""")
			
			let obj = resultHex?.toObject() as? [String: String]
			
			
			print("Tezos address - ledger lib: \(obj)")
			
			
			
			
		} else {
			print("is not notification UUID")
		}
	}
}





// Javascript write function passed into SendAPDU function
/*
write = async (buffer: Buffer, txid?: string | null | undefined) => {
	log("ble-frame", "=> " + buffer.toString("hex"));

	try {
	  await this.writeCharacteristic.writeWithResponse(
		buffer.toString("base64"),
		txid
	  );
	} catch (e: any) {
	  throw new DisconnectedDeviceDuringOperation(e.message);
	}
  };
*/
