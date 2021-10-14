//
//  Publisher+extensions.swift
//  
//
//  Created by Simon Mcloughlin on 11/10/2021.
//

import Combine

public extension Publisher {
	
	/**
	 Wrap a Publisher in a Future of type `<Output, Never>`
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
	 Wrap a Publisher in a Deferred Future of type `<Output, Never>`
	 */
	func asDeferredFuture() -> Deferred<Future<Output, Never>> {
		return Deferred { self.asFuture() }
	}
	
	/**
	 Convert a publisher output into a swift `Result`object to make handling `sink`'s easier
	 */
	func convertToResult() -> AnyPublisher<Result<Output, Failure>, Never> {
		self.map(Result.success)
			.catch { Just(.failure($0)) }
			.eraseToAnyPublisher()
	}
	
	/**
	 Call .handleEvents, but only use the `receiveOutput` callback as a shorthand way of running some logic or clean up code
	 */
	func onReceiveOutput(_ callback: @escaping ((Self.Output) -> Void)) -> Publishers.HandleEvents<Self> {
		return self.handleEvents(receiveSubscription: nil, receiveOutput: callback, receiveCompletion: nil, receiveCancel: nil, receiveRequest: nil)
	}
	
	/**
	 Custom sink implementation breaking each piece into a seperate dedicated callback, avoiding the need to call a switch or unwrap an error
	 */
	func sink(onError: @escaping ((Failure) -> Void), onSuccess: @escaping ((Output) -> Void), onComplete: (() -> Void)? = nil) -> AnyCancellable {
		return self.sink { completion in
			
			switch completion {
				case .failure(let error):
					onError(error)
				
				case .finished:
					if let onComp = onComplete {
						onComp()
					}
			}
			
		} receiveValue: { output in
			onSuccess(output)
		}
	}
}



public extension AnyPublisher {
	
	/**
	 Helper for returning a `Just` publisher, with the appropriate Failure type and erased to `AnyPublisher`
	 */
	static func just(_ output: Output) -> Self {
		Just(output)
			.setFailureType(to: Failure.self)
			.eraseToAnyPublisher()
	}
	
	/**
	 Helper for returning a `Fail` publisher, erased to `AnyPublisher`
	 */
	static func fail(with error: Failure) -> Self {
		Fail(error: error).eraseToAnyPublisher()
	}
	
	/**
	 Call .handleEvents, but only use the `receiveOutput` callback as a shorthand way of running some logic or clean up code
	 */
	func onReceiveOutput(_ callback: @escaping ((Self.Output) -> Void)) -> Publishers.HandleEvents<Self> {
		return self.handleEvents(receiveSubscription: nil, receiveOutput: callback, receiveCompletion: nil, receiveCancel: nil, receiveRequest: nil)
	}
	
	/**
	 Custom sink implementation breaking each piece into a seperate dedicated callback, avoiding the need to call a switch or unwrap an error
	 */
	func sink(onError: @escaping ((Failure) -> Void), onSuccess: @escaping ((Output) -> Void), onComplete: (() -> Void)? = nil) -> AnyCancellable {
		return self.sink { completion in
			
			switch completion {
				case .failure(let error):
					onError(error)
				
				case .finished:
					if let onComp = onComplete {
						onComp()
					}
			}
			
		} receiveValue: { output in
			onSuccess(output)
		}
	}
}
