//
//  DiskService.swift
//  KukaiCoreSwift
//
//  Created by Simon Mcloughlin on 22/01/2021.
//  Copyright © 2021 Kukai AB. All rights reserved.
//

import Foundation
import os.log


public enum DiskServiceError: Error {
	case documentDirectoryNotFound
	case createFolderError
	case noDateCreatedOnFile
	case unknown
}

/// A service class to write and read data from the devices documents directory
public class DiskService {
	
	// MARK: - Write
	
	/**
	Write an instance of `Data` to a given fileName
	- Returns: Bool, indicating if the operation was successful
	*/
	public static func write(data: Data, toFileName: String, isExcludedFromBackup: Bool = true) -> Bool {
		guard let dir = documentsDirectory(isExcludedFromBackup: isExcludedFromBackup) else {
			Logger.kukaiCoreSwift.error("Failed to find documents directory")
			return false
		}
		
		let fileURL = dir.appendingPathComponent(toFileName)
		
		// delete any old file first
		if !delete(fileName: toFileName) {
			Logger.kukaiCoreSwift.error("Failed to clear old file")
			return false
		}
		
		// Write the current contents to disk
		do {
			try data.write(to: fileURL)
			
			Logger.kukaiCoreSwift.info("Serialised encodable to: \(toFileName)")
			return true
			
		} catch (let error) {
			Logger.kukaiCoreSwift.error("Failed to write to \(toFileName): \((error))")
			return false
		}
	}
	
	/**
	Write an instance of an object conforming to `Encodable` to a fileName
	- Returns: Bool, indicating if the operation was successful
	*/
	public static func write<T: Encodable>(encodable: T, toFileName: String, isExcludedFromBackup: Bool = true) -> Bool {
		do {
			let encodedData = try JSONEncoder().encode(encodable)
			return write(data: encodedData, toFileName: toFileName, isExcludedFromBackup: isExcludedFromBackup)

		} catch (let error) {
			Logger.kukaiCoreSwift.error("Failed to write to \(toFileName): \(error)")
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
			Logger.kukaiCoreSwift.error("Failed to find documents directory")
			return nil
		}
		
		let fileURL = dir.appendingPathComponent(fromFileName)
		
		
		do {
			return try Data(contentsOf: fileURL)
			
		} catch (let error) {
			Logger.kukaiCoreSwift.error("Failed to read from \(fromFileName): \(error)")
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
			Logger.kukaiCoreSwift.error("Failed to parse decodable from \(fromFileName): \(error)")
			return nil
		}
	}
	
	
	
	// MARK: - Fetch
	
