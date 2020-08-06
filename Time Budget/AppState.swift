//
//  Config.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 7/22/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI
import Combine

let longPressDuration = 0.25
let longPressMaxDrift: CGFloat = 0.1
let listViewExtension: CGFloat = 200
let interestThreshold: Float = -1000
let stateChangeCollectionTime: Int = 10
let longPeriod: Float = Float(days)

enum ViewRefreshKey {
	case topView, budgetStack, fundList, dayView
}

class AppState {
	private init() {
		debugLog("AppState.init")
	}
	
	static let subject = PassthroughSubject<ViewRefreshKey, Never>()
	private static let singleton = AppState()
	static func get() -> AppState { singleton }
	
	@Bindable(send: .topView, to: subject, beforeSet: {
		(beforeValue, afterValue) in
		if beforeValue == afterValue && afterValue == .day {
			AppState.get().dayViewResetListPosition = true
		}
	})
	var mainTabSelection = MainTabSelection.fund
	
	@Bindable(send: .budgetStack, to: subject)
	var budgetStack: BudgetStack = BudgetStack()
	
	@Bindable(send: .dayView, to: subject)
	var dayViewResetListPosition: Bool = true
	
	@Bindable(send: false)
	var dayViewPosition: CGPoint = CGPoint(x: 0, y: 0)
	
	@Bindable(send: .dayView, to: subject)
	var dayViewExpensePeriod: TimeInterval = 30 * minutes
	
	@Bindable(send: .dayView, to: subject)
	var dayViewPlusMinusDays: Int = 1
	
	@Bindable(send: .dayView, to: subject)
	var dayViewAction: DayViewAction = .add
	
	@Bindable(send: .dayView, to: subject)
	var dayViewActionDetail: String = "No action selected"
	
	var dayViewPeriodsPerDay: Int {
		return Int(oneDay / dayViewExpensePeriod)
	}
	
	@Bindable(send: .fundList, to: subject)
	var fundListAction: FundAction = .view
	
	@Bindable(send: .fundList, to: subject)
	var fundListActionDetail: String = "No action selected"
	
	@Bindable(send: .fundList, to: subject)
	var ratioDisplayMode: RatioDisplayMode = .percentage
	
	@Bindable(send: false)
	var lastSelectedFund: TimeFund? = nil
	
	@Bindable(send: .topView, to: subject)
	var titleOverride: String? = nil
	
	var title: String {
		var title: String
		if titleOverride != nil {
			title = titleOverride!
		} else {
			if budgetStack.hasTopBudget() {
				title = budgetStack.getTopBudget().name
			} else {
				title = "None"
			}
		}
		return title
	}
	
	var budgetNameFontSize: CGFloat {
		let budgetNameSize = title.count
		var size: CGFloat
		if budgetNameSize > 20 {
			size = 15
		} else if budgetNameSize > 10 {
			size = 20
		} else {
			size = 30
		}
		return size
	}
	
	private let updateTimer: Timer = Timer(timeInterval: 5 * minutes, repeats: true, block: { _ in
		subject.send(.dayView)
	})

}
