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
class Bindable<T, M> {
	
	private var internalValue: T
	private let messageToSend: M
	private var subject: CurrentValueSubject<M, Never>
	
	init(wrappedValue: T, send message: M, to subject: CurrentValueSubject<M, Never>) {
		self.internalValue = wrappedValue
		self.messageToSend = message
		self.subject = subject
	}
	
	var wrappedValue: T {
		get {
			internalValue
		}
		set {
			internalValue = newValue
			subject.send(messageToSend)
		}
	}
	
	var projectedValue: Binding<T> {
		Binding<T>(
			get: {
				self.internalValue
		},
			set: {
				self.internalValue = $0
				self.subject.send(self.messageToSend)
		}
		)
	}
	
}
