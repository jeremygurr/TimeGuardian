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
				if self.action != .clone && self.action != .subBudget {
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
			}.onDelete { indexSet in
				for index in 0 ..< self.spentFunds.count {
					let fund = self.spentFunds[index]
					if indexSet.contains(index) {
						self.managedObjectContext.delete(fund)
					}
				}
				saveData(self.managedObjectContext)
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

struct FundRowView: View {
	@Binding var action: FundAction
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	@EnvironmentObject var budgetStack: BudgetStack
	@ObservedObject var fund: TimeFund
	var funds: FetchedResults<TimeFund>
	
	func commitRenameFund() {
		self.fund.name = self.fund.name.trimmingCharacters(in: .whitespacesAndNewlines)
		let newName = self.fund.name
		if newName == "" {
			self.managedObjectContext.delete(self.fund)
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
		}
		saveData(self.managedObjectContext)
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
				if fund.subBudget != nil && self.action == .spend {
					Button(action: {
						self.budgetStack.push(budget: self.fund.subBudget!)
						self.budgetStack.push(fund: self.fund)
					}, label: {
						HStack {
							Text("\(fund.balance)")
								.frame(width: 40, alignment: .trailing)
							Divider()
							Text(fund.name)
								.frame(minWidth: 20, maxWidth: .infinity, alignment: .leading)
							Image(systemName: "list.bullet")
								.imageScale(.large)
						}
					}
					)
				} else {
					Button(action: {
						switch self.action {
							case .spend:
								self.fund.adjustBalance(-1)
								for f in self.budgetStack.getFunds() {
									f.adjustBalance(-1)
							}
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
									if self.fund.subBudget == nil {
										self.fund.subBudget = subBudget
									} else {
										self.fund.subBudget = nil
									}
								} catch {
									errorLog("\(error)")
							}
							case .clone:
								let newFund = TimeFund(context: self.managedObjectContext)
								newFund.name = self.fund.name
								newFund.budget = self.budgetStack.getTopBudget()
								for i in 0 ..< self.funds.count {
									self.funds[i].order = Int16(i)
								}
								newFund.order = Int16(self.funds.count)
								newFund.subBudget = self.fund.subBudget
							case .edit:
								errorLog("Impossible")
							case .delete:
								debugLog("Not implemented yet")
						}
						saveData(self.managedObjectContext)
					}, label: {
						HStack {
							Text("\(fund.balance)")
								.frame(width: 40, alignment: .trailing)
							Divider()
							Text(fund.name)
								.frame(minWidth: 20, maxWidth: .infinity, alignment: .leading)
							if self.fund.subBudget != nil {
								Image(systemName: "list.bullet")
									.imageScale(.large)
							}
						}
					})
				}
			}
		}
	}
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



