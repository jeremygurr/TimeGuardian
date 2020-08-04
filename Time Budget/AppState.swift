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
let interestThreshold: Float = -1000

enum ViewRefreshKey {
	case none, budgetStack
}

class AppState {
	private init() {
		debugLog("AppState.init")
	}
	
	static let subject = PassthroughSubject<ViewRefreshKey, Never>()
	private static let singleton = AppState()
	static func get() -> AppState { singleton }
	
	@Bindable(send: .budgetStack, to: subject)
	var budgetStack: BudgetStack = BudgetStack()
	
	@Bindable(send: .budgetStack, to: subject)
	var dayViewListPosition: Int? = nil
	@Bindable(send: .budgetStack, to: subject)
	var dayViewUpdateTrigger = false
	@Bindable(send: .budgetStack, to: subject)
	var dayViewExpensePeriod: TimeInterval = 30 * minutes
	@Bindable(send: .budgetStack, to: subject)
	var dayViewPlusMinusDays: Int = 1
	@Bindable(send: .budgetStack, to: subject)
	var dayViewAction: DayViewAction = .add
	var dayViewPeriodsPerDay: Int {
		return Int(oneDay / dayViewExpensePeriod)
	}
	
	@Bindable(send: .budgetStack, to: subject)
	var fundListAction: FundAction = .view
	@Bindable(send: .budgetStack, to: subject)
	var fundListActionDetail: String = "No action selected"
	@Bindable(send: .budgetStack, to: subject)
	var lastSelectedFund: TimeFund? = nil
	
	@Bindable(send: .budgetStack, to: subject)
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
	
	@Bindable(send: .budgetStack, to: subject)
	var ratioDisplayMode: RatioDisplayMode = .percentage
}
