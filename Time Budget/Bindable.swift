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
	private let afterSet: (T, T) -> Void

	init(
		wrappedValue: T,
		send messages: [M] = [],
		to subject: PassthroughSubject<M, Never>? = nil,
		beforeSet: @escaping (T, T) -> Void = {(_, _) in},
		afterSet: @escaping (T, T) -> Void = {(_, _) in}
	) {
		self.internalValue = wrappedValue
		self.messagesToSend = messages
		self.subject = subject
		self.beforeSet = beforeSet
		self.afterSet = afterSet
	}
	
	var wrappedValue: T {
		get {
			internalValue
		}
		set {
			let oldValue = internalValue
			beforeSet(oldValue, newValue)
			let changed = internalValue != newValue
			internalValue = newValue
			if changed {
				if let s = subject {
					for message in messagesToSend {
						debugLog("Bindable: sending \(message)")
						s.send(message)
					}
				}
			}
			afterSet(oldValue, newValue)
		}
	}
	
	var projectedValue: Binding<T> {
		Binding<T>(
			get: {
				self.internalValue
		},
			set: {
				let oldValue = self.internalValue
				self.beforeSet(oldValue, $0)
				let changed = oldValue != $0
				self.internalValue = $0
				if changed {
					if let s = self.subject {
						for message in self.messagesToSend {
							debugLog("Bindable: sending \(message)")
							s.send(message)
						}
					}
				}
				self.afterSet(oldValue, $0)
		}
		)
	}
	
}
