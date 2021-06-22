//
//  DiskService.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 22/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import os.log


/// A service class to write and read data from the devices documents directory
public class DiskService {
	
	
	// MARK: - Write
	
	/**
	Write an instance of `Data` to a given fileName
	- Returns: Bool, indicating if the operation was successful
	*/
	public static func write(data: Data, toFileName: String) -> Bool {
		guard let dir = documentsDirectory() else {
			os_log(.error, log: .kukaiCoreSwift, "Failed to find documents directory")
			return false
		}
		
		let fileURL = dir.appendingPathComponent(toFileName)
		
		// delete any old file first
		if !delete(fileName: toFileName) {
			os_log(.error, log: .kukaiCoreSwift, "Failed to clear old file")
			return false
		}
		
		
		// Write the current contents to disk
		do {
			try data.write(to: fileURL)
			
			os_log(.debug, log: .kukaiCoreSwift, "Serialised encodable to: %@", toFileName)
			return true
			
		} catch (let error) {
			os_log(.error, log: .kukaiCoreSwift, "Failed to write to %@: %@", toFileName, error.localizedDescription)
			return false
		}
	}
	
	/**
	Write an instance of an object conforming to `Encodable` to a fileName
	- Returns: Bool, indicating if the operation was successful
	*/
	public static func write<T: Encodable>(encodable: T, toFileName: String) -> Bool {
		do {
			let encodedData = try JSONEncoder().encode(encodable)
			return write(data: encodedData, toFileName: toFileName)

		} catch (let error) {
			os_log(.error, log: .kukaiCoreSwift, "Failed to write to %@: %@", toFileName, error.localizedDescription)
			return false
		}
	}
	
	
	
	// MARK: - Read
	
	/**
	Read a fileName and return the contents as `Data`
	- Returns: `Data`, if able to read file
	*/
	public static func readData(fromFileName: String) -> Data? {
		guard let dir = documentsDirectory() else {
			os_log(.error, log: .kukaiCoreSwift, "Failed to find documents directory")
			return nil
		}
		
		let fileURL = dir.appendingPathComponent(fromFileName)
		
		
		do {
			return try Data(contentsOf: fileURL)
			
		} catch (let error) {
			os_log(.error, log: .kukaiCoreSwift, "Failed to read from %@: %@", fromFileName, error.localizedDescription)
			return nil
		}
	}
	
	/**
	Read a fileName, and parse the contents as an instance of a `Decodable` object
	- Returns: An instance of the `Decodable` type, if able to read file and parse it
	*/
	public static func read<T: Decodable>(type: T.Type, fromFileName: String) -> T? {
		guard let data = readData(fromFileName: fromFileName) else {
			return nil
		}
		
			
		do {
			return try JSONDecoder().decode(T.self, from: data)
			
		} catch (let error) {
			os_log(.error, log: .kukaiCoreSwift, "Failed to parse decodable from %@: %@", fromFileName, error.localizedDescription)
			return nil
		}
	}
	
	
	
	// MARK: - Delete
	
	/**
	Delete a fileName
	- Returns: Bool, indicating if the operation was successful
	*/
	public static func delete(fileName: String) -> Bool {
		guard let fileURL = exists(fileName: fileName) else {
			return true // if no file exists at the URL, return true so code doesn't think it was unable to find it
		}
		
		do {
			try FileManager.default.removeItem(at: fileURL)
			return true
			
		} catch (let error) {
			os_log(.error, log: .kukaiCoreSwift, "Failed to delete file %@: %@", fileName, error.localizedDescription)
			return false
		}
	}
	
	
	
	// MARK: - Utility
	
	/**
	Get the URL to the devices documents directory, if possible
	*/
	public static func documentsDirectory() -> URL? {
		if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
			return dir
		}
		
		return nil
	}
	
	/**
	Check if a fileName exists in the documents directory or not
	*/
	public static func exists(fileName: String) -> URL? {
		if let dir = documentsDirectory() {
			let fileURL = dir.appendingPathComponent(fileName)
			
			if FileManager.default.fileExists(atPath: fileURL.path) {
				return fileURL
			}
		}
		
		return nil
	}
}
