//
//  FundListView.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/16/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI

struct FundListView: View {
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	@EnvironmentObject var budgetStack: BudgetStack
	@FetchRequest var availableFunds: FetchedResults<TimeFund>
	@FetchRequest var spentFunds: FetchedResults<TimeFund>
	@FetchRequest var allFunds: FetchedResults<TimeFund>
	@State var newFundTop = ""
	@State var newFundBottom = ""
	@State var action: FundAction = .spend
	
	init(budgetStack: BudgetStack) {
		let budget = budgetStack.getTopBudget()
		_availableFunds = TimeFund.fetchAvailableRequest(budget: budget)
		_spentFunds = TimeFund.fetchSpentRequest(budget: budget)
		_allFunds = TimeFund.fetchAllRequest(budget: budget)
	}
	
	var body: some View {
		VStack {
			MultiRowSegmentedPickerView(
				choices: FundAction.allCasesInRows,
				selectedIndex: self.$action,
				onChange: { (newValue: FundAction) in
					if newValue == .edit {
						self.editMode?.wrappedValue = .active
					} else {
						self.editMode?.wrappedValue = .inactive
						UIApplication.shared.endEditing(true)
					}
			}
				)
			List {
				if self.action == .spend
					|| self.action == .reset
					|| self.action == .earn
					|| self.action == .delete
				{
					FundSectionAllView(
						allFunds: self.allFunds,
						action: self.$action
					)
				}
				FundSectionAvailableView(
					availableFunds: self.availableFunds,
					allFunds: self.allFunds,
					newFundTop: self.$newFundTop,
					newFundBottom: self.$newFundBottom,
					action: self.$action
				)
				FundSectionSpentView(
					spentFunds: self.spentFunds,
					allFunds: self.allFunds,
					action: self.$action
				)
			}
		}
	}
}

struct FundSectionAllView: View {
	var allFunds: FetchedResults<TimeFund>
	@Binding var action: FundAction
	@Environment(\.managedObjectContext) var managedObjectContext
	var allFundBalance: Int16 {
		var total: Int16 = 0
		for fund in self.allFunds {
			total += fund.balance
		}
		return total
	}
	
	var body: some View {
		Section() {
			Button(action: {
				switch self.action {
					case .spend:
						for fund in self.allFunds {
							fund.adjustBalance(-1)
						}
					case .reset:
						for fund in self.allFunds {
							fund.resetBalance()
						}
					case .earn:
						for fund in self.allFunds {
							fund.adjustBalance(1)
						}
					case .subBudget:
					  debugLog("Can't create subBudget on all")
					case .clone:
						debugLog("Can't clone all")
					case .edit:
						debugLog("Not implemented yet")
					case .delete:
						debugLog("Not implemented yet")
				}
				saveData(self.managedObjectContext)
			}, label: {
				HStack {
					Text("\(allFundBalance)")
						.frame(width: 40, alignment: .trailing)
					Divider()
					Text("All Funds")
						.frame(minWidth: 20, maxWidth: .infinity, alignment: .leading)
				}
			})
		}
	}
}

struct FundSectionAvailableView: View {
	var availableFunds: FetchedResults<TimeFund>
	var allFunds: FetchedResults<TimeFund>
	@Binding var newFundTop: String
	@Binding var newFundBottom: String
	@Binding var action : FundAction
	@Environment(\.managedObjectContext) var managedObjectContext
	
	var body: some View {
		Section(header: Text("Available")) {
			NewFundRowView(newFundName: $newFundTop, funds: availableFunds, posOfNewFund: .before)
			ForEach(availableFunds, id: \.self) { fund in
				FundRowView(action: self.$action, fund: fund, funds: self.allFunds)
			}.onDelete { indexSet in
				for index in 0 ..< self.availableFunds.count {
					let fund = self.availableFunds[index]
					if indexSet.contains(index) {
						self.managedObjectContext.delete(fund)
					}
				}
				saveData(self.managedObjectContext)
			}.onMove() { (source: IndexSet, destination: Int) in
				var newFunds: [TimeFund] = self.availableFunds.map() { $0 }
				newFunds.move(fromOffsets: source, toOffset: destination)
				for (index, fund) in newFunds.enumerated() {
					fund.order = Int16(index)
				}
				saveData(self.managedObjectContext)
			}
			NewFundRowView(newFundName: $newFundBottom, funds: availableFunds, posOfNewFund: .after)
		}
	}
}

struct FundSectionSpentView: View {
	var spentFunds: FetchedResults<TimeFund>
	var allFunds: FetchedResults<TimeFund>
	@Binding var action : FundAction
	@Environment(\.managedObjectContext) var managedObjectContext
	
	var body: some View {
		Section(header: Text("Spent")) {
			ForEach(spentFunds, id: \.self) { fund in
				FundRowView(action: self.$action, fund: fund, funds: self.allFunds)
			}.onMove() { (source: IndexSet, destination: Int) in
				var newFunds: [TimeFund] = self.spentFunds.map() { $0 }
				newFunds.move(fromOffsets: source, toOffset: destination)
				for (index, fund) in newFunds.enumerated() {
					fund.order = Int16(index)
				}
				saveData(self.managedObjectContext)
			}
		}
	}
}

struct FundListView_Previews: PreviewProvider {
	static var previews: some View {
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		let testDataBuilder = TestDataBuilder(context: context)
		testDataBuilder.createTestData()
		let budget = testDataBuilder.budgets.first!
		let budgetStack = BudgetStack()
		budgetStack.push(budget: budget)
		return FundListView(budgetStack: budgetStack)
			.environment(\.managedObjectContext, context)
			.environmentObject(budgetStack)
	}
}



