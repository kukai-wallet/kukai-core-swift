//
//  MediaProxySerivceTests.swift
//  
//
//  Created by Simon Mcloughlin on 10/02/2022.
//

import Foundation
@testable import KukaiCoreSwift
import XCTest

class MediaProxySerivceTests: XCTestCase {
	
	static let ipfsURIWithoutExtension = "ipfs://bafybeiatpitaej7bynhsequ5hl45jbtjft2nkkho74jfocvnw4vrqlhdea"
	static let ipfsURIWithExtension = "ipfs://Qmczgp9juksRrzDkXUQQQFb9xwNDimv1gTy6kLjZqVNPoX/display/1012.png"
	static let httpsURI = "https://uxwing.com/wp-content/themes/uxwing/download/20-food-and-drinks/rice.png"
	
	let mediaProxyService = MediaProxyService()
	
	override func setUpWithError() throws {
		
	}
	
	override func tearDownWithError() throws {
		
	}
	
	func testURLFormatters() {
		let url1 = MediaProxyService.url(fromUriString: MediaProxySerivceTests.ipfsURIWithoutExtension, ofFormat: .mobile64)
		let url2 = MediaProxyService.url(fromUriString: MediaProxySerivceTests.ipfsURIWithExtension, ofFormat: .mobile128)
		let url3 = MediaProxyService.url(fromUriString: MediaProxySerivceTests.httpsURI, ofFormat: .mobile180)
		let url4 = MediaProxyService.url(fromUriString: MediaProxySerivceTests.ipfsURIWithoutExtension, ofFormat: .mobile900)
		
		XCTAssert(url1?.absoluteString == "https://data.mantodev.com/media/mobile64/ipfs/bafybeiatpitaej7bynhsequ5hl45jbtjft2nkkho74jfocvnw4vrqlhdea", url1?.absoluteString ?? "")
		XCTAssert(url2?.absoluteString == "https://data.mantodev.com/media/mobile128/ipfs/Qmczgp9juksRrzDkXUQQQFb9xwNDimv1gTy6kLjZqVNPoX/display/1012.png", url2?.absoluteString ?? "")
		XCTAssert(url3?.absoluteString == "https://data.mantodev.com/media/mobile180/web/uxwing.com/wp-content/themes/uxwing/download/20-food-and-drinks/rice.png", url3?.absoluteString ?? "")
		XCTAssert(url4?.absoluteString == "https://data.mantodev.com/media/mobile900/ipfs/bafybeiatpitaej7bynhsequ5hl45jbtjft2nkkho74jfocvnw4vrqlhdea", url4?.absoluteString ?? "")
		
		let url5 = MediaProxyService.url(fromUri: URL(string: MediaProxySerivceTests.ipfsURIWithoutExtension), ofFormat: .mobile64)
		let url6 = MediaProxyService.url(fromUri: URL(string: MediaProxySerivceTests.ipfsURIWithExtension), ofFormat: .mobile64)
		let url7 = MediaProxyService.url(fromUri: URL(string: MediaProxySerivceTests.httpsURI), ofFormat: .mobile64)
		
		XCTAssert(url5?.absoluteString == "https://data.mantodev.com/media/mobile64/ipfs/bafybeiatpitaej7bynhsequ5hl45jbtjft2nkkho74jfocvnw4vrqlhdea", url5?.absoluteString ?? "")
		XCTAssert(url6?.absoluteString == "https://data.mantodev.com/media/mobile64/ipfs/Qmczgp9juksRrzDkXUQQQFb9xwNDimv1gTy6kLjZqVNPoX/display/1012.png", url6?.absoluteString ?? "")
		XCTAssert(url7?.absoluteString == "https://data.mantodev.com/media/mobile64/web/uxwing.com/wp-content/themes/uxwing/download/20-food-and-drinks/rice.png", url7?.absoluteString ?? "")
		
		let url8 = MediaProxyService.iconURL(forNFT: MockConstants.tokenWithNFTs.nfts![0])
		let url9 = MediaProxyService.smallURL(forNFT: MockConstants.tokenWithNFTs.nfts![0])
		
		XCTAssert(url8?.absoluteString == "https://data.mantodev.com/media/mobile64/ipfs/Qmczgp9juksRrzDkXUQQQFb9xwNDimv1gTy6kLjZqVNPoX/display/1012.png", url8?.absoluteString ?? "-")
		XCTAssert(url9?.absoluteString == "https://data.mantodev.com/media/mobile180/ipfs/bafybeiatpitaej7bynhsequ5hl45jbtjft2nkkho74jfocvnw4vrqlhdea", url9?.absoluteString ?? "-")
		
		let url10 = MediaProxyService.mediumURL(forNFT: MockConstants.tokenWithNFTs.nfts![0])
		let url11 = MediaProxyService.largeURL(forNFT: MockConstants.tokenWithNFTs.nfts![0])
		
		XCTAssert(url10?.absoluteString == "https://data.mantodev.com/media/mobile600/ipfs/bafybeiatpitaej7bynhsequ5hl45jbtjft2nkkho74jfocvnw4vrqlhdea", url10?.absoluteString ?? "-")
		XCTAssert(url11?.absoluteString == "https://data.mantodev.com/media/mobile900/ipfs/bafybeiatpitaej7bynhsequ5hl45jbtjft2nkkho74jfocvnw4vrqlhdea", url11?.absoluteString ?? "-")
		
		let alreadyConverted = URL(string: "https://data.mantodev.com/media/mobile64/ipfs/bafybeiatpitaej7bynhsequ5hl45jbtjft2nkkho74jfocvnw4vrqlhdea")
		let testConversion = MediaProxyService.url(fromUri: alreadyConverted, ofFormat: .mobile64)
		XCTAssert(testConversion?.absoluteString == "https://data.mantodev.com/media/mobile64/ipfs/bafybeiatpitaej7bynhsequ5hl45jbtjft2nkkho74jfocvnw4vrqlhdea", testConversion?.absoluteString  ?? "-")
	}
	
