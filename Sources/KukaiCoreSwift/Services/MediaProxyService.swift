//
//  MediaProxyService.swift
//  
//
//  Created by Simon Mcloughlin on 01/02/2022.
//

import UIKit
import SDWebImage
import OSLog

public enum MediaProxyServiceError: String, Error {
	case noMimeTypeFoundInsideFormats
	case unableToParseContentType
}

public enum CacheType {
	case temporary
	case permanent
}

/// A service class for interacting with the TC infrastructure to proxy NFT images, videos and audio files
public class MediaProxyService: NSObject {
	
	/// Enum denoting the avaialble sizes for media, in a human friendly, scale agnostic manner
	public enum Format: String, Codable {
		case icon
		case small
		case medium
		case large
		
		public func rawFormat() -> RawFormat {
			switch self {
				case .icon:
					return .mobile64
					
				case .small:
					return (UIScreen.main.scale == 2 ? .mobile128 : .mobile180)
					
				case .medium:
					return (UIScreen.main.scale == 2 ? .mobile400 : .mobile600)
					
				case .large:
					return (UIScreen.main.scale == 2 ? .mobile600 : .mobile900)
			}
		}
	}
	
	/// Enum denoting the avaialble sizes for media in the specific values available on the server
	public enum RawFormat: String, Codable {
		case mobile64
		case mobile128
		case mobile180
		case mobile400
		case mobile600
		case mobile900
	}
	
	/// Supported source types for proxied media
	public enum Source: String, Codable {
		case ipfs
		case web
	}
	
	/// Supported media types
	public enum MediaType: String, Codable {
		case image
		case audio
		case video
	}
	
	/// Helper to parse a collection of media types to understand its contents
	public enum AggregatedMediaType: String, Codable {
		case imageOnly
		case audioOnly
		case videoOnly
		case imageAndAudio
	}
	
	private var getMediaTypeCompletion: ((Result<[MediaType], KukaiError>) -> Void)? = nil
	private var getMediaTypeDownloadTask: URLSessionDownloadTask? = nil
	
	private static let videoFormats = ["mp4", "mov", "webm"]
	private static let audioFormats = ["mpeg", "mpg", "mp3"]
	private static let imageFormats = ["png", "jpeg", "jpg", "bmp", "tif", "tiff", "svg", "gif", "webp"]
	private static let permanentCache = SDImageCache(namespace: "permanent")
	private static let temporaryCache = SDImageCache(namespace: "temporary")
	
	private static var permanentImageManager: SDWebImageManager? = nil
	private static var temporaryImageManager: SDWebImageManager? = nil
	private static var prefetcher: SDWebImagePrefetcher? = nil
	
	
	public static func setupImageLibrary() {
		MediaProxyService.permanentCache.config.maxMemoryCost = UInt(100 * 1000 * 1000) // 100 MB
		MediaProxyService.permanentImageManager = SDWebImageManager(cache: MediaProxyService.permanentCache, loader: SDImageLoadersManager())
		
		MediaProxyService.temporaryCache.config.maxDiskAge = 3600 * 24 * 7 // 1 Week
		MediaProxyService.temporaryCache.config.maxMemoryCost = UInt(500 * 1000 * 1000) // 500 MB
		
		let temporaryImageManager = SDWebImageManager(cache: MediaProxyService.temporaryCache, loader: SDImageLoadersManager())
		MediaProxyService.temporaryImageManager = temporaryImageManager
		MediaProxyService.prefetcher = SDWebImagePrefetcher(imageManager: temporaryImageManager)
	}
	
	public static func imageManager(forCacheType: CacheType) -> SDWebImageManager? {
		return forCacheType == .temporary ? temporaryImageManager : permanentImageManager
	}
	
	
	// MARK: - URL conversion
	
