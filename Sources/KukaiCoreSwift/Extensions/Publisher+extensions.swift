//
//  Publisher+extensions.swift
//  
//
//  Created by Simon Mcloughlin on 11/10/2021.
//

import Combine

public extension Publisher {
	
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
	
	func asDeferredFuture() -> Deferred<Future<Output, Never>> {
		return Deferred { self.asFuture() }
	}
	
	func convertToResult() -> AnyPublisher<Result<Output, Failure>, Never> {
		self.map(Result.success)
			.catch { Just(.failure($0)) }
			.eraseToAnyPublisher()
	}
}

public extension AnyPublisher {
	
	static func just(_ output: Output) -> Self {
		Just(output)
			.setFailureType(to: Failure.self)
			.eraseToAnyPublisher()
	}
	
	static func fail(with error: Failure) -> Self {
		Fail(error: error).eraseToAnyPublisher()
	}
}
