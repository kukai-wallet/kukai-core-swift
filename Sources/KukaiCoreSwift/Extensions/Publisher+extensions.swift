//
//  Publisher+extensions.swift
//  
//
//  Created by Simon Mcloughlin on 11/10/2021.
//

import Combine

public extension Publisher {
	
	/**
	 Convert a publisher into a Future
	 */
	func asFuture() -> Future<Output, Never> {
		var subscriptions = Set<AnyCancellable>()
		
		return Future<Output, Never> { promise in
			self.sink(receiveCompletion: { _ in
				subscriptions.removeAll()
				
			}, receiveValue: { value in
				promise(.success(value))
			})
			.store(in: &subscriptions)
		}
	}
	
	/**
	 Convert a publisher into a Deferred Future. Useful for mapping @Published vars into a Future, so the results of funcitons can be dasiy chained together
	 */
	func asDeferredFuture() -> Deferred<Future<Output, Never>> {
		return Deferred { self.asFuture() }
	}
}
