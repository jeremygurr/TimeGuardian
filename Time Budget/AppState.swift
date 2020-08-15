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

enum ViewRefreshKey {
	case topView, budgetStack, fundList, dayView
}

class AppState {
	private init() {
		debugLog("AppState.init")
	}
	
	// must be run after managedObjectContext is set
	func loadSettings() {
		if let context = managedObjectContext {
			do {
				let request: NSFetchRequest<Settings> = Settings.fetchRequest()
				let settingsArray = try context.fetch(request)
				let settings: Settings
				if let s = settingsArray.first {
					settings = s
				} else {
					settings = Settings(context: context)
				}
				updateSettings(settings)
			} catch {
				errorLog("Error fetching settings: \(error)")
			}
		}
	}
	
	func migrateData() {
		let dataVersion = settings?.dataVersion ?? 0
		if dataVersion < 1 {
			debugLog("Older dataVersion found: \(dataVersion), migrating data to version 1")
			if let context = managedObjectContext {
				do {
					let request: NSFetchRequest<TimeExpense> = TimeExpense.fetchRequest()
					let expenses = try context.fetch(request)
					debugLog("Found \(expenses.count) expenses to migrate")
					for expense in expenses {
						if let fund = expense.fund {
							debugLog("Expense needs to be migrated: \(expense.description)")
							var pathString = expense.path
							pathString.append(newline)
							pathString.append(fund.name)
							expense.path = pathString
							expense.fund = nil
							
							var when = expense.when
							when.addTimeInterval(Double(expense.timeSlot) * 30 * minutes)
							expense.when = when
							expense.timeSlot = -1
							debugLog("New expense: \(expense.description)")
						}
					}
					settings?.dataVersion = 1
					saveData(context)
				} catch {
					errorLog("Error migrating data: \(error)")
				}
			} else {
				debugLog("No managedObjectContext, so migration can't be performed")
			}
		}
	}
	
	func updateSettings(_ settings: Settings) {
		if settings != self.settings {
			self.settings = settings
			
			let newFundListSettings = FundListSettings(settings)
			if newFundListSettings != fundListSettings {
				fundListSettings = newFundListSettings
			}
			
			let newDayViewSettings = DayViewSettings(settings)
			if newDayViewSettings != dayViewSettings {
				dayViewSettings = newDayViewSettings
			}
		}
	}
	
	static let subject = PassthroughSubject<ViewRefreshKey, Never>()
	private static let singleton = AppState()
	static func get() -> AppState { singleton }
	
	var managedObjectContext: NSManagedObjectContext? = nil
	
	private var settings: Settings? = nil
	
	@Bindable(send: .fundList, to: subject)
	var fundListSettings = FundListSettings()
	
	@Bindable(send: .dayView, to: subject)
	var dayViewSettings = DayViewSettings()
	
	@Bindable(send: .topView, to: subject, beforeSet: {
		(beforeValue, afterValue) in
		if beforeValue == afterValue {
			if afterValue == .day {
				AppState.get().dayViewResetListPosition = true
			} else if afterValue == .fund {
				AppState.get().titleOverride = nil
				//				editMode?.wrappedValue = .inactive
				if let context = AppState.get().managedObjectContext {
					context.rollback()
				}
				AppState.get().budgetStack.toFirstBudget()
			}
		}
	})
	var mainTabSelection = MainTabSelection.fund
	
	@Bindable(send: .budgetStack, to: subject)
	var budgetStack: BudgetStack = BudgetStack()
	
	@Bindable(send: .dayView, to: subject)
	var dayViewResetListPosition: Bool = true
	
	@Bindable(send: false)
	var dayViewPosition: CGPoint = CGPoint(x: 0, y: 0)
	
	//	@Bindable(send: .dayView, to: subject)
	//	var dayViewExpensePeriod: TimeInterval = 30 * minutes
	//
	@Bindable(send: .dayView, to: subject)
	var dayViewPlusMinusDays: Int = 1
	
	@Bindable(send: .dayView, to: subject)
	var dayViewAction: DayViewAction = .add
	
	@Bindable(send: .dayView, to: subject, beforeSet: {
		(beforeValue, afterValue) in
		debugLog("Bindable: dayViewActionDetail changed from " + beforeValue + "  to " + afterValue)
	})
	var dayViewActionDetail: String = "No action selected"
	
