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
	
	func migrateData() {
		let dataVersion = settings.dataVersion
		if dataVersion < 1 {
			debugLog("Older dataVersion found: \(dataVersion), migrating data to version 1")
			do {
				let request: NSFetchRequest<TimeExpense> = TimeExpense.fetchRequest()
				let expenses = try managedObjectContext.fetch(request)
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
				settings.dataVersion = 1
				saveData()
			} catch {
				errorLog("Error migrating data: \(error)")
			}
		}
	}
	
	static let subject = PassthroughSubject<ViewRefreshKey, Never>()
	
	@Bindable(send: [.fundList, .dayView], to: subject)
	var settings = WrappedSettings()
	
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
	
	//	@Bindable(send: .dayView, to: subject)
	//	var dayViewExpensePeriod: TimeInterval = 30 * minutes
	//
	@Bindable(send: [.dayView], to: subject)
	var dayViewPlusMinusDays: Int = 1
	
	@Bindable(send: [.dayView], to: subject)
	var dayViewAction: DayViewAction = .add
	
	@Bindable(send: [.dayView], to: subject, beforeSet: {
		(beforeValue, afterValue) in
		debugLog("Bindable: dayViewActionDetail changed from " + beforeValue + "  to " + afterValue)
	})
	var dayViewActionDetail: String = "No action selected"
	
	var dayViewPeriodsPerDay: Int {
		let result = Int(oneDay / settings.shortPeriod)
		debugLog("AppState.dayViewPeriodsPerDay = \(result)")
		return result
	}
	
	@Bindable(send: [.dayView], to: subject)
	var dayViewTimeSlotOfCurrentTime: TimeSlot = TimeSlot(baseDate: Date(), slotIndex: 0, slotSize: 30 * minutes)
	
	@Bindable(send: [.fundList], to: subject)
	var fundListAction: FundAction = .view
	
	@Bindable(send: [.fundList], to: subject)
	var fundListActionDetail: String = "No action selected"
	
	//	@Bindable(send: .fundList, to: subject)
	//	var balanceDisplayMode: BalanceDisplayMode = .unit
	//
	//	@Bindable(send: .fundList, to: subject)
	//	var ratioDisplayMode: RatioDisplayMode = .percentage
	//
	@Bindable(send: [.dayView], to: subject, beforeSet: {
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
	
	@Bindable(send: [.topView], to: subject)
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

struct WrappedSettings: Equatable {
	static func == (lhs: WrappedSettings, rhs: WrappedSettings) -> Bool {
		lhs.shortPeriod == rhs.shortPeriod
			&& lhs.longPeriod == rhs.longPeriod
			&& lhs.balanceDisplayMode == rhs.balanceDisplayMode
			&& lhs.ratioDisplayMode == rhs.ratioDisplayMode
	}
	
	@Binding var shortPeriod: TimeInterval
	@Binding var longPeriod: TimeInterval
	@Binding var balanceDisplayMode: BalanceDisplayMode
	@Binding var ratioDisplayMode: RatioDisplayMode
	@Binding var dataVersion: Int16
	
	init() {
		
		do {
			let settings: Settings
			let request: NSFetchRequest<Settings> = Settings.fetchRequest()
			let settingsArray = try managedObjectContext.fetch(request)
			if let s = settingsArray.first {
				settings = s
			} else {
				settings = Settings(context: managedObjectContext)
			}
			
			_shortPeriod = Binding(
				get: {
					debugLog("AppState WrappedSettings get shortPeriod = \(settings.shortPeriod)")
					return settings.shortPeriod
			}, set: {
				debugLog("AppState WrappedSettings setting shortPeriod to \($0)")
				settings.shortPeriod = $0
				debugLog("AppState WrappedSettings shortPeriod is now \(settings.shortPeriod)")
			}
			)
			
			_longPeriod = Binding(
				get: {
					settings.longPeriod
			}, set: {
				settings.longPeriod = $0
			}
			)
			
			_balanceDisplayMode = Binding(
				get: {
					BalanceDisplayMode(rawValue: Int(settings.balanceDisplayMode)) ?? .unit
			}, set: {
				settings.balanceDisplayMode = Int16($0.rawValue)
			}
			)
			
			_ratioDisplayMode = Binding(
				get: {
					RatioDisplayMode(rawValue: Int(settings.ratioDisplayMode)) ?? .percentage
			}, set: {
				settings.ratioDisplayMode = Int16($0.rawValue)
			}
			)
			
			_dataVersion = Binding(
				get: {
					settings.dataVersion
			}, set: {
				settings.dataVersion = $0
			}
			)
			
		} catch {
			errorLog("Error fetching settings: \(error)")

			_shortPeriod = Binding<TimeInterval>(get: { return 0 }, set: { _ in })
			_longPeriod = Binding<TimeInterval>(get: { return 0 }, set: { _ in })
			_balanceDisplayMode = Binding<BalanceDisplayMode>(get: { return .unit }, set: { _ in })
			_ratioDisplayMode = Binding<RatioDisplayMode>(get: { return .percentage }, set: { _ in })
			_dataVersion = Binding<Int16>(get: { return 0 }, set: { _ in })
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



