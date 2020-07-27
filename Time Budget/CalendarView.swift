//
//  CalendarView.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 7/26/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI
import Introspect

struct CalendarView: View {
	@EnvironmentObject var calendarSettings: CalendarSettings
	@EnvironmentObject var budgetStack: BudgetStack
	@FetchRequest var todaysExpenses: FetchedResults<TimeExpense>
	@Environment(\.managedObjectContext) var managedObjectContext

	init() {
		_todaysExpenses = TimeExpense.fetchRequestFor(date: Date())
	}

	func toTimeString(_ period: Int) -> String {
		let startOfDay = getStartOfDay()
		let interval = TimeInterval(period * calendarSettings.expensePeriod * 60)
		let currentPeriod = startOfDay.advanced(by: interval)
		let timeFormat = DateFormatter()
		timeFormat.dateFormat = "HH:mm"
		let timeString = timeFormat.string(from: currentPeriod)
		return timeString
	}
	
	func getItemIndexOfCurrentTime() -> Int {
		let now = Date()
		let startOfDay = getStartOfDay()
		let difference = Int(startOfDay.distance(to: now))
		let itemIndex = difference / 60 / calendarSettings.expensePeriod
		return itemIndex
	}
	
	func colorOfRow(_ row: Int) -> some View {
		if(row == getItemIndexOfCurrentTime()) {
			return Color.init("HighlightBackground")
		}
		return Color.white
	}
	
	func getExpenseFor(_ period: Int) -> TimeExpense? {
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
	
	func toExpenseString(_ period: Int) -> String {
		var result = ""
		if let existingExpense = self.getExpenseFor(period) {
			result = existingExpense.fund.name
		}
		return result
	}
	
	var body: some View {
		List {
			ForEach(0 ..< 10) { _ in
				Text("")
			}
			ForEach(0 ..< calendarSettings.periodsPerDay) { period in
				HStack {
					Text("\(self.toTimeString(period))")
					Spacer()
					Text("\(self.toExpenseString(period))")
				}
				.padding()
				.contentShape(Rectangle())
				.background(self.colorOfRow(period))
				.onTapGesture {
					if let existingExpense = self.getExpenseFor(period) {
						self.managedObjectContext.delete(existingExpense)
						saveData(self.managedObjectContext)
					} else {
						if let fund = self.budgetStack.lastSelectedFund {
							let expense = TimeExpense(context: self.managedObjectContext)
							expense.fund = fund
							expense.timeSlot = Int16(period)
							var pathString = ""
							let space : Character = " "
							for f in self.budgetStack.getFunds() {
								if pathString.count > 0 {
									pathString.append(space)
								}
								pathString.append(contentsOf: "\(f.id)")
							}
							expense.path = pathString
							expense.when = getStartOfDay()
							saveData(self.managedObjectContext)
						}
					}
				}
			}
			ForEach(0 ..< 10) { _ in
				Text("")
			}
		}.introspectTableView { tableView in
			tableView.scrollToRow(at: IndexPath(item: self.getItemIndexOfCurrentTime() + 10, section: 0), at: .middle, animated: false)
		}
	}
}

struct CalendarView_Previews: PreviewProvider {
	static let calendarSettings = CalendarSettings()
	static var previews: some View {
		CalendarView()
			.environmentObject(calendarSettings)
	}
}
