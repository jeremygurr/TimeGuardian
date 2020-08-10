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
	@State var viewState = 0
	@Binding var action: FundAction
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	@Binding var budgetStack: BudgetStack
	@ObservedObject var fund: TimeFund
	var funds: FetchedResults<TimeFund>
	@Binding var ratioDisplayMode: RatioDisplayMode
	@Binding var dayViewExpensePeriod: TimeInterval
	@Binding var lastSelectedFundPaths: [FundPath]

	init(fund: ObservedObject<TimeFund>, funds: FetchedResults<TimeFund>) {
		let appState = AppState.get()
		_action = appState.$fundListAction
		_fund = fund
		self.funds = funds
		_ratioDisplayMode = appState.$ratioDisplayMode
		_budgetStack = appState.$budgetStack
		_dayViewExpensePeriod = appState.$dayViewExpensePeriod
		_lastSelectedFundPaths = appState.$lastSelectedFundPaths
	}

	var balance: String {
		fund.frozen ? "∞" : "\(fund.roundedBalance)"
	}

	var ratioString: String {
		let ratioString: String
		let percentage = fund.frozen ? "∞" : formatPercentage(fund.getRatio() * budgetStack.getCurrentRatio())
		let time = fund.frozen ? "∞" : formatTime(fund.getRatio() * budgetStack.getCurrentRatio() * longPeriod)
		let rechargeAmount = formatRecharge(fund.recharge)
		switch self.ratioDisplayMode {
			case .percentage:
				ratioString = percentage
			case .timePerDay:
				ratioString = time
			case .rechargeAmount:
				ratioString = rechargeAmount
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
						.frame(width: 55, alignment: .trailing)
						.contentShape(Rectangle())
						.onTapGesture {
							debugLog("clicked on ratio button")
							switch self.action {
								case .earn:
									self.fund.recharge += 1
									saveData(self.managedObjectContext)
								case .qspend:
									if self.fund.recharge > 1 {
										self.fund.recharge -= 1
										saveData(self.managedObjectContext)
									}
								default:
									self.ratioDisplayMode = self.ratioDisplayMode.next()
							}
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
							var fundPath = self.budgetStack.getFundPath()
							fundPath.append(self.fund)
							AppState.get().push(fundPath: fundPath)
							self.budgetStack.push(budget: self.fund.subBudget!)
							self.budgetStack.push(fund: self.fund)
						}
					} else {
						withAnimation(.none) {
							getMainButton(expensePeriod: self.dayViewExpensePeriod)
						}
					}
				}
			}
		}
		.onReceive(
			AppState.subject
				.filter({ $0 == .fundList })
				.collect(.byTime(RunLoop.main, .milliseconds(stateChangeCollectionTime)))
		) { x in
			self.viewState += 1
			debugLog("FundRowView: view state changed to \(self.viewState) (\(x.count) events)")
		}
	}
	
	func getMainButton(expensePeriod: TimeInterval) -> some View {
		return FundRowLabel(fund: self.fund)
			.contentShape(Rectangle())
			.onTapGesture {
				debugLog("clicked on main action button")
				switch self.action {
					case .view:
						var fundPath = self.budgetStack.getFundPath()
						fundPath.append(self.fund)
						AppState.get().push(fundPath: fundPath)
						return
					case .spend:
						var fundPath = self.budgetStack.getFundPath()
						fundPath.append(self.fund)
						addExpenseToCurrentTimeIfEmpty(fundPath: fundPath, expensePeriod: expensePeriod, managedObjectContext: self.managedObjectContext)
						self.budgetStack.toFirstBudget()
					case .reset:
						self.fund.resetBalance()
					case .earn:
						self.fund.earn()
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

enum RatioDisplayMode: CaseIterable {
	case percentage, timePerDay, rechargeAmount
}

struct FundRowLabel: View {
	@ObservedObject var fund: TimeFund
	
	var body: some View {
		Text(fund.name)
			.frame(minWidth: 20, maxWidth: .infinity, alignment: .leading)
	}
}

func formatTime(_ x: Float) -> String {
	let y = Double(x)
	var result: String
	if y < 1 * minutes {
		result = String(format: "%.1fs", y / seconds)
	} else if y < 1 * hours {
		result = String(format: "%.1fm", y / minutes)
	} else {
		result = String(format: "%.1fh", y / hours)
	}
	
	return result
}

func formatRecharge(_ x: Float) -> String {
	var result: String
	result = String(format: "%2.0f", x)
	if x >= 0 {
		result = "+" + result
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
	let fund: TimeFund

	init(budget: TimeBudget, fund: TimeFund) {
		_allFunds = TimeFund.fetchAllRequest(budget: budget)
		self.fund = fund
	}
		
	var body: some View {
		FundRowView(fund: ObservedObject(initialValue: fund), funds: allFunds)
	}
}

struct FundRowView_Previews: PreviewProvider {
	static var previews: some View {

		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		let testDataBuilder = TestDataBuilder(context: context)
		testDataBuilder.createTestData()
		let budget = testDataBuilder.budgets.first!
		let fund = testDataBuilder.funds.first!
		let appState = AppState.get()
		appState.budgetStack.push(budget: budget)
		
		return FundRowView_PreviewHelper(budget: budget, fund: fund)
			.environment(\.managedObjectContext, context)
			.frame(maxHeight: 50)
			.border(Color.black, width: 2)
		
	}
}