	/**
	 Take a URI from a token metadata response and convert it to a useable media proxy URL
	 - parameter fromUriString: String containing a URI (supports IPFS URIs)
	 - parameter ofFormat: The requested format from the proxy
	 - returns: An optional URL
	 */
	public static func url(fromUriString uri: String?, ofFormat format: RawFormat, keepGif: Bool = false) -> URL? {
		guard let uri = uri else {
			return nil
		}
		
		return url(fromUri: URL(string: uri), ofFormat: format)
	}
	
	/**
	 Take a URI from a token metadata response and convert it to a useable media proxy URL
	 - parameter fromUri: URL object containing a URI (supports IPFS URIs)
	 - parameter ofFormat: The requested format from the proxy
	 - returns: An optional URL
	 */
	public static func url(fromUri uri: URL?, ofFormat format: RawFormat) -> URL? {
		guard let uri = uri, let scheme = uri.scheme, let strippedURL = uri.absoluteString.components(separatedBy: "://").last else {
			return nil
		}
		
		let sanitizedURL = strippedURL.replacingOccurrences(of: "www.", with: "")
		var source = Source.ipfs
		
		switch scheme {
			case "https":
				source = .web
				
			case "ipfs":
				source = .ipfs
				
			default:
				return nil
		}
		
		return URL(string: "https://data.mantodev.com/media/\(format.rawValue)/\(source.rawValue)/\(sanitizedURL)")
	}
	
	/**
	 Helper method to return a standard thumbnail URL for a NFT, taking into account some custom logic / known workarounds
	 - parameter fromNFT: `NFT` object
	 - returns: An optional URL
	 */
	public static func iconURL(forNFT nft: NFT) -> URL? {
		
		if nft.metadata?.symbol == "OBJKT" {
			return MediaProxyService.url(fromUri: nft.displayURI, ofFormat: Format.icon.rawFormat())
			
		} else {
			return MediaProxyService.url(fromUri: nft.thumbnailURI ?? nft.displayURI, ofFormat: Format.icon.rawFormat())
		}
	}
	
	/**
	 Helper method to return a standard small version of the display URL for a NFT
	 - parameter fromNFT: `NFT` object
	 - returns: An optional URL
	 */
	public static func smallURL(forNFT nft: NFT) -> URL? {
		return MediaProxyService.url(fromUri: nft.displayURI ?? nft.artifactURI, ofFormat: Format.small.rawFormat())
	}
	
	/**
	 Helper method to return a standard medium version of the display URL for a NFT
	 - parameter fromNFT: `NFT` object
	 - returns: An optional URL
	 */
	public static func mediumURL(forNFT nft: NFT) -> URL? {
		return MediaProxyService.url(fromUri: nft.displayURI ?? nft.artifactURI, ofFormat: Format.medium.rawFormat())
	}
	
	/**
	 Helper method to return a standard large version of the display URL for a NFT
	 - parameter fromNFT: `NFT` object
	 - returns: An optional URL
	 */
	public static func largeURL(forNFT nft: NFT) -> URL? {
		return MediaProxyService.url(fromUri: nft.displayURI ?? nft.artifactURI, ofFormat: Format.large.rawFormat())
	}
	
	
	
	// MARK: - Type checking
	
	/**
	 Using only info from `TzKTBalanceMetadataFormat` determine the media type(s) of the object
	 */
	public static func getMediaType(fromFormats formats: [TzKTBalanceMetadataFormat]) -> [MediaType] {
		var types: [MediaType] = []
		
		// Check if the metadata contains a format with a mimetype
		for format in formats {
			if format.mimeType.starts(with: "video/") {
				types.append(.video)
				
			} else if format.mimeType.starts(with: "audio/") {
				types.append(.audio)
				
			} else if format.mimeType.starts(with: "image/") || format.mimeType.starts(with: "application/") {
				types.append(.image)
				
			} else if !format.mimeType.contains("/"), let type = checkFileExtension(fileExtension: format.mimeType) {
				
				// Some tokens have a mimetype that doesn't conform to standard, and only includes the file format
				types.append(type)
			}
		}
		
		return types
	}
	