	func testMediaTypeCheckerFromFormat() {
		let imageFormats = [TzKTBalanceMetadataFormat(uri: MediaProxySerivceTests.ipfsURIWithoutExtension, mimeType: "image/png", dimensions: nil)]
		let videoFormats = [TzKTBalanceMetadataFormat(uri: MediaProxySerivceTests.ipfsURIWithoutExtension, mimeType: "video/mp4", dimensions: nil)]
		let audioFormats = [TzKTBalanceMetadataFormat(uri: MediaProxySerivceTests.ipfsURIWithoutExtension, mimeType: "audio/mp3", dimensions: nil)]
		
		let expectationImage = XCTestExpectation(description: "media serivce image")
		mediaProxyService.getMediaType(fromFormats: imageFormats, orURL: URL(string: MediaProxySerivceTests.ipfsURIWithoutExtension)) { result in
			
			switch result {
				case .success(let mediaType):
					XCTAssert(mediaType[0] == .image, mediaType[0].rawValue)
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectationImage.fulfill()
		}
		
		let expectationVideo = XCTestExpectation(description: "media serivce video")
		mediaProxyService.getMediaType(fromFormats: videoFormats, orURL: URL(string: MediaProxySerivceTests.ipfsURIWithoutExtension)) { result in
			
			switch result {
				case .success(let mediaType):
					XCTAssert(mediaType[0] == .video, mediaType[0].rawValue)
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectationVideo.fulfill()
		}
		
		let expectationAudio = XCTestExpectation(description: "media serivce audio")
		mediaProxyService.getMediaType(fromFormats: audioFormats, orURL: URL(string: MediaProxySerivceTests.ipfsURIWithoutExtension)) { result in
			
			switch result {
				case .success(let mediaType):
					XCTAssert(mediaType[0] == .audio, mediaType[0].rawValue)
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectationAudio.fulfill()
		}
		
		wait(for: [expectationImage, expectationVideo, expectationAudio], timeout: 120)
	}
	
	func testMediaTypeCheckerFromUrlExtension() {
		let expectation = XCTestExpectation(description: "media serivce extension url")
		mediaProxyService.getMediaType(fromFormats: [], orURL: URL(string: MediaProxySerivceTests.ipfsURIWithExtension)) { result in
			
			switch result {
				case .success(let mediaType):
					XCTAssert(mediaType[0] == .image, mediaType[0].rawValue)
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
	
	func testMediaTypeCheckerFromHeaders() {
		let expectation = XCTestExpectation(description: "media service request")
		mediaProxyService.getMediaType(fromFormats: [], orURL: URL(string: MediaProxySerivceTests.ipfsURIWithoutExtension), urlSession: MockConstants.shared.networkService.urlSession) { result in
			
			switch result {
				case .success(let mediaType):
					XCTAssert(mediaType[0] == .image, mediaType[0].rawValue)
					
				case .failure(let error):
					XCTFail("Error: \(error)")
			}
			
			expectation.fulfill()
		}
		
		wait(for: [expectation], timeout: 120)
	}
}
