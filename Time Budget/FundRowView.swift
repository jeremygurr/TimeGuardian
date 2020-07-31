//
//  FundRowView.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/19/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

struct FundRowView: View {
	struct ViewState: Equatable {
		var ratioDisplayMode: RatioDisplayMode = .percentage
	}
	@State private var viewState = ViewState()
	@Environment(\.injected) private var injected: AppState.Injection
	private var stateUpdate: AnyPublisher<ViewState, Never> {
		injected.appState.map {
			ViewState(ratioDisplayMode: $0.ratioDisplayMode)
		}
		.removeDuplicates().eraseToAnyPublisher()
	}

	@Binding var action: FundAction
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	@EnvironmentObject var budgetStack: BudgetStack
	@EnvironmentObject var calendarSettings: CalendarSettings
	@ObservedObject var fund: TimeFund
	var funds: FetchedResults<TimeFund>
	let balance: String

	init(action: Binding<FundAction>, fund: ObservedObject<TimeFund>, funds: FetchedResults<TimeFund>) {
		_action = action
		_fund = fund
		self.funds = funds
		let f = fund.wrappedValue
		balance = f.frozen ? "∞" : "\(f.roundedBalance)"
	}
	
	var ratioString: String {
		let ratioString: String
		let percentage = fund.frozen ? "∞" : formatPercentage(fund.getRatio() * budgetStack.getCurrentRatio())
		let time = fund.frozen ? "∞" : formatTime(fund.getRatio() * budgetStack.getCurrentRatio() * 24 * 3600)
		switch viewState.ratioDisplayMode {
			case .percentage:
				ratioString = percentage
			case .timePerDay:
				ratioString = time
		}
		return ratioString
	}
         
	func commitRenameFund() {
		self.fund.name = self.fund.name.trimmingCharacters(in: .whitespacesAndNewlines)
		let newName = self.fund.name
		if newName == "" {
			self.managedObjectContext.rollback()
		} else if self.fund.subBudget != nil {
			let subBudget = self.fund.subBudget!
			if subBudget.name != newName {
				subBudget.name = newName
				if let funds = subBudget.superFund {
					for fundToRename in funds {
						if (fundToRename as! TimeFund).name != newName {
							(fundToRename as! TimeFund).name = newName
						}
					}
				}
			}
			saveData(self.managedObjectContext)
		}
	}
	
	var body: some View {
		VStack {
			if self.editMode?.wrappedValue == .active {
				TextField(
					"Fund Name",
					text: $fund.name,
					onEditingChanged: { value in
						if !value {
							self.commitRenameFund()
						}
				},
					onCommit: {
						self.commitRenameFund()
				}
				)
			} else {
				HStack {
					Text(balance)
						.frame(width: 30, alignment: .trailing)
					Divider()
					Text("\(ratioString)")
						.frame(width: 50, alignment: .trailing)
						.contentShape(Rectangle())
						.onTapGesture {
							if self.viewState.ratioDisplayMode == .percentage {
								self.injected.appState.value.ratioDisplayMode = .timePerDay
							} else {
								self.injected.appState.value.ratioDisplayMode = .percentage
							}
							debugLog("clicked on ratio button")
					}
					Divider()
					if fund.subBudget != nil
						&& self.action.goesToSubIfPossible {
						HStack {
							FundRowLabel(fund: self.fund)
							Image(systemName: "list.bullet")
								.imageScale(.large)
						}
						.contentShape(Rectangle())
						.onTapGesture {
							debugLog("clicked on sub")
							self.budgetStack.push(budget: self.fund.subBudget!)
							self.budgetStack.push(fund: self.fund)
						}
					} else {
						withAnimation(.none) {
							getMainButton()
						}
					}
				}
			}
		}
		.onReceive(stateUpdate) { self.viewState = $0 }
	}
	
