//
//  FundRowView.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/19/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation
import SwiftUI

struct FundRowView: View {
	@Binding var action: FundAction
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	@EnvironmentObject var budgetStack: BudgetStack
	@EnvironmentObject var calendarSettings: CalendarSettings
	@ObservedObject var fund: TimeFund
	var funds: FetchedResults<TimeFund>
	
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
				if fund.subBudget != nil
					&& self.action.goesToSubIfPossible {
					Button(action: {
						self.budgetStack.push(budget: self.fund.subBudget!)
						self.budgetStack.push(fund: self.fund)
					}, label: {
						FundRowLabel(fund: self.fund)
					}
					)
				} else {
					withAnimation(.none) {
						getMainButton()
					}
				}
			}
		}
	}
	
	func getMainButton() -> some View {
		return Button(action: {
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
		}, label: {
			FundRowLabel(fund: self.fund)
		})
	}
}

struct FundRowLabel: View {
	@ObservedObject var fund: TimeFund
	@EnvironmentObject var budgetStack: BudgetStack
	
	var body: some View {
		let percentage = fund.frozen ? "∞" : formatPercentage(fund.getRatio() * budgetStack.getCurrentRatio())
		let balance = fund.frozen ? "∞" : "\(fund.roundedBalance)"
		return HStack {
			Text(balance)
				.frame(width: 30, alignment: .trailing)
			Divider()
			Text("\(percentage)")
				.frame(width: 50, alignment: .trailing)
			Divider()
			Text(fund.name)
				.frame(minWidth: 20, maxWidth: .infinity, alignment: .leading)
			if self.fund.subBudget != nil {
				Image(systemName: "list.bullet")
					.imageScale(.large)
			}
		}
	}
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

struct NewFundRowView: View {
	@Environment(\.managedObjectContext) var managedObjectContext
	@EnvironmentObject var budgetStack: BudgetStack
	@Binding var newFundName: String
	var funds: FetchedResults<TimeFund>
	let posOfNewFund: ListPosition
	
	var body: some View {
		HStack {
			TextField("New Fund", text: self.$newFundName)
			Button(action: {
				self.newFundName = self.newFundName.trimmingCharacters(in: .whitespacesAndNewlines)
				
				if self.newFundName.count > 0 {
					let fund = TimeFund(context: self.managedObjectContext)
					fund.name = self.newFundName
					fund.budget = self.budgetStack.getTopBudget()
					var index = 0
					
					if self.posOfNewFund == .before {
						fund.order = 0
						index += 1
					}
					
					for i in 0 ..< self.funds.count {
						self.funds[i].order = Int16(i + index)
					}
					
					index += self.funds.count
					
					if self.posOfNewFund == .after {
						fund.order = Int16(index)
						index += 1
					}
					
					saveData(self.managedObjectContext)
					self.newFundName = ""
				}
			}) {
				Image(systemName: "plus.circle.fill")
					.foregroundColor(.green)
					.imageScale(.large)
			}
		}
	}
}

struct FundRowView_Previews: PreviewProvider {
	@State static var action: FundAction = .spend
	@FetchRequest(
		entity: TimeFund.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \TimeFund.order, ascending: true)]
	) static var allFunds: FetchedResults<TimeFund>
	
	static var previews: some View {
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		let testDataBuilder = TestDataBuilder(context: context)
		testDataBuilder.createTestData()
		let budget = testDataBuilder.budgets.first!
		let fund = testDataBuilder.funds.first!
		let budgetStack = BudgetStack()
		budgetStack.push(budget: budget)
		return FundRowView(action: $action, fund: fund, funds: allFunds)
			.environment(\.managedObjectContext, context)
			.environmentObject(budgetStack)
	}
}
