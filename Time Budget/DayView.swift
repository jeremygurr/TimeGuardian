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
import Combine

struct DayView: View {
	@State var viewState = 0

	@Binding var budgetStack: BudgetStack
	@FetchRequest var recentExpenses: FetchedResults<TimeExpense>
	@Environment(\.managedObjectContext) var managedObjectContext
	@State var startDate: Date
	@State var endDate: Date
	@State var timeSlots: [TimeSlot]
	@Binding var currentPosition: Int?
	@Binding var action: DayViewAction
	@Binding var actionDetail: String

	init() {
		
		let appState = AppState.get()
		_action = appState.$dayViewAction
		_actionDetail = appState.$dayViewActionDetail
		let today = getStartOfDay()
		let plusMinus = appState.dayViewPlusMinusDays
		let newStartDate = today - Double(plusMinus) * days
		let newEndDate = today + Double(plusMinus) * days
		_startDate = State(initialValue: newStartDate)
		_endDate = State(initialValue: newEndDate)
		_recentExpenses = TimeExpense.fetchRequestFor(startDate: newStartDate, endDate: newEndDate)
		var newTimeSlots: [TimeSlot] = []
		
		for dayOffset in -plusMinus ... plusMinus {
			for timeSlot in 0 ..< appState.dayViewPeriodsPerDay {
				let baseDate = today + Double(dayOffset) * days
				newTimeSlots.append(TimeSlot(baseDate: baseDate, slotIndex: timeSlot, slotSize: appState.dayViewExpensePeriod))
			}
		}
		
		_timeSlots = State(initialValue: newTimeSlots)
		_currentPosition = appState.$dayViewListPosition
		_budgetStack = appState.$budgetStack
		
	}
	
	var body: some View {
		VStack {
			MultiRowSegmentedPickerView(
				actionDetail: self.$actionDetail,
				choices: DayViewAction.allCasesInRows,
				selectedIndex: self.$action,
				onChange: { _ in }
			)
			Text(actionDetail)
				.font(.body)
			List {
				Text("").frame(height: listViewExtension)
				ExpenseRowView(todaysExpenses: self.recentExpenses, timeSlots: $timeSlots)
					.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
				Text("").frame(height: listViewExtension)
			}
			.introspectTableView { tableView in
				tableView.scrollToRow(
					at: IndexPath(
						item: self.getCurrentPosition() + 1, section: 0)
					, at: .middle
					, animated: false
				)
			}
			.onReceive(
				AppState.subject
					.filter({ $0 == .dayView })
					.collect(.byTime(RunLoop.main, .milliseconds(stateChangeCollectionTime)))
			) { x in
				self.viewState += 1
				debugLog("DayView: view state changed to \(self.viewState) (\(x.count) events)")
			}
		}
	}
	
	func getCurrentPosition() -> Int {
		var result: Int
		if let c = self.currentPosition {
			result = c
		} else {
			let c = self.getCalendarOffsetForCurrentTime()
			self.currentPosition = c
			result = c
		}
		return result
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
	@Binding var budgetStack: BudgetStack
	var todaysExpenses: FetchedResults<TimeExpense>
	@Environment(\.managedObjectContext) var managedObjectContext
	@Binding var timeSlots: [TimeSlot]
	@Binding var currentPosition: Int?
	@Binding var dayViewExpensePeriod: TimeInterval
	@Binding var lastSelectedFund: TimeFund?
	@Binding var action: DayViewAction
	
	init(todaysExpenses: FetchedResults<TimeExpense>, timeSlots: Binding<[TimeSlot]>) {
		let appState = AppState.get()
		_currentPosition = appState.$dayViewListPosition
		self.todaysExpenses = todaysExpenses
		_timeSlots = timeSlots
		_budgetStack = appState.$budgetStack
		_dayViewExpensePeriod = appState.$dayViewExpensePeriod
		_lastSelectedFund = appState.$lastSelectedFund
		_action = appState.$dayViewAction
	}
	
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
			.padding(.leading, 10)
			Spacer()
			Text("\(toExpenseString(timeSlot: timeSlot, todaysExpenses: self.todaysExpenses))")
				.padding(.trailing, 10)
		}
		.contentShape(Rectangle())
		.background(colorOfRow(timeSlot: timeSlot, expensePeriod: dayViewExpensePeriod))
		.onTapGesture {
			self.currentPosition = index
			debugLog("DayView: expense row pressed")
			let existingExpense = getExpenseFor(timeSlot: timeSlot, todaysExpenses: self.todaysExpenses)
			switch self.action {
				case .add:
					debugLog("DayView: add action")
					if existingExpense == nil {
						addExpense(timeSlot: timeSlot, lastSelectedFund: self.lastSelectedFund, budgetStack: self.budgetStack, managedObjectContext: self.managedObjectContext)
					}
				case .remove:
					debugLog("DayView: remove action")
					if existingExpense != nil {
						self.removeExpense(existingExpense: existingExpense!)
				}
			}
		}
	}
	
	func removeExpense(existingExpense: TimeExpense) {
		debugLog("removeExpense: \(existingExpense)")
		existingExpense.fund.adjustBalance(1)
		var path = existingExpense.path.split(separator: newline)
		if path.count > 0 {
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
		}
		self.managedObjectContext.delete(existingExpense)
		saveData(self.managedObjectContext)
	}
}

func addExpense(timeSlot: TimeSlot, lastSelectedFund: TimeFund?, budgetStack: BudgetStack, managedObjectContext: NSManagedObjectContext) {
	if let fund = lastSelectedFund {
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

func colorOfRow(timeSlot: TimeSlot, expensePeriod: TimeInterval) -> some View {
	if(timeSlot == getTimeSlotOfCurrentTime(expensePeriod: expensePeriod)) {
		return Color.init("HighlightBackground")
	}
	return Color.clear
}

func toTimeString(timeSlot: TimeSlot) -> String {
	let startOfDay = getStartOfDay()
	let interval = timeSlot.secondsFromBeginning
	let currentPeriod = startOfDay.advanced(by: interval)
	let timeFormat = DateFormatter()
	timeFormat.dateFormat = "HH:mm"
	let timeString = timeFormat.string(from: currentPeriod)
	//	debugLog("toTimeString -> \(timeString)")
	return timeString
}

func toDayString(timeSlot: TimeSlot) -> String {
	let startOfDay = timeSlot.baseDate
	let interval = timeSlot.secondsFromBeginning
	let currentPeriod = startOfDay.advanced(by: interval)
	let timeFormat = DateFormatter()
	timeFormat.dateFormat = "E"
	let timeString = timeFormat.string(from: currentPeriod)
	//	debugLog("toTimeString -> \(timeString)")
	return timeString
}

struct CalendarView_Previews: PreviewProvider {
	static var previews: some View {
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		let testDataBuilder = TestDataBuilder(context: context)
		testDataBuilder.createTestData()
		let appState = AppState.get()
		let budget = testDataBuilder.budgets.first!
		appState.budgetStack.push(budget: budget)
		
		return Group {
			DayView()
				.environment(\.colorScheme, .light)
				.environment(\.managedObjectContext, context)
			
			DayView()
				.environment(\.colorScheme, .dark)
				.environment(\.managedObjectContext, context)
		}
		
	}
}