	var dayViewPeriodsPerDay: Int {
		return Int(oneDay / dayViewSettings.shortPeriod)
	}
	
	@Bindable(send: .dayView, to: subject)
	var dayViewTimeSlotOfCurrentTime: TimeSlot = TimeSlot(baseDate: Date(), slotIndex: 0, slotSize: 30 * minutes)
	
	@Bindable(send: .fundList, to: subject)
	var fundListAction: FundAction = .view
	
	@Bindable(send: .fundList, to: subject)
	var fundListActionDetail: String = "No action selected"
	
	//	@Bindable(send: .fundList, to: subject)
	//	var balanceDisplayMode: BalanceDisplayMode = .unit
	//
	//	@Bindable(send: .fundList, to: subject)
	//	var ratioDisplayMode: RatioDisplayMode = .percentage
	//
	@Bindable(send: .dayView, to: subject, beforeSet: {
		(beforeValue: [FundPath], afterValue: [FundPath]) in
		let beforeLastPath: FundPath? = beforeValue.last
		let afterLastPath: FundPath? = afterValue.last
		let beforeName: String? = beforeLastPath?.last?.name
		let afterName: String? = afterLastPath?.last?.name
		let b = beforeName ?? "nil"
		let a = afterName ?? "nil"
		let out = "Bindable: lastSelectedFundPaths.last changed from \(b) to \(a)"
		debugLog(out)
	})
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
	
	//	private let updateTimer: Timer = Timer(timeInterval: 5 * minutes, repeats: true, block: { _ in
	//		subject.send(.dayView)
	//	})
	
}

struct FundListSettings: Equatable {
	
	init(_ g: Settings) {
		_shortPeriod = g.shortPeriod
		_longPeriod = g.longPeriod
		_balanceDisplayMode = BalanceDisplayMode(rawValue: Int(g.balanceDisplayMode)) ?? .unit
		_ratioDisplayMode = RatioDisplayMode(rawValue: Int(g.ratioDisplayMode)) ?? .percentage
		settings = g
		debugLog("AppState: New FundListSettings created with ratioDisplayMode = \(_ratioDisplayMode)")
	}
	
	init() {
		_shortPeriod = 30 * minutes
		_longPeriod = oneDay
		_balanceDisplayMode = .unit
		_ratioDisplayMode = .percentage
		debugLog("AppState: New FundListSettings created with ratioDisplayMode = \(_ratioDisplayMode)")
		settings = nil
	}
	
	let settings: Settings?
	
	var _shortPeriod: TimeInterval
	var _longPeriod: TimeInterval
	var _balanceDisplayMode: BalanceDisplayMode
	var _ratioDisplayMode: RatioDisplayMode
	
	var shortPeriod: TimeInterval {
		get { _shortPeriod }
		
		set {
			_shortPeriod = newValue
			settings?.shortPeriod = newValue
		}
	}
	
	var longPeriod: TimeInterval {
		get { _longPeriod }
		
		set {
			_longPeriod = newValue
			settings?.longPeriod = newValue
		}
	}
	
	var balanceDisplayMode: BalanceDisplayMode {
		get { _balanceDisplayMode }
		
		set {
			_balanceDisplayMode = newValue
			settings?.balanceDisplayMode = Int16(newValue.rawValue)
		}
	}
	
	var ratioDisplayMode: RatioDisplayMode {
		get { _ratioDisplayMode }
		
		set {
			_ratioDisplayMode = newValue
			settings?.ratioDisplayMode = Int16(newValue.rawValue)
			debugLog("AppState: Updated ratioDisplayMode to \(newValue)")
		}
	}
	
}

struct DayViewSettings: Equatable {
	
	init(_ g: Settings) {
		_shortPeriod = g.shortPeriod
		settings = g
	}
	
	init() {
		_shortPeriod = 30 * minutes
		settings = nil
	}
	
	let settings: Settings?
	
	var _shortPeriod: TimeInterval
	
	var shortPeriod: TimeInterval {
		get { _shortPeriod }
		
		set {
			_shortPeriod = newValue
			settings?.shortPeriod = newValue
		}
	}
	
}

enum BalanceDisplayMode: Int, CaseIterable {
	case unit = 0, time
}

enum RatioDisplayMode: Int, CaseIterable {
	case percentage = 0, timePerDay, rechargeAmount
}

