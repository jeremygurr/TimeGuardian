//
//  Bindable.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 8/4/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI
import Combine

@propertyWrapper
class Bindable<T: Equatable, M> {
	
	private var internalValue: T
	private let messagesToSend: [M]
	private var subject: PassthroughSubject<M, Never>?
	private let beforeSet: (T, T) -> Void
	
	init(
		wrappedValue: T,
		send messages: [M],
		to subject: PassthroughSubject<M, Never>? = nil,
		beforeSet: @escaping (T, T) -> Void = {(_, _) in}
	) {
		self.internalValue = wrappedValue
		self.messagesToSend = messages
		self.subject = subject
		self.beforeSet = beforeSet
	}
	
	var wrappedValue: T {
		get {
			internalValue
		}
		set {
			beforeSet(internalValue, newValue)
			if internalValue != newValue {
				internalValue = newValue
				if let s = subject {
					for message in messagesToSend {
						debugLog("Bindable: sending \(message)")
						s.send(message)
					}
				}
			}
		}
	}
	
	var projectedValue: Binding<T> {
		Binding<T>(
			get: {
				self.internalValue
		},
			set: {
				self.beforeSet(self.internalValue, $0)
				if self.internalValue != $0 {
					self.internalValue = $0
					if let s = self.subject {
						for message in self.messagesToSend {
							debugLog("Bindable: sending \(message)")
							s.send(message)
						}
					}
				}
		}
		)
	}
	
}
