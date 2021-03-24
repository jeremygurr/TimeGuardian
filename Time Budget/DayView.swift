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
	@Binding var action: DayViewAction
	@Binding var actionDetail: String
	@Binding var recentFunds: [FundPath]
	
	@State private var tableView: UITableView?
	
	init() {
		
		debugLog("DayView.init")
				
		_action = appState.$dayViewAction
		_actionDetail = appState.$dayViewActionDetail
		_budgetStack = appState.$budgetStack
		_recentFunds = appState.$lastSelectedFundPaths
		
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
					ExpenseRowView(tableView: $tableView)
						.listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
				}
			}
			.introspectTableView { tableView in
				if self.tableView != tableView {
					self.tableView = tableView
				}
				
				if appState.dayViewResetListPosition {
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
				}
			}
		}.onDisappear {
			if let t = self.tableView {
				appState.dayViewPosition = t.contentOffset
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
			if let t = self.tableView, t.contentOffset.y > 0 {
				appState.dayViewPosition = t.contentOffset
			}
			
			self.viewState += 1
			debugLog("DayView: view state changed to \(self.viewState) (\(x.count) events)")
		}
	}
	
	func getCalendarOffsetForCurrentTime() -> Int {
		var result: Int = 0
		for i in 0 ..< appState.dayViewTimeSlots.count {
			let slot = appState.dayViewTimeSlots[i]
			if slot.coversCurrentTime {
				result = i
				break
			}
		}
		return result
	}
	

}

func dayViewPeriodsPerDay() -> Int {
	let result = Int(oneDay / appState.shortPeriod)
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
	@FetchRequest var recentExpenses: FetchedResults<TimeExpense>
	@Binding var lastSelectedFundPaths: [FundPath]
	@Binding var action: DayViewAction
	@State var startDate: Date
	@State var endDate: Date

	init(tableView: Binding<UITableView?>) {

		debugLog("ExpenseRowView.init")

		_tableView = tableView
		_budgetStack = appState.$budgetStack
		_lastSelectedFundPaths = appState.$lastSelectedFundPaths
		_action = appState.$dayViewAction

		let today = getStartOfDay()
		let plusMinus = appState.dayViewPlusMinusDays
		let newStartDate = today - Double(plusMinus) * days
		let newEndDate = today + Double(plusMinus) * days
		_startDate = State(initialValue: newStartDate)
		_endDate = State(initialValue: newEndDate)
		_recentExpenses = TimeExpense.fetchRequestFor(startDate: newStartDate, endDate: newEndDate)

	}
	
	var body: some View {
		ForEach(0 ..< appState.dayViewTimeSlots.count, id: \.self) { index in
			self.rowView(index)
		}
	}
	
	func colorOfRow(timeSlot: TimeSlot) -> some View {
		if(timeSlot == appState.dayViewTimeSlotOfCurrentTime) {
			return Color.init("HighlightBackground")
		}
		return Color.clear
	}
	
	func rowView(_ index: Int) -> some View {
		let timeSlot = appState.dayViewTimeSlots[index]
		return HStack {
			VStack {
				Text("\(toDayString(timeSlot: timeSlot))")
				Text("\(toTimeString(timeSlot: timeSlot))")
			}
			.padding(.leading, 10)
			Spacer()
			Text("\(toExpenseString(timeSlot: timeSlot, todaysExpenses: self.recentExpenses))")
				.padding(.trailing, 10)
		}
		.contentShape(Rectangle())
		.background(colorOfRow(timeSlot: timeSlot))
		.onTapGesture {
			let existingExpense = getExpenseFor(timeSlot: timeSlot, todaysExpenses: self.recentExpenses)
			
			if let t = self.tableView {
				appState.dayViewPosition = t.contentOffset
			}
			
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
	if let existingExpense = getExpenseFor(timeSlot: timeSlot, todaysExpenses: todaysExpenses) {
		result = existingExpense.fundName
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
	return timeString
}

func toDayString(timeSlot: TimeSlot) -> String {
	let startOfDay = timeSlot.baseDate
	let interval = timeSlot.secondsFromBeginning
	let currentPeriod = startOfDay.advanced(by: interval)
	let timeFormat = DateFormatter()
	timeFormat.dateFormat = "E"
	let timeString = timeFormat.string(from: currentPeriod)
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
			
		}
		
	}
}
