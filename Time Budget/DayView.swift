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
	@State var startDate: Date
	@State var endDate: Date
	@State var timeSlots: [TimeSlot]
	@Binding var action: DayViewAction
	@Binding var actionDetail: String
	@Binding var recentFunds: [FundPath]
	@Binding var timeSlotOfCurrentTime: TimeSlot
	
	@State private var tableView: UITableView?
	
	init() {
		
		debugLog("DayView.init")
		
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
		
		debugLog("DayView.init: Generating \(dayViewPeriodsPerDay()) time slots for each day")
		
		for dayOffset in -plusMinus ... plusMinus {
			for timeSlot in 0 ..< dayViewPeriodsPerDay() {
				let baseDate = today + Double(dayOffset) * days
				newTimeSlots.append(
					TimeSlot(
						baseDate: baseDate,
						slotIndex: timeSlot,
						slotSize: appState.shortPeriod
					)
				)
			}
		}
		
		_timeSlots = State(initialValue: newTimeSlots)
		_budgetStack = appState.$budgetStack
		_recentFunds = appState.$lastSelectedFundPaths
		
		_timeSlotOfCurrentTime = appState.$dayViewTimeSlotOfCurrentTime
		
	}
	
	var body: some View {
		VStack(alignment: .leading) {
			Text("Recently Selected Funds")
				.font(.headline)
				.padding(.vertical, 3)
				.padding(.leading, 15)
				
				.frame(maxWidth: .infinity, alignment: .leading)
				.background(Color(UIColor.secondarySystemFill))
			if recentFunds.count > 0 {
				ForEach(recentFunds.indices, id: \.self) { i in
					RecentFundViewRow(recentFunds: self.recentFunds, index: i)
				}
				.offset(x: 0, y: 8)
			} else {
				Text("No funds have been selected")
					.font(.body)
					.padding(.vertical, 3)
					.padding(.leading, 15)
					.frame(maxWidth: .infinity, minHeight: 40, maxHeight: 40, alignment: .leading)
			}
			List {
				Section(header: Text("Time Slots")) {
					ExpenseRowView(
						tableView: self.$tableView,
						todaysExpenses: self.recentExpenses,
						timeSlots: $timeSlots,
						timeSlotOfCurrentTime: self.$timeSlotOfCurrentTime
					)
						.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
				}
			}
			.introspectTableView { tableView in
				if self.tableView != tableView {
					self.tableView = tableView
				}
				
				if appState.dayViewResetListPosition {
					debugLog("DayView: resetting list position")
					tableView.scrollToRow(
						at: IndexPath(
							item: self.getCalendarOffsetForCurrentTime() + 1, section: 0)
						, at: .middle
						, animated: false
					)
					appState.dayViewPosition = tableView.contentOffset
					appState.dayViewResetListPosition = false
				} else {
					tableView.setContentOffset(appState.dayViewPosition, animated: false)
					debugLog("DayView: list position updated to \(tableView.contentOffset)")
				}
			}
		}.onAppear {
			debugLog("DayView appeared")
			self.updateCurrentTimeSlot()
		}.onDisappear {
			debugLog("DayView disappeared")
			if let t = self.tableView {
				appState.dayViewPosition = t.contentOffset
				debugLog("AppState dayViewPosition updated to \(t.contentOffset)")
			}
			self.updateCurrentTimeSlot()
		}.onReceive(
			AppState.subject
				.filter({ $0 == .dayView })
				.collect(
					.byTime(
						RunLoop.main, .milliseconds(stateChangeCollectionTime)
					)
			)
		) { x in
			if let t = self.tableView, t.contentOffset.y > 0 {
				appState.dayViewPosition = t.contentOffset
				debugLog("AppState dayViewPosition updated to \(t.contentOffset)")
			}
			
			self.viewState += 1
			debugLog("DayView: view state changed to \(self.viewState) (\(x.count) events)")
		}
	}
	
	func updateCurrentTimeSlot() {
		let ts = getTimeSlotOfCurrentTime()
		if ts != self.timeSlotOfCurrentTime {
			self.timeSlotOfCurrentTime = ts
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
	
	func updateTimeSlots() {
		var newTimeSlots: [TimeSlot] = []
		let today = getStartOfDay()
		let plusMinus = appState.dayViewPlusMinusDays
		
		debugLog("DayView.updateTimeSlots: Generating \(dayViewPeriodsPerDay()) time slots for each day")

		for dayOffset in -plusMinus ... plusMinus {
			for timeSlot in 0 ..< dayViewPeriodsPerDay() {
				let baseDate = today + Double(dayOffset) * days
				newTimeSlots.append(TimeSlot(baseDate: baseDate, slotIndex: timeSlot, slotSize: appState.shortPeriod))
			}
		}
		
		if timeSlots[0] != newTimeSlots[0] {
			timeSlots = newTimeSlots
		}
	}
	
}

func dayViewPeriodsPerDay() -> Int {
	let shortPeriod = appState.shortPeriod
	debugLog("dayViewPeriodsPerDay read shortPeriod = \(shortPeriod)")
	let result = Int(oneDay / appState.shortPeriod)
	debugLog("dayViewPeriodsPerDay() = \(result)")
	return result
}

struct RecentFundViewRow: View {
	let recentFunds: [FundPath]
	let index: Int
	let lastRecentFund: TimeFund?
	let fundPath: FundPath?
	
	init(recentFunds: [FundPath], index: Int) {
		self.recentFunds = recentFunds
		self.index = index
		self.lastRecentFund = recentFunds[index].last
		self.fundPath = recentFunds[index]
	}
	
	var noLastRecentFund: Bool {
		self.lastRecentFund == nil
	}
	
	func recentFundColor() -> Color {
		if index == recentFunds.count - 1 {
			return Color.init("HighlightBackground")
		} else {
			return Color.clear
		}
	}
	
	var body: some View {
		VStack(alignment: .leading, spacing: 5) {
			if noLastRecentFund {
				Text("Nothing")
					.font(.body)
					.padding(.top, 3)
					.padding(.leading, 15)
					.frame(maxWidth: .infinity, minHeight: 30, maxHeight: 30, alignment: .leading)
			} else {
				Text("\(self.lastRecentFund!.name)")
					.font(.body)
					.padding(.vertical, 5)
					.padding(.leading, 15)
					.frame(maxWidth: .infinity, minHeight: 30, alignment: .leading)
					.contentShape(Rectangle())
					.background(recentFundColor())
					.onTapGesture {
						appState.push(fundPath: self.fundPath!)
				}
				Rectangle()
					.frame(height: 1)
					.padding(.all, 0)
					.foregroundColor(Color(UIColor.separator))
			}
		}
	}
}

struct ExpenseRowView: View {
	@Binding private var tableView: UITableView?
	@Binding var budgetStack: BudgetStack
	var todaysExpenses: FetchedResults<TimeExpense>
	@Binding var timeSlots: [TimeSlot]
	@Binding var lastSelectedFundPaths: [FundPath]
	@Binding var action: DayViewAction
	@Binding var timeSlotOfCurrentTime: TimeSlot
	
	init(tableView: Binding<UITableView?>, todaysExpenses: FetchedResults<TimeExpense>, timeSlots: Binding<[TimeSlot]>, timeSlotOfCurrentTime: Binding<TimeSlot>) {
		debugLog("ExpenseRowView.init")
		_tableView = tableView
		self.todaysExpenses = todaysExpenses
		_timeSlots = timeSlots
		_budgetStack = appState.$budgetStack
		_lastSelectedFundPaths = appState.$lastSelectedFundPaths
		_action = appState.$dayViewAction
		_timeSlotOfCurrentTime = timeSlotOfCurrentTime
	}
	
	var body: some View {
		ForEach(0 ..< self.timeSlots.count, id: \.self) { index in
			self.rowView(index)
		}
	}
	
	func colorOfRow(timeSlot: TimeSlot) -> some View {
		if(timeSlot == timeSlotOfCurrentTime) {
			return Color.init("HighlightBackground")
		}
		return Color.clear
	}
	
	func rowView(_ index: Int) -> some View {
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
		.background(colorOfRow(timeSlot: timeSlot))
		.onTapGesture {
			debugLog("DayView: expense row pressed")
			let existingExpense = getExpenseFor(timeSlot: timeSlot, todaysExpenses: self.todaysExpenses)
			
			if let t = self.tableView {
				appState.dayViewPosition = t.contentOffset
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
				appState.push(fundPath: existingExpense!.fundPath)
				self.removeExpense(existingExpense: existingExpense!)
			} else {
				if let lastFundPath = self.lastSelectedFundPaths.last {
					addExpense(timeSlot: timeSlot, fundPath: lastFundPath)
					saveData()
				}
			}
			//			}
		}
	}
	
	func removeExpense(existingExpense: TimeExpense) {
		debugLog("removeExpense: \(existingExpense)")
		existingExpense.lastFund.adjustBalance(1)
		var path = existingExpense.path.split(separator: newline)
		if path.count > 0 {
			path.reverse()
			for i in 0 ..< path.count - 1 {
				
				let fundName = String(path[i])
				let budgetName = String(path[i+1])
				
				let request = TimeFund.fetchRequest(budgetName: budgetName, fundName: fundName)
				
				do {
					let funds = try managedObjectContext.fetch(request)
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
		managedObjectContext.delete(existingExpense)
		saveData()
	}
}

func getExpenseFor(timeSlot: TimeSlot, todaysExpenses: FetchedResults<TimeExpense>) -> TimeExpense? {
	var result: TimeExpense? = nil
	
	let shortPeriod = appState.shortPeriod
	for expense in todaysExpenses {
		if expense.when >= timeSlot.baseDate + Double(timeSlot.slotIndex) * shortPeriod {
			let endDate = timeSlot.baseDate + Double(timeSlot.slotIndex) * shortPeriod + shortPeriod
			if expense.when < endDate {
				result = expense
			}
			break
		}
	}
	return result
}

func toExpenseString(timeSlot: TimeSlot, todaysExpenses: FetchedResults<TimeExpense>) -> String {
	var result = ""
	//	debugLog("DayView.toExpenseString(\(timeSlot))")
	if let existingExpense = getExpenseFor(timeSlot: timeSlot, todaysExpenses: todaysExpenses) {
		result = existingExpense.fundName
		//		debugLog("DayView.toExpenseString: existing expense: \(result)")
	} else {
		//		debugLog("DayView.toExpenseString: No existing expense")
	}
	return result
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
		let budget = testDataBuilder.budgets.first!
		appState.budgetStack.push(budget: budget)
		let fund = testDataBuilder.funds.first!
		let fundPath = FundPath(fundPath: [fund])
		appState.lastSelectedFundPaths.append(fundPath)
		
		return Group {
			DayView()
				.environment(\.colorScheme, .light)
				.environment(\.managedObjectContext, context)
			
			//			DayView()
			//				.environment(\.colorScheme, .dark)
			//				.environment(\.managedObjectContext, context)
		}
		
	}
}



