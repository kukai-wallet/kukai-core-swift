//
//  MediaProxyService.swift
//  
//
//  Created by Simon Mcloughlin on 01/02/2022.
//

import UIKit
import Kingfisher

public class MediaProxyService: NSObject {
	
	public enum Format: String, Codable {
		case icon		// 80px
		case small		// 300px
		case medium		// 600px
		case gallery	// 1200px
		case raw		// original
	}
	
	public enum Source: String, Codable {
		case ipfs
		case web
	}
	
	public enum MediaType: String, Codable {
		case image
		case audio
		case video
	}
	
	public struct Constants {
		public static let permanentImageCacheName = "kukai-mediaproxy-permanent"
		public static let temporaryImageCacheName = "kukai-mediaproxy-temporary"
	}
	
	
	private var getMediaTypeCompletion: ((Result<MediaType, ErrorResponse>) -> Void)? = nil
	private var getMediaTypeDownloadTask: URLSessionDownloadTask? = nil
	
	
	
	// MARK: - URL conversion
	
	public static func url(fromUriString uri: String?, ofFormat format: Format) -> URL? {
		guard let uri = uri else {
			return nil
		}
		
		return url(fromUri: URL(string: uri), ofFormat: format)
	}
	
	public static func url(fromUri uri: URL?, ofFormat format: Format) -> URL? {
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
		
		return URL(string: "https://static.tcinfra.net/media/\(format.rawValue)/\(source.rawValue)/\(sanitizedURL)")
	}
	
	public static func thumbnailURL(uri: URL) -> URL? {
		return MediaProxyService.url(fromUri: uri, ofFormat: .icon)
	}
	
	public static func displayURL(uri: URL) -> URL? {
		return MediaProxyService.url(fromUri: uri, ofFormat: .small)
	}
	
	
	
	// MARK: - Type checking
	
	public func getMediaType(fromFormats formats: [TzKTBalanceMetadataFormat], orURL url: URL, completion: @escaping ((Result<MediaType, ErrorResponse>) -> Void)) {
		
		// Check if the metadata contains a format with a mimetype
		// Gifs may be reencoded as videos, so ignore them
		for format in formats {
			if format.mimeType.starts(with: "video/") {
				completion(Result.success(.video))
				return
				
			} else if format.mimeType.starts(with: "audio/") {
				completion(Result.success(.audio))
				return
				
			} else if (format.mimeType.starts(with: "image/") || format.mimeType.starts(with: "application/")) && format.mimeType != "image/gif" {
				completion(Result.success(.image))
				return
			}
		}
		
		// Check if we can get the type from a file extension in the URL
		if url.pathExtension != "", url.pathExtension != "gif" {
			if ["png", "jpeg", "jpg", "bmp", "tif", "tiff"].contains(url.pathExtension) {
				completion(Result.success(.image))
				return
				
			} else if ["mpeg", "mpg", "mp3"].contains(url.pathExtension) {
				completion(Result.success(.audio))
				return
				
			} else if ["mp4", "mov"].contains(url.pathExtension) {
				completion(Result.success(.video))
				return
			}
		}
		
		// Else fire off a network request to test the actual file type
		// Can't use a "HEAD" request as it will fail if the proxy is not caching the asset. Need to download a packet and examine the headers, then cancel the request
		self.getMediaTypeCompletion = completion
		self.getMediaTypeDownloadTask = URLSession.shared.downloadTask(with: url)
		self.getMediaTypeDownloadTask?.delegate = self
		self.getMediaTypeDownloadTask?.resume()
	}
	
	
	
	
	// MARK: - Cache management
	
	public static func permanentImageCache() -> ImageCache {
		let cache = ImageCache(name: MediaProxyService.Constants.permanentImageCacheName)
		cache.diskStorage.config.expiration = .never
		
		return cache
	}
	
	public static func temporaryImageCache() -> ImageCache {
		let cache = ImageCache(name: MediaProxyService.Constants.temporaryImageCacheName)
		cache.diskStorage.config.expiration = .days(30)
		
		return cache
	}
	
	public static func removeAllImages() {
		MediaProxyService.permanentImageCache().clearCache(completion: nil)
		MediaProxyService.temporaryImageCache().clearCache(completion: nil)
	}
	
	public static func clearExpiredImages() {
		MediaProxyService.temporaryImageCache().cleanExpiredCache(completion: nil)
	}
	
	
	
	// MARK: - Image loading
	
	public static func load(url: URL?, to imageView: UIImageView, fromCache cache: ImageCache, fallback: UIImage, downSampleSize: (width: Int, height: Int)?) {
		guard let url = url else {
			imageView.image = fallback
			return
		}
		
		
		// Don't donwload real images during unit tests. Investigate mocking kingfisher
		if Thread.current.isRunningXCTest { return }
		
		let fileExtension = url.absoluteString.components(separatedBy: ".").last ?? ""
		var processors: [KingfisherOptionsInfoItem] = [.originalCache(cache)]
		
		if fileExtension == "svg" {
			processors = [.processor(SVGImgProcessor())]
			
		} else if fileExtension == "gif" {
			// Do nothing, all handled by default
			processors = []
			
		} else if let size = downSampleSize {
			// Only possible on non SVG's and non gifs, like jpeg, png etc
			processors = [.processor( DownsamplingImageProcessor(size: CGSize(width: size.width, height: size.height)))]
		}
		
		imageView.kf.indicatorType = .activity
		imageView.kf.setImage(with: url, options: processors) { result in
			guard let _ = try? result.getError() else {
				return
			}
			
			// If image downloading fails, display fallback image
			imageView.image = fallback
		}
	}
}

extension MediaProxyService: URLSessionDownloadDelegate {
	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		
	}
	
	public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		guard let completion = self.getMediaTypeCompletion else {
			return
		}
		
		if let e = error {
			completion(Result.failure(ErrorResponse.internalApplicationError(error: e)))
		} else {
			completion(Result.failure(ErrorResponse.unknownError()))
		}
	}
	
	public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		
		// We are only interested in seeing the "Content-Type" header. As soon as we have received 1 packet, cancel the request, examine the header and return
		// "HEAD" requests fail if the proxy hasn't seen the asset before, so to be safe and avoid complex code, just assume its not there
		downloadTask.cancel()
		
		guard let completion = self.getMediaTypeCompletion else {
			return
		}
		
		guard let httpResponse = downloadTask.response as? HTTPURLResponse, let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") else {
			completion(Result.failure(ErrorResponse.error(string: "Unbale to parse Content Type", errorType: .internalApplicationError)))
			return
		}
		
		if contentType.contains("video/") {
			completion(Result.success(.video))
			
		} else if contentType.contains("audio/") {
			completion(Result.success(.audio))
			
		} else {
			completion(Result.success(.image))
		}
	}
}
