//
//  Config.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 7/22/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI
import Combine

let longPressDuration = 0.15
let longPressMaxDrift: CGFloat = 0.1
let listViewExtension: CGFloat = 200
let interestThreshold: Float = -1
let rechargeLevel: Float = 3

struct AppState {
	var currentPosition: Int? = nil
}

extension AppState {
	struct Injection: EnvironmentKey {
		let appState: CurrentValueSubject<AppState, Never>
		static var defaultValue: Self {
			return .init(appState: .init(AppState()))
		}
	}
}

extension EnvironmentValues {
	var injected: AppState.Injection {
		get { self[AppState.Injection.self] }
		set { self[AppState.Injection.self] = newValue }
	}
}

// Emables us to send changes back to the app state
extension Binding where Value: Equatable {
	func dispatched(to state: CurrentValueSubject<AppState, Never>,
									_ keyPath: WritableKeyPath<AppState, Value>) -> Self {
		return .init(
			get: { () -> Value in
				self.wrappedValue
		}, set: { newValue in
			self.wrappedValue = newValue
			state.value[keyPath: keyPath] = newValue
		})
	}
}

// usage:
//let injected = AppState.Injection(appState: .init(AppState()))
//let contentView = ContentView().environment(\.injected, injected)

/*
struct ContentView: View {
	
	// The local view's state encapsulated in one container:
	@State private var state = ViewState()
	
	// The app's state injection
	@Environment(\.appState) private var injected: AppState.Injection
	
	var body: some View {
		Text("Value: \(state.value)")
			.onReceive(stateUpdate) { self.state = $0 }
	}
	
	// The state update filtering
	private var stateUpdate: AnyPublisher<ViewState, Never> {
		injected.appState.map { $0.viewState }
			.removeDuplicates().eraseToAnyPublisher()
	}
}

// Convenient mapping from AppState to ViewState
private extension AppState {
	var viewState: ContentView.ViewState {
		return .init(value: value1)
	}
}

*/
