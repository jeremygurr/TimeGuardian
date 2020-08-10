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
	@Binding var action: DayViewAction
	@Binding var actionDetail: String
	@Binding var recentFunds: [FundPath]
	
	@State private var tableView: UITableView?

	init() {
		
		debugLog("DayView.init")
		
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
		_budgetStack = appState.$budgetStack
		_recentFunds = appState.$lastSelectedFundPaths
		
	}
	
	func fundRowView(_ i: Int) -> some View {
		let fundPath = recentFunds[i]
		if let fund = fundPath.last {
			return
				Text("\(fund.name)")
		} else {
			return Text("")
		}
	}
	
	var body: some View {
		VStack {
			List {
				Section(header: Text("Recently Selected Funds")) {
					ForEach(recentFunds.indices) { i in
						self.fundRowView(i)
					}
				}
			}
			List {
				Section(header: Text("Time Slots")) {
				ExpenseRowView(tableView: self.$tableView, todaysExpenses: self.recentExpenses, timeSlots: $timeSlots)
					.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
				}
			}
			.introspectTableView { tableView in
				if self.tableView != tableView {
					self.tableView = tableView
				}

				if AppState.get().dayViewResetListPosition {
					debugLog("DayView: resetting list position")
					tableView.scrollToRow(
						at: IndexPath(
							item: self.getCalendarOffsetForCurrentTime() + 1, section: 0)
						, at: .middle
						, animated: false
					)
					AppState.get().dayViewPosition = tableView.contentOffset
					AppState.get().dayViewResetListPosition = false
				} else {
					tableView.setContentOffset(AppState.get().dayViewPosition, animated: false)
					debugLog("DayView: list position updated to \(tableView.contentOffset)")
				}
			}
		}.onAppear {
			debugLog("DayView appeared")
		}.onDisappear {
			debugLog("DayView disappeared")
			if let t = self.tableView {
				AppState.get().dayViewPosition = t.contentOffset
				debugLog("AppState dayViewPosition updated to \(t.contentOffset)")
			}
		}.onReceive(
			AppState.subject
				.filter({ $0 == .dayView })
				.collect(
					.byTime(
						RunLoop.main, .milliseconds(stateChangeCollectionTime)
					)
			)
		) { x in
			if let t = self.tableView {
				AppState.get().dayViewPosition = t.contentOffset
				debugLog("AppState dayViewPosition updated to \(t.contentOffset)")
			}
			
			self.viewState += 1
			debugLog("DayView: view state changed to \(self.viewState) (\(x.count) events)")
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
	@Binding private var tableView: UITableView?
	@Binding var budgetStack: BudgetStack
	var todaysExpenses: FetchedResults<TimeExpense>
	@Environment(\.managedObjectContext) var managedObjectContext
	@Binding var timeSlots: [TimeSlot]
	@Binding var dayViewExpensePeriod: TimeInterval
	@Binding var lastSelectedFundPaths: [FundPath]
	@Binding var action: DayViewAction
	
	init(tableView: Binding<UITableView?>, todaysExpenses: FetchedResults<TimeExpense>, timeSlots: Binding<[TimeSlot]>) {
		debugLog("ExpenseRowView.init")
		_tableView = tableView
		let appState = AppState.get()
		self.todaysExpenses = todaysExpenses
		_timeSlots = timeSlots
		_budgetStack = appState.$budgetStack
		_dayViewExpensePeriod = appState.$dayViewExpensePeriod
		_lastSelectedFundPaths = appState.$lastSelectedFundPaths
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
			debugLog("DayView: expense row pressed")
			let existingExpense = getExpenseFor(timeSlot: timeSlot, todaysExpenses: self.todaysExpenses)
			
			if let t = self.tableView {
				AppState.get().dayViewPosition = t.contentOffset
				debugLog("AppState dayViewPosition updated to \(t.contentOffset)")
			}

//			switch self.action {
//				case .add:
//					debugLog("DayView: add action")
//					if existingExpense == nil {
//						addExpense(timeSlot: timeSlot, lastSelectedFund: self.lastSelectedFund, budgetStack: self.budgetStack, managedObjectContext: self.managedObjectContext)
//					}
//				case .remove:
//					debugLog("DayView: remove action")
//					if existingExpense != nil {
//						self.lastSelectedFund = existingExpense!.fund
//						self.removeExpense(existingExpense: existingExpense!)
//				}
//				case .toggle:
					debugLog("DayView: toggle action")
					if existingExpense != nil {
						AppState.get().push(fundPath: existingExpense!.fundPath)
						self.removeExpense(existingExpense: existingExpense!)
					} else {
						if let lastFundPath = self.lastSelectedFundPaths.last {
							addExpense(timeSlot: timeSlot, fundPath: lastFundPath, managedObjectContext: self.managedObjectContext)
						}
				}
//			}
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

func addExpense(timeSlot: TimeSlot, fundPath: FundPath?, budgetStack: BudgetStack, managedObjectContext: NSManagedObjectContext) {
	if fundPath != nil {
		addExpense(timeSlot: timeSlot, fundPath: fundPath!, budgetStack: budgetStack, managedObjectContext: managedObjectContext)
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