	/**
	 Given multiple sources of information, attempt to find the media type the url is pointing too
	 - parameter fromFormats: An array of `TzKTBalanceMetadataFormat` that comes down with the TzKTClient's balancing fetching code. It MAY contain infomration on the media type
	 - parameter orURL: The URL for the record. It MAY contain a file extension dennoting the file type
	 - parameter urlSession: If type can't be found via URL or metadata, download the first packet, examine the headers for `Content-Type` using this session. (HEAD requests aren't currently supported if the asset hasn't been already cached)
	 - parameter completion: A block to run when a type can be found, or an error encountered
	 */
	public func getMediaType(fromFormats formats: [TzKTBalanceMetadataFormat], orURL url: URL?, urlSession: URLSession = .shared, completion: @escaping ((Result<[MediaType], KukaiError>) -> Void)) {
		
		let types = MediaProxyService.getMediaType(fromFormats: formats)
		if types.count > 0 {
			completion(Result.success(types))
			return
		}
		
		
		// Check if we can get the type from a file extension in the URL
		guard let url = url else {
			completion(Result.failure(KukaiError.internalApplicationError(error: MediaProxyServiceError.noMimeTypeFoundInsideFormats)))
			return
		}
		
		if url.pathExtension != "", url.pathExtension != "gif", let type = MediaProxyService.checkFileExtension(fileExtension: url.pathExtension) {
			completion(Result.success([type]))
			return
		}
		
		// Else fire off a network request to test the actual file type
		// Can't use a "HEAD" request as it will fail if the proxy is not caching the asset. Need to download a packet and examine the headers, then cancel the request
		self.getMediaTypeCompletion = completion
		self.getMediaTypeDownloadTask = urlSession.downloadTask(with: url)
		self.getMediaTypeDownloadTask?.delegate = self
		self.getMediaTypeDownloadTask?.resume()
	}
	
	/// Helper method to parse an array of `MediaType` to quickly determine its content type so UI can be easily arraged
	public static func typesContents(_ types: [MediaType]) -> AggregatedMediaType? {
		guard types.count > 0 else {
			return nil
		}
		
		let duplicatesRemoved = NSOrderedSet(array: types).map({ $0 as? MediaType })
		if duplicatesRemoved.contains(where: { $0 == .audio }) && duplicatesRemoved.contains(where: { $0 == .image }) {
			return .imageAndAudio
			
		} else if duplicatesRemoved[0] == .video {
			return .videoOnly
			
		} else if duplicatesRemoved[0] == .audio {
			return .audioOnly
			
		} else {
			return .imageOnly
		}
	}
	
	private static func checkFileExtension(fileExtension: String) -> MediaType? {
		if fileExtension != "" {
			if MediaProxyService.imageFormats.contains(fileExtension) {
				return .image
				
			} else if MediaProxyService.audioFormats.contains(fileExtension) {
				return .audio
				
			} else if MediaProxyService.videoFormats.contains(fileExtension) {
				return .video
			}
		}
		
		return nil
	}
	
	
	
	// MARK: - Cache management
	
	/// Clear all images from all caches
	public static func removeAllImages(completion: @escaping (() -> Void)) {
		MediaProxyService.temporaryCache.clearMemory()
		MediaProxyService.temporaryCache.clearDisk {
			MediaProxyService.permanentCache.clearMemory()
			MediaProxyService.permanentCache.clearDisk {
				completion()
			}
		}
	}
	
	public static func removeAllImages(fromCache: CacheType, completion: @escaping (() -> Void)) {
		let cache = imageCache(forType: fromCache)
		cache.clearMemory()
		cache.clearDisk {
			completion()
		}
	}
	
	/// Clear only iamges from cahce that have expired
	public static func clearExpiredImages() {
		MediaProxyService.temporaryCache.deleteOldFiles()
	}
	
