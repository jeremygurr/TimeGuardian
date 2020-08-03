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

class AppState {
	init() {
		debugLog("AppState.init")
	}
	
	var budgetStack: State<BudgetStack> = State(initialValue: BudgetStack())
	
	@State var dayViewListPosition: Int? = nil
	@State var dayViewUpdateTrigger = false
	@State var dayViewExpensePeriod: TimeInterval = 30 * minutes
	@State var dayViewPlusMinusDays: Int = 1
	@State var dayViewAction: DayViewAction = .add
	var dayViewPeriodsPerDay: Int {
		return Int(oneDay / dayViewExpensePeriod)
	}

	@State var fundListAction: FundAction = .view
	@State var fundListActionDetail: String = "No action selected"
	@State var lastSelectedFund: TimeFund? = nil

	@State var titleOverride: String? = nil

	var title: String {
		var title: String
		if titleOverride != nil {
			title = titleOverride!
		} else {
			if budgetStack.wrappedValue.hasTopBudget() {
				title = budgetStack.wrappedValue.getTopBudget().name
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
	
	@State var ratioDisplayMode: RatioDisplayMode = .percentage
}
