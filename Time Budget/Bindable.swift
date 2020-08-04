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
	private let messageToSend: M
	private var subject: PassthroughSubject<M, Never>
	
	init(
		wrappedValue: T,
		send message: M,
		to subject: PassthroughSubject<M, Never>
	) {
		self.internalValue = wrappedValue
		self.messageToSend = message
		self.subject = subject
	}
	
	var wrappedValue: T {
		get {
			internalValue
		}
		set {
			if internalValue != newValue {
				internalValue = newValue
				debugLog("sending \(messageToSend)")
				subject.send(messageToSend)
			}
		}
	}
	
	var projectedValue: Binding<T> {
		Binding<T>(
			get: {
				self.internalValue
		},
			set: {
				if self.internalValue != $0 {
					self.internalValue = $0
					debugLog("sending \(self.messageToSend)")
					self.subject.send(self.messageToSend)
				}
		}
		)
	}
	
}
