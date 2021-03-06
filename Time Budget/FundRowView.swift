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
	@Binding var fundAction: FundAction
	@Environment(\.editMode) var editMode
	@Binding var budgetStack: BudgetStack
	@ObservedObject var fund: TimeFund
	var funds: FetchedResults<TimeFund>
	@Binding var lastSelectedFundPaths: [FundPath]
	
	init(fund: ObservedObject<TimeFund>, funds: FetchedResults<TimeFund>) {
		_fundAction = appState.$fundListAction
		_fund = fund
		self.funds = funds
		_budgetStack = appState.$budgetStack
		_lastSelectedFundPaths = appState.$lastSelectedFundPaths
	}
	
	func handleFrozen(_ s: String) -> String {
		fund.frozen ? "∞" : s
	}
	
	var balanceString: String {
		let balanceString: String
		//		let t = fund.getRatio() * budgetStack.getCurrentRatio() * longPeriod * fund.balance / fund.recharge
		let shortPeriod = appState.shortPeriod
		let t = shortPeriod * TimeInterval(fund.balance)
		let time = formatTime(t)
		switch appState.balanceDisplayMode {
			case .unit:
				balanceString = "\(Int(fund.balance))"
			case .time:
				balanceString = time
		}
		return handleFrozen(balanceString)
	}
	
	var ratioString: String {
		let ratioString: String
		let percentage =
			formatPercentage(
				fund.getRatio() * budgetStack.getCurrentRatio()
		)
		let longPeriod = appState.longPeriod
		let time =
			formatTime(
				TimeInterval(fund.getRatio() * budgetStack.getCurrentRatio()) * longPeriod
		)
		let rechargeAmount = formatRecharge(fund.recharge)
		switch appState.ratioDisplayMode {
			case .percentage:
				ratioString = percentage
			case .timePerDay:
				ratioString = time
			case .rechargeAmount:
				ratioString = rechargeAmount
		}
		return handleFrozen(ratioString)
	}
	
	func commitRenameFund() {
		self.fund.name = self.fund.name.trimmingCharacters(in: .whitespacesAndNewlines)
		let newName = self.fund.name
		if newName == "" {
			managedObjectContext.rollback()
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
			saveData()
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
					Text("\(balanceString)")
						.frame(width: 55, alignment: .trailing)
						.onTapGesture {
							debugLog("clicked on balance button")
							appState.balanceDisplayMode = appState.balanceDisplayMode.next()
							saveData()
					}
					Divider()
					Text("\(ratioString)")
						.frame(width: 55, alignment: .trailing)
						.contentShape(Rectangle())
						.onTapGesture {
							debugLog("clicked on ratio button")
							switch self.fundAction {
								case .earn:
									self.fund.recharge += 1
									saveData()
								case .qspend:
									if self.fund.recharge > 1 {
										self.fund.recharge -= 1
										saveData()
								}
								default:
									appState.ratioDisplayMode = appState.ratioDisplayMode.next()
									saveData()
							}
					}
					Divider()
					if fund.subBudget != nil
						&& self.fundAction.goesToSubIfPossible {
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
							appState.push(fundPath: fundPath)
							self.budgetStack.push(budget: self.fund.subBudget!)
							self.budgetStack.push(fund: self.fund)
						}
					} else {
						withAnimation(.none) {
							getMainButton(expensePeriod: appState.shortPeriod)
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
				switch self.fundAction {
					case .view:
						var fundPath = self.budgetStack.getFundPath()
						fundPath.append(self.fund)
						appState.push(fundPath: fundPath)
						return
					case .spend:
						var fundPath = self.budgetStack.getFundPath()
						fundPath.append(self.fund)
						addExpenseToCurrentTimeIfEmpty(fundPath: fundPath)
						self.budgetStack.toFirstBudget()
					case .reset:
						self.fund.resetBalance()
					case .earn:
						self.fund.earn()
					case .subBudget:
						do {
							var subBudget: TimeBudget
							let request = TimeBudget.fetchRequest(name: self.fund.name)
							if let budgetWithSameName = try managedObjectContext.fetch(request).first {
								subBudget = budgetWithSameName
							} else {
								subBudget = TimeBudget(context: managedObjectContext)
								subBudget.name = self.fund.name
							}
							self.fund.subBudget = subBudget
						} catch {
							errorLog("\(error)")
					}
					case .copy:
						let newFund = TimeFund(context: managedObjectContext)
						newFund.name = self.fund.name
						newFund.order = self.fund.order
						newFund.budget = self.budgetStack.getTopBudget()
						newFund.subBudget = self.fund.subBudget
					case .edit:
						errorLog("Impossible")
					case .delete:
						managedObjectContext.delete(self.fund)
					case .qspend:
						self.fund.adjustBalance(-1)
					case .freeze:
						self.fund.frozen = !self.fund.frozen
					case .unSubBudget:
						self.fund.subBudget = nil
				}
				saveData()
		}
	}
}

struct FundRowLabel: View {
	@ObservedObject var fund: TimeFund
	
	var body: some View {
		Text(fund.name)
			.frame(minWidth: 20, maxWidth: .infinity, alignment: .leading)
	}
}

func formatTime(_ x: TimeInterval) -> String {
	var y = Double(x)
	
	var sign = ""
	if y < 0 {
		sign = "-"
		y = -y
	}
	
	var unit: String
	if y < 1 * minutes {
		y /= seconds
		unit = "s"
	} else if y < 1 * hours {
		y /= minutes
		unit = "m"
	} else {
		y /= hours
		unit = "h"
	}
	
	var result: String
	if y < 0.1 {
		result = ""
		unit = ""
		sign = ""
	} else {
		if y - y.rounded(.down) < 0.1 {
			result = String(format: "%.0f", y / seconds)
		} else {
			result = String(format: "%.1f", y / seconds)
		}
	}
	
	return sign + result + unit
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
		appState.budgetStack.push(budget: budget)
		
		return FundRowView_PreviewHelper(budget: budget, fund: fund)
			.environment(\.managedObjectContext, context)
			.frame(maxHeight: 50)
			.border(Color.black, width: 2)
		
	}
}

