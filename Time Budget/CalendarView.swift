//
//  CalendarView.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 7/26/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI
import CoreData
import Introspect

struct CalendarView: View {
	@EnvironmentObject var calendarSettings: CalendarSettings
	@EnvironmentObject var budgetStack: BudgetStack
	@FetchRequest var todaysExpenses: FetchedResults<TimeExpense>
	@Environment(\.managedObjectContext) var managedObjectContext

	init() {
		_todaysExpenses = TimeExpense.fetchRequestFor(date: Date())
	}

	var body: some View {
		List {
			ForEach(0 ..< 10) { _ in
				Text("")
			}
			ExpenseRowView(todaysExpenses: self.todaysExpenses)
			ForEach(0 ..< 10) { _ in
				Text("")
			}
		}.introspectTableView { tableView in
			tableView.scrollToRow(
				at: IndexPath(
					item: getItemIndexOfCurrentTime(calendarSettings: self.calendarSettings) + 10, section: 0)
				, at: .middle
				, animated: false
			)
		}
	}
}

struct ExpenseRowView: View {
	@EnvironmentObject var calendarSettings: CalendarSettings
	@EnvironmentObject var budgetStack: BudgetStack
	var todaysExpenses: FetchedResults<TimeExpense>
	@Environment(\.managedObjectContext) var managedObjectContext

	var body: some View {
		ForEach(0 ..< calendarSettings.periodsPerDay, id: \.self) { period in
			HStack {
				Text("\(toTimeString(period, calendarSettings: self.calendarSettings))")
				Spacer()
				Text("\(toExpenseString(period, todaysExpenses: self.todaysExpenses))")
			}
			.padding()
			.contentShape(Rectangle())
			.background(colorOfRow(period, calendarSettings: self.calendarSettings))
			.onTapGesture {
				if let existingExpense = getExpenseFor(period, todaysExpenses: self.todaysExpenses) {
					self.removeExpense(existingExpense: existingExpense)
				} else {
					self.addExpense(period: period)
				}
			}
		}
	}
	
	func removeExpense(existingExpense: TimeExpense) {
		existingExpense.fund.adjustBalance(1)
		var path = existingExpense.path.split(separator: space)
		path.reverse()
		for i in 0 ..< path.count - 1 {
			
			let fundName = String(path[i])
			let budgetName = String(path[i+1])
			
			let request = TimeFund.fetchRequest(budgetName: budgetName, fundName: fundName)
			
			do {
				let funds = try self.managedObjectContext.fetch(request)
				if let fund = funds.first {
					fund.adjustBalance(1)
				} else {
					errorLog("Missing fund: budgetName = \(budgetName), fundName = \(fundName)")
				}
			} catch {
				errorLog("Error fetching fund: budgetName = \(budgetName), fundName = \(fundName), \(error)")
			}
			
		}
		self.managedObjectContext.delete(existingExpense)
		saveData(self.managedObjectContext)
	}
	
	func addExpense(period: Int) {
		if let fund = self.budgetStack.lastSelectedFund {
			let expense = TimeExpense(context: self.managedObjectContext)
			expense.fund = fund
			expense.timeSlot = Int16(period)
			var pathString = ""
			for b in self.budgetStack.getBudgets() {
				if pathString.count > 0 {
					pathString.append(space)
				}
				pathString.append(contentsOf: "\(b.name)")
			}
			expense.path = pathString
			debugLog("Recorded path = '\(pathString)'")
			expense.when = getStartOfDay()
			fund.deepSpend(budgetStack: self.budgetStack)
			saveData(self.managedObjectContext)
		}
	}
}

func getExpenseFor(_ period: Int, todaysExpenses: FetchedResults<TimeExpense>) -> TimeExpense? {
	var result: TimeExpense? = nil

	for expense in todaysExpenses {
		if expense.timeSlot == period {
			result = expense
		} else if expense.timeSlot > period {
			break
		}
	}
	return result
}

func toExpenseString(_ period: Int, todaysExpenses: FetchedResults<TimeExpense>) -> String {
	var result = ""
	if let existingExpense = getExpenseFor(period, todaysExpenses: todaysExpenses) {
		result = existingExpense.fund.name
	}
	return result
}

func colorOfRow(_ row: Int, calendarSettings: CalendarSettings) -> some View {
	if(row == getItemIndexOfCurrentTime(calendarSettings: calendarSettings)) {
		return Color.init("HighlightBackground")
	}
	return Color.white
}

func toTimeString(_ period: Int, calendarSettings: CalendarSettings) -> String {
	let startOfDay = getStartOfDay()
	let interval = TimeInterval(period * calendarSettings.expensePeriod * 60)
	let currentPeriod = startOfDay.advanced(by: interval)
	let timeFormat = DateFormatter()
	timeFormat.dateFormat = "HH:mm"
	let timeString = timeFormat.string(from: currentPeriod)
	return timeString
}

func getItemIndexOfCurrentTime(calendarSettings: CalendarSettings) -> Int {
	let now = Date()
	let startOfDay = getStartOfDay()
	let difference = Int(startOfDay.distance(to: now))
	let itemIndex = difference / 60 / calendarSettings.expensePeriod
	return itemIndex
}

struct CalendarView_Previews: PreviewProvider {
	static let calendarSettings = CalendarSettings()
	static var previews: some View {
		CalendarView()
			.environmentObject(calendarSettings)
	}
}

let space : Character = " "