	/**
	 Fetch a remote file and optionally store it in a supplied folder in the documents directory
	 */
	public static func fetchRemoteFile(url: URL, storeInFolder: String?, completion: @escaping ((Result<URL, Error>) -> Void)) {
		guard let docDirectory = documentsDirectory() else {
			completion(Result.failure(DiskServiceError.documentDirectoryNotFound))
			return
		}
		
		// Create filename and path, checking if the folder exists and creating if not
		let fileName = url.lastPathComponent
		var fullFilePath = docDirectory
		
		if let subDirectory = storeInFolder {
			fullFilePath = fullFilePath.appendingPathComponent(subDirectory)
			
			if !FileManager.default.fileExists(atPath: fullFilePath.path) {
				do {
					try FileManager.default.createDirectory(at: fullFilePath, withIntermediateDirectories: true)
				} catch {
					completion(Result.failure(DiskServiceError.createFolderError))
					return
				}
			}
		}
		
		fullFilePath = fullFilePath.appendingPathComponent(fileName)
		
		
		// Check if filename exists already, if so early exit
		if FileManager.default.fileExists(atPath: fullFilePath.path) {
			completion(Result.success(fullFilePath))
			return
		}
		
		
		// Else download the file, move it to the location, return the path if successful
		let sessionConfig = URLSessionConfiguration.default
		let session = URLSession(configuration: sessionConfig)
		let request = URLRequest(url: url)
		
		let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
			guard let tempLocalUrl = tempLocalUrl, error == nil else {
				completion(Result.failure(error ?? DiskServiceError.unknown))
				return
			}
			
			do {
				try FileManager.default.copyItem(at: tempLocalUrl, to: fullFilePath)
				completion(Result.success(fullFilePath))
				return
				
			} catch (let writeError) {
				completion(Result.failure(writeError))
				return
			}
		}
		task.resume()
	}
	
	/**
	 Check the contents of a folder and delete the files if older than a given date
	 */
	public static func clearFiles(inFolder: String, olderThanDays: Int, completion: @escaping ((Error?) -> Void)) {
		print("clearFiles - entered")
		let calendar = Calendar.current
		
		guard let docDirectory = documentsDirectory(), let daysAgo = calendar.date(byAdding: .day, value: olderThanDays * -1, to: Date()) else {
			print("clearFiles - can't find doc directory")
			completion(DiskServiceError.documentDirectoryNotFound)
			return
		}
		
		let fullFolderPath = docDirectory.appendingPathComponent(inFolder)
		
		print("clearFiles - starting task")
		DispatchQueue.global(qos: .background).async {
			do {
				print("clearFiles - starting do")
				let directoryContent = try FileManager.default.contentsOfDirectory(at: fullFolderPath, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles)
				for url in directoryContent {
					let resources = try url.resourceValues(forKeys: [.creationDateKey])
					
					guard let creationDate = resources.creationDate else {
						print("clearFiles - file missing creation date")
						DispatchQueue.main.async { completion(DiskServiceError.noDateCreatedOnFile) }
						return
					}
					
					if creationDate < daysAgo {
						print("clearFiles - clearing files")
						try FileManager.default.removeItem(at: url)
					} else {
						print("clearFiles - no files to clear")
					}
				}
				
				print("clearFiles - finished do")
			}
			catch (let error) {
				print("clearFiles - entered catch")
				DispatchQueue.main.async { completion(error) }
			}
			
			print("clearFiles - returning as normal")
			DispatchQueue.main.async { completion(nil) }
		}
	}
	
	/**
	 Return the size, in bytes, of a given folder in the documents directory
	 */
	public static func sizeOfFolder(_ folder: String) -> Int? {
		guard let docDirectory = documentsDirectory() else {
			return nil
		}
		
		let fullFolderPath = docDirectory.appendingPathComponent(folder)
		
		guard let enumerator = FileManager.default.enumerator(at: fullFolderPath, includingPropertiesForKeys: [.fileSizeKey]) else {
			return nil
		}
			
		var size = 0
		for case let fileURL as URL in enumerator {
			guard let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
				continue
			}
			size += fileSize
		}
		
		return size
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
			Logger.kukaiCoreSwift.error("Failed to delete file \(fileName): \(error)")
			return false
		}
	}
	
	public static func delete(fileNames: [String]) -> Bool {
		for fileName in fileNames {
			if !DiskService.delete(fileName: fileName) {
				return false
			}
		}
		
		return true
	}
	
	
	
	// MARK: - Utility
	
	/**
	Get the URL to the devices documents directory, if possible
	*/
	public static func documentsDirectory(isExcludedFromBackup: Bool = true) -> URL? {
		do {
			// Need to create the documents directory on github actions
			var url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
			var resourceValues = URLResourceValues()
			resourceValues.isExcludedFromBackup = isExcludedFromBackup
			try url.setResourceValues(resourceValues)
			
			return url
			
		} catch (let error) {
			Logger.kukaiCoreSwift.error("Error fetching documents directory: \(error)")
			return nil
		}
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
	
	
	/**
	 Find all files in documents directory begining with prefix
	 */
	
	public static func allFileNamesWith(prefix: String) -> [String] {
		var tempStrings: [String] = []
		
		if let dir = documentsDirectory(), let contents = try? FileManager.default.contentsOfDirectory(atPath: dir.path) {
			for filename in contents {
				if filename.prefix(prefix.count) == prefix {
					tempStrings.append(filename)
				}
			}
		}
		
		return tempStrings
	}
}