	func getMainButton() -> some View {
		return FundRowLabel(fund: self.fund)
			.contentShape(Rectangle())
			.onTapGesture {
				debugLog("clicked on main action button")
				switch self.action {
					case .view:
						self.budgetStack.lastSelectedFund = self.fund
						return
					case .spend:
						//					self.fund.deepSpend(budgetStack: self.budgetStack)
						addExpenseToCurrentTimeIfEmpty(fund: self.fund, budgetStack: self.budgetStack, calendarSettings: self.calendarSettings, managedObjectContext: self.managedObjectContext)
						self.budgetStack.toFirstBudget()
					case .reset:
						self.fund.resetBalance()
					case .earn:
						self.fund.adjustBalance(1)
					case .subBudget:
						do {
							var subBudget: TimeBudget
							let request = TimeBudget.fetchRequest(name: self.fund.name)
							if let budgetWithSameName = try self.managedObjectContext.fetch(request).first {
								subBudget = budgetWithSameName
							} else {
								subBudget = TimeBudget(context: self.managedObjectContext)
								subBudget.name = self.fund.name
							}
							self.fund.subBudget = subBudget
						} catch {
							errorLog("\(error)")
					}
					case .copy:
						let newFund = TimeFund(context: self.managedObjectContext)
						newFund.name = self.fund.name
						newFund.order = self.fund.order
						newFund.budget = self.budgetStack.getTopBudget()
						newFund.subBudget = self.fund.subBudget
					case .edit:
						errorLog("Impossible")
					case .delete:
						self.managedObjectContext.delete(self.fund)
					case .qspend:
						self.fund.adjustBalance(-1)
					case .freeze:
						self.fund.frozen = !self.fund.frozen
					case .unSubBudget:
						self.fund.subBudget = nil
				}
				saveData(self.managedObjectContext)
		}
	}
}

enum RatioDisplayMode {
	case percentage, timePerDay
}

struct FundRowLabel: View {
	@ObservedObject var fund: TimeFund
	@EnvironmentObject var budgetStack: BudgetStack
	
	var body: some View {
		Text(fund.name)
			.frame(minWidth: 20, maxWidth: .infinity, alignment: .leading)
	}
}

func formatTime(_ x: Float) -> String {
	let y = Double(x)
	var result: String
	if y < 2 * minutes {
		result = String(format: "%.1fs", y / seconds)
	} else if y < 2 * hours {
		result = String(format: "%.1fm", y / minutes)
	} else {
		result = String(format: "%.1fh", y / hours)
	}
	
	return result
}

func formatPercentage(_ x: Float) -> String {
	let y = x*100
	var result: String
	if y >= 10 {
		result = String(format: "%2.0f%%", y)
	} else if y >= 1 {
		result = String(format: "%1.1f%%", y)
	} else {
		result = String(format: "%.2f%%", y)
	}
	
	return result
}

struct FundRowView_PreviewHelper: View {
	@FetchRequest var allFunds: FetchedResults<TimeFund>
	@State var action: FundAction = .view
	@State var ratioDisplayMode: RatioDisplayMode = .percentage
	let fund: TimeFund

	init(budget: TimeBudget, fund: TimeFund) {
		_allFunds = TimeFund.fetchAllRequest(budget: budget)
		self.fund = fund
	}
		
	var body: some View {
		FundRowView(action: $action, fund: ObservedObject(initialValue: fund), funds: allFunds)
	}
}

struct FundRowView_Previews: PreviewProvider {
	static var previews: some View {

		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		let testDataBuilder = TestDataBuilder(context: context)
		testDataBuilder.createTestData()
		let budget = testDataBuilder.budgets.first!
		let fund = testDataBuilder.funds.first!
		let budgetStack = BudgetStack()
		let calendarSettings = CalendarSettings()
		let appState = AppState.Injection(appState: .init(AppState()))
		budgetStack.push(budget: budget)
		return FundRowView_PreviewHelper(budget: budget, fund: fund)
			.environment(\.managedObjectContext, context)
			.environment(\.injected, appState)
			.environmentObject(budgetStack)
			.environmentObject(calendarSettings)
			.frame(maxHeight: 50)
			.border(Color.black, width: 2)
	}
}
