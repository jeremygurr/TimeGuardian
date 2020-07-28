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
	@State var startDate: Date
	@State var endDate: Date
	@State var timeSlots: [TimeSlot]

	init(calendarSettings: CalendarSettings) {
		let today = getStartOfDay()
		let plusMinus = calendarSettings.plusMinusDays
		let newStartDate = today - Double(plusMinus) * days
		let newEndDate = today + Double(plusMinus) * days
		_startDate = State(initialValue: newStartDate)
		_endDate = State(initialValue: newEndDate)
		_todaysExpenses = TimeExpense.fetchRequestFor(startDate: newStartDate, endDate: newEndDate)
		var newTimeSlots: [TimeSlot] = []
		for dayOffset in -plusMinus ... plusMinus {
			for timeSlot in 0 ..< calendarSettings.periodsPerDay {
				let baseDate = today + Double(dayOffset) * days
				newTimeSlots.append(TimeSlot(baseDate: baseDate, slotIndex: timeSlot, slotSize: calendarSettings.expensePeriod))
			}
		}
		_timeSlots = State(initialValue: newTimeSlots)
	}

	var body: some View {
		List {
			Text("").frame(height: listViewExtension)
			ExpenseRowView(todaysExpenses: self.todaysExpenses, timeSlots: $timeSlots)
			Text("").frame(height: listViewExtension)
		}
		.introspectTableView { tableView in
			tableView.scrollToRow(
				at: IndexPath(
					item: self.getCalendarOffsetForCurrentTime() + 1, section: 0)
				, at: .middle
				, animated: false
			)
		}
	}

	func getCalendarOffsetForCurrentTime() -> Int {
		var result: Int = 0
		for i in 0 ..< timeSlots.count {
			let slot = timeSlots[i]
			if slot.coversCurrentTime {
				result = i
				break
			}
		}
		return result
	}
	
}

struct ExpenseRowView: View {
	@EnvironmentObject var calendarSettings: CalendarSettings
	@EnvironmentObject var budgetStack: BudgetStack
	var todaysExpenses: FetchedResults<TimeExpense>
	@Environment(\.managedObjectContext) var managedObjectContext
	@Binding var timeSlots: [TimeSlot]

	var body: some View {
		ForEach(0 ..< self.timeSlots.count, id: \.self) { index in
			self.RowView(index)
		}
	}
	
	func RowView(_ index: Int) -> some View {
		let timeSlot = timeSlots[index]
		return HStack {
			VStack {
				Text("\(toDayString(timeSlot: timeSlot))")
				Text("\(toTimeString(timeSlot: timeSlot))")
			}
			Spacer()
			Text("\(toExpenseString(timeSlot: timeSlot, todaysExpenses: self.todaysExpenses))")
		}
		.padding()
		.contentShape(Rectangle())
		.background(colorOfRow(timeSlot: timeSlot, calendarSettings: self.calendarSettings))
		.onTapGesture {
			if let existingExpense = getExpenseFor(timeSlot: timeSlot, todaysExpenses: self.todaysExpenses) {
				self.removeExpense(existingExpense: existingExpense)
			} else {
				addExpense(timeSlot: timeSlot, budgetStack: self.budgetStack, managedObjectContext: self.managedObjectContext)
			}
		}
	}
	
	func removeExpense(existingExpense: TimeExpense) {
		debugLog("removeExpense: \(existingExpense)")
		existingExpense.fund.adjustBalance(1)
		var path = existingExpense.path.split(separator: newline)
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
}

func addExpense(timeSlot: TimeSlot, budgetStack: BudgetStack, managedObjectContext: NSManagedObjectContext) {
	if let fund = budgetStack.lastSelectedFund {
		addExpense(timeSlot: timeSlot, fund: fund, budgetStack: budgetStack, managedObjectContext: managedObjectContext)
		saveData(managedObjectContext)
	}
}

func getExpenseFor(timeSlot: TimeSlot, todaysExpenses: FetchedResults<TimeExpense>) -> TimeExpense? {
	var result: TimeExpense? = nil

	for expense in todaysExpenses {
		if expense.when == timeSlot.baseDate && expense.timeSlot == timeSlot.slotIndex {
			result = expense
		} else if
			expense.when > timeSlot.baseDate ||
				expense.when == timeSlot.baseDate &&
				expense.timeSlot > timeSlot.slotIndex {
			break
		}
	}
	return result
}

func toExpenseString(timeSlot: TimeSlot, todaysExpenses: FetchedResults<TimeExpense>) -> String {
	var result = ""
	if let existingExpense = getExpenseFor(timeSlot: timeSlot, todaysExpenses: todaysExpenses) {
		result = existingExpense.fund.name
	}
	return result
}

func colorOfRow(timeSlot: TimeSlot, calendarSettings: CalendarSettings) -> some View {
	if(timeSlot == getTimeSlotOfCurrentTime(calendarSettings: calendarSettings)) {
		return Color.init("HighlightBackground")
	}
	return Color.clear
}

func toTimeString(timeSlot: TimeSlot) -> String {
	let startOfDay = getStartOfDay()
	let interval = timeSlot.minutesFromBeginning * minutes
	let currentPeriod = startOfDay.advanced(by: interval)
	let timeFormat = DateFormatter()
	timeFormat.dateFormat = "HH:mm"
	let timeString = timeFormat.string(from: currentPeriod)
	//	debugLog("toTimeString -> \(timeString)")
	return timeString
}

func toDayString(timeSlot: TimeSlot) -> String {
	let startOfDay = timeSlot.baseDate
	let interval = timeSlot.minutesFromBeginning * minutes
	let currentPeriod = startOfDay.advanced(by: interval)
	let timeFormat = DateFormatter()
	timeFormat.dateFormat = "E"
	let timeString = timeFormat.string(from: currentPeriod)
//	debugLog("toTimeString -> \(timeString)")
	return timeString
}

struct CalendarView_Previews: PreviewProvider {
	static let calendarSettings = CalendarSettings()
	static var previews: some View {
		
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		let testDataBuilder = TestDataBuilder(context: context)
		testDataBuilder.createTestData()
		let budget = testDataBuilder.budgets.first!
		let budgetStack = BudgetStack()
		budgetStack.push(budget: budget)
		
		return Group {
			CalendarView(calendarSettings: calendarSettings)
				.environmentObject(calendarSettings)
				.environmentObject(budgetStack)
				.environment(\.colorScheme, .light)
				.environment(\.managedObjectContext, context)

			CalendarView(calendarSettings: calendarSettings)
				.environmentObject(calendarSettings)
				.environmentObject(budgetStack)
				.environment(\.colorScheme, .dark)
				.environment(\.managedObjectContext, context)
		}
	}
}

