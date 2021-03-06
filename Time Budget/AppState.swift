//
//  Config.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 7/22/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import CoreData
import SwiftUI
import Combine

let longPressDuration = 0.25
let longPressMaxDrift: CGFloat = 0.1
let listViewExtension: CGFloat = 200
let stateChangeCollectionTime: Int = 10

var appState = AppState()

enum ViewRefreshKey {
	case topView, fundList, dayView
}

class AppState {
	
	init() {
		debugLog("AppState.init")
	}
	
	func postInit() {
		migrateData()
		loadSettings()
		updateTimeSlots()
	}
	
	func migrateData() {
		let dataVersion = AppState.settings.dataVersion
		if dataVersion < 1 {
			debugLog("Older dataVersion found: \(dataVersion), migrating data to version 1")
			do {
				let request: NSFetchRequest<TimeExpense> = TimeExpense.fetchRequest()
				let expenses = try managedObjectContext.fetch(request)
				debugLog("Found \(expenses.count) expenses to migrate")
				for expense in expenses {
					if let fund = expense.fund {
						var pathString = expense.path
						pathString.append(newline)
						pathString.append(fund.name)
						expense.path = pathString
						expense.fund = nil
						
						var when = expense.when
						when.addTimeInterval(Double(expense.timeSlot) * 30 * minutes)
						expense.when = when
						expense.timeSlot = -1
					}
				}
				AppState.settings.dataVersion = 1
				saveData()
			} catch {
				errorLog("Error migrating data: \(error)")
			}
		}
	}
	
	func loadSettings() {
		shortPeriod = AppState.settings.shortPeriod
		longPeriod = AppState.settings.longPeriod
		balanceDisplayMode = BalanceDisplayMode(rawValue: Int(AppState.settings.balanceDisplayMode)) ?? .unit
		ratioDisplayMode = RatioDisplayMode(rawValue: Int(AppState.settings.ratioDisplayMode)) ?? .percentage
	}
	
	static let subject = PassthroughSubject<ViewRefreshKey, Never>()
	
	static private var settings = Settings.fetch(context: managedObjectContext)
	
	@Bindable(send: [.fundList, .dayView], to: subject, beforeSet: {
		(beforeValue, afterValue) in
		if beforeValue != afterValue {
			settings.shortPeriod = afterValue
		}
	}, afterSet: {
		(beforeValue, afterValue) in
		if beforeValue != afterValue {
			appState.updateTimeSlots()
		}
	})
	var shortPeriod: TimeInterval = 30 * minutes
	
	@Bindable(send: [.fundList], to: subject, beforeSet: {
		(beforeValue, afterValue) in
		if beforeValue != afterValue {
			settings.longPeriod = afterValue
		}
	})
	var longPeriod: TimeInterval = oneDay
	
	@Bindable(send: [.fundList], to: subject, beforeSet: {
		(beforeValue, afterValue) in
		if beforeValue != afterValue {
			settings.balanceDisplayMode = Int16(afterValue.rawValue)
		}
	})
	var balanceDisplayMode: BalanceDisplayMode = .unit
	
	@Bindable(send: [.fundList], to: subject, beforeSet: {
		(beforeValue, afterValue) in
		if beforeValue != afterValue {
			settings.ratioDisplayMode = Int16(afterValue.rawValue)
		}
	})
	var ratioDisplayMode: RatioDisplayMode = .percentage
	
	@Bindable(send: [.topView], to: subject, beforeSet: {
		(beforeValue, afterValue) in
		if beforeValue == afterValue {
			if afterValue == .day {
				appState.dayViewResetListPosition = true
			} else if afterValue == .fund {
				appState.titleOverride = nil
				//				editMode?.wrappedValue = .inactive
				managedObjectContext.rollback()
				appState.budgetStack.toFirstBudget()
			}
		}
	})
	var mainTabSelection = MainTabSelection.fund
	
	@Bindable(send: [.topView, .fundList], to: subject)
	var budgetStack: BudgetStack = BudgetStack()
	
	@Bindable(send: [.dayView], to: subject)
	var dayViewResetListPosition: Bool = true
	
	@Bindable(send: [false])
	var dayViewPosition: CGPoint = CGPoint(x: 0, y: 0)
	
	@Bindable(send: [.dayView], to: subject)
	var dayViewPlusMinusDays: Int = 1
	
	@Bindable(send: [.dayView], to: subject)
	var dayViewAction: DayViewAction = .add
	
	@Bindable(send: [.dayView], to: subject)
	var dayViewActionDetail: String = "No action selected"

	@Bindable(send: [.dayView], to: subject)
	var dayViewTimeSlots: [TimeSlot] = []
	
	func updateTimeSlots() {
		
		var newTimeSlots: [TimeSlot] = []
		let today = getStartOfDay()
		let plusMinus = appState.dayViewPlusMinusDays
		
		for dayOffset in -plusMinus ... plusMinus {
			for timeSlot in 0 ..< dayViewPeriodsPerDay() {
				let baseDate = today + Double(dayOffset) * days
				newTimeSlots.append(TimeSlot(baseDate: baseDate, slotIndex: timeSlot, slotSize: appState.shortPeriod))
			}
		}
		
		if !arrayEquals(appState.dayViewTimeSlots, newTimeSlots) {
			appState.dayViewTimeSlots = newTimeSlots
			dayViewResetListPosition = true
		}
		
		let currentTimeSlot = getTimeSlotOfCurrentTime()
		if currentTimeSlot != appState.dayViewTimeSlotOfCurrentTime {
			appState.dayViewTimeSlotOfCurrentTime = currentTimeSlot
		}

	}
	
	@Bindable(send: [.dayView], to: subject)
	var dayViewTimeSlotOfCurrentTime: TimeSlot = TimeSlot(baseDate: Date(), slotIndex: 0, slotSize: 30 * minutes)
	
	@Bindable(send: [.fundList], to: subject)
	var fundListAction: FundAction = .view
	
	@Bindable(send: [.fundList], to: subject)
	var fundListActionDetail: String = "No action selected"
	
	@Bindable(send: [.dayView], to: subject)
	var lastSelectedFundPaths: [FundPath] = []
	
	func push(fundPath: FundPath) {
		var newFundPaths = lastSelectedFundPaths
		newFundPaths.removeAll(where: { $0 == fundPath })
		while newFundPaths.count > 2 {
			newFundPaths.removeFirst()
		}
		newFundPaths.append(fundPath)
		lastSelectedFundPaths = newFundPaths
	}
	
	@Bindable(send: [false])
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
	
	//	private let updateTimer: Timer = Timer(timeInterval: 5 * minutes, repeats: true, block: { _ in
	//		subject.send(.dayView)
	//	})
	
}

enum BalanceDisplayMode: Int, CaseIterable {
	case unit = 0, time
}

enum RatioDisplayMode: Int, CaseIterable {
	case percentage = 0, timePerDay, rechargeAmount
}