	/// Get size in bytes
	public static func sizeOf(cache: CacheType) -> UInt {
		return imageCache(forType: cache).totalDiskSize()
	}
	
	
	
	// MARK: - Image loading
	
	/**
	 Attempt to use KingFisher library to load an image from a URL, into an UIImageView, with support for downsampling, displaying loading spinner, svgs, gifs and the permanent / temporary caching system
	 - parameter url: Media proxy URL pointing to an image
	 - parameter to: The `UIImageView` to load the image into
	 - parameter fromCache: Which cahce to search for the image, or load it into if not found and needs to be downloaded
	 - parameter fallback: If an error occurs and an image can't be downloaded/loaded in, display this image instead
	 - parameter downSampleSize: Supply the dimensions you wish the image to be resized to fit
	 - parameter completion: returns when operation finished, if successful it will return the downloaded image's CGSize
	 */
	public static func load(url: URL?, to imageView: UIImageView, withCacheType cacheType: CacheType, fallback: UIImage, downSampleSize: CGSize? = nil, completion: ((CGSize?) -> Void)? = nil) {
		guard let url = url else {
			imageView.image = fallback
			if let comp = completion { comp(nil) }
			return
		}
		
		
		// Don't donwload real images during unit tests. Investigate mocking kingfisher
		if Thread.current.isRunningXCTest { return }
		
		
		var options: [SDWebImageContextOption: Any] = [:]
		if let downSampleSize = downSampleSize {
			options[.imageTransformer] = SDImageResizingTransformer(size: downSampleSize, scaleMode: .fill)
		}
		
		
		imageView.sd_imageIndicator = SDWebImageProgressIndicator.default
		imageManager(forCacheType: cacheType)?.loadImage(with: url, context: options, progress: nil, completed: { image, data, error, sdCacheType, success, url in
			
			if image != nil {
				imageView.image = image
			} else {
				imageView.image = fallback
			}
			
			completion?(image?.size)
		})
	}
	
	public static func imageCache(forType: CacheType) -> SDImageCache {
		if forType == .temporary {
			return MediaProxyService.temporaryCache
		} else {
			return MediaProxyService.permanentCache
		}
	}
	
	/**
	 Attempt to use KingFisher library to load an image from a URL, and store it directly in the cache for later usage. Also optional return the downloaded size via a completion block, useful for preparing table/collection view
	 - parameter url: Media proxy URL pointing to an image
	 - parameter fromCache: Which cahce to search for the image, or load it into if not found and needs to be downloaded
	 - parameter completion: returns when operation finished, if successful it will return the downloaded image's CGSize
	 */
	public static func cacheImage(url: URL?, cacheType: CacheType = .temporary, completion: @escaping ((CGSize?) -> Void)) {
		guard let url = url else {
			completion(nil)
			return
		}
		
		// Don't donwload real images during unit tests. Investigate mocking kingfisher
		if Thread.current.isRunningXCTest { return }
		
		
		MediaProxyService.prefetcher?.prefetchURLs([url], progress: nil, completed: { finishedURLs, skippedURLs in
			let size = MediaProxyService.temporaryCache.imageFromCache(forKey: url.absoluteString)?.size
			
			if skippedURLs > 0 {
				Logger.kukaiCoreSwift.error("Error downloading + caching image")
			}
			
			completion(size)
		})
	}
	
	/// Check if a given url is already cached
	public static func isCached(url: URL?, cacheType: CacheType = .temporary) -> Bool {
		guard let url = url else {
			return false
		}
		
		return imageCache(forType: cacheType).diskImageDataExists(withKey: url.absoluteString)
	}
	
	/**
	 Check if an image is cached, and return its size if so. Useful for preparing table/collection view
	 - parameter url: Media proxy URL pointing to an image
	 - parameter fromCache: Which cahce to search for the image, or load it into if not found and needs to be downloaded
	 - parameter completion: returns when operation finished, if successful it will return the downloaded image's CGSize
	 */
	public static func sizeForImageIfCached(url: URL?, cacheType: CacheType = .temporary, completion: @escaping ((CGSize?) -> Void) ) {
		guard let url = url else {
			completion(nil)
			return
		}
		
		let size = imageCache(forType: cacheType).imageFromCache(forKey: url.absoluteString)?.size
		completion(size)
	}
}

