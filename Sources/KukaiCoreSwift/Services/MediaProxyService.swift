//
//  MediaProxyService.swift
//  
//
//  Created by Simon Mcloughlin on 01/02/2022.
//

import UIKit
import Kingfisher

public class MediaProxyService {
	
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
	
	public struct Constants {
		public static let permanentImageCacheName = "kukai-mediaproxy-permanent"
		public static let temporaryImageCacheName = "kukai-mediaproxy-temporary"
	}
	
	
	
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
	/*
	/**
	 Cloudflare provides an IPFS gateway, take the IPFS URL and reformat to work with cloudflares URL structure
	 */
	private func ipfsURIToCloudflareURL(uri: URL) -> URL? {
		if let strippedURI = uri.absoluteString.components(separatedBy: "ipfs://").last, let url = URL(string: "https://cloudflare-ipfs.com/ipfs/\(strippedURI)") {
			return url
		}
		
		return nil
	}
	*/
	
	public static func thumbnailURL(uri: URL) -> URL? {
		return MediaProxyService.url(fromUri: uri, ofFormat: .icon)
	}
	
	public static func displayURL(uri: URL) -> URL? {
		return MediaProxyService.url(fromUri: uri, ofFormat: .small)
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