extension MediaProxyService: URLSessionDownloadDelegate {
	
	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		process(downloadTask: downloadTask)
	}
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		guard let completion = self.getMediaTypeCompletion, let e = error, e.code != -999 else {
			// When .cancel() is called it also triggers this callback, but without an error. Just ignore
			return
		}
		
		completion(Result.failure(KukaiError.internalApplicationError(error: e)))
	}
	
	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		process(downloadTask: downloadTask)
	}
	
	private func process(downloadTask: URLSessionDownloadTask) {
		// We are only interested in seeing the "Content-Type" header. As soon as we have received 1 packet, cancel the request, examine the header and return
		// "HEAD" requests fail if the proxy hasn't seen the asset before
		downloadTask.cancel()
		
		guard let completion = self.getMediaTypeCompletion else {
			return
		}
		
		guard let httpResponse = downloadTask.response as? HTTPURLResponse, let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") else {
			completion(Result.failure(KukaiError.internalApplicationError(error: MediaProxyServiceError.unableToParseContentType)))
			return
		}
		
		if contentType.contains("video/") {
			completion(Result.success([.video]))
			
		} else if contentType.contains("audio/") {
			completion(Result.success([.audio]))
			
		} else {
			completion(Result.success([.image]))
		}
	}
}

/*
public class ContentTypeCheckingImageDownloader: ImageDownloader {
	
	public override func startDownloadTask(context: DownloadingContext, callback: SessionDataTask.TaskCallback) -> DownloadTask {
		
		let downloadTask = addDownloadTask(context: context, callback: callback)
		
		let sessionTask = downloadTask.sessionTask
		guard !sessionTask.started else {
			return downloadTask
		}
		
		sessionTask.onTaskDone.delegate(on: self) { (self, done) in
			// Underlying downloading finishes.
			// result: Result<(Data, URLResponse?)>, callbacks: [TaskCallback]
			let (result, callbacks) = done
			
			// Before processing the downloaded data.
			self.reportDidDownloadImageData(result: result, url: context.url)
			
			switch result {
					
				// Download finished. Now process the data to an image.
				case .success(let (data, response)):
					
					let processor = ImageDataProcessor(data: data, callbacks: callbacks, processingQueue: context.options.processingQueue)
					
					// If we are downloading an SVG, replace DefaultImageProcessor with SVGImgProcessor
					if let httpResponse = response as? HTTPURLResponse, let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"), contentType.contains("svg") {
						for (index, callback) in processor.callbacks.enumerated() {
							if callback.options.processor.identifier == DefaultImageProcessor.default.identifier {
								processor.callbacks[index].options.processor = SVGImgProcessor()
							}
						}
					}
					
					processor.onImageProcessed.delegate(on: self) { (self, done) in
						// `onImageProcessed` will be called for `callbacks.count` times, with each
						// `SessionDataTask.TaskCallback` as the input parameter.
						// result: Result<Image>, callback: SessionDataTask.TaskCallback
						let (result, callback) = done
						
						self.reportDidProcessImage(result: result, url: context.url, response: response)
						
						let imageResult = result.map { ImageLoadingResult(image: $0, url: context.url, originalData: data) }
						let queue = callback.options.callbackQueue
						queue.execute { callback.onCompleted?.call(imageResult) }
					}
					processor.process()
					
				case .failure(let error):
					callbacks.forEach { callback in
						let queue = callback.options.callbackQueue
						queue.execute { callback.onCompleted?.call(.failure(error)) }
					}
			}
		}
		
		reportWillDownloadImage(url: context.url, request: context.request)
		sessionTask.resume()
		return downloadTask
	}
}
*/
