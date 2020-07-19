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
	let budget: TimeBudget
	let fundStack: [TimeFund]
	@FetchRequest var availableFunds: FetchedResults<TimeFund>
	@FetchRequest var spentFunds: FetchedResults<TimeFund>
	@FetchRequest var allFunds: FetchedResults<TimeFund>
	@State var newFundTop = ""
	@State var newFundBottom = ""
	@State var action: FundBalanceAction = .spend
	
	init(budget: TimeBudget, fundStack: [TimeFund] = [], parentFund: TimeFund? = nil) {
		self.budget = budget
		var newFundStack = fundStack
		if parentFund != nil {
			newFundStack.append(parentFund!)
		}
		self.fundStack = newFundStack
		_availableFunds = TimeFund.fetchAvailableRequest(budget: budget)
		_spentFunds = TimeFund.fetchSpentRequest(budget: budget)
		_allFunds = TimeFund.fetchAllRequest(budget: budget)
	}
	
	var body: some View {
		VStack {
			if self.editMode?.wrappedValue == .inactive {
				Picker("Fund Action", selection: $action) {
					Text("Spend")
						.tag(FundBalanceAction.spend)
					Text("Earn")
						.tag(FundBalanceAction.earn)
					Text("Reset")
						.tag(FundBalanceAction.reset)
					Text("Sub")
						.tag(FundBalanceAction.subBudget)
					Text("Clone")
						.tag(FundBalanceAction.clone)
				}
				.font(.largeTitle)
				.pickerStyle(SegmentedPickerStyle())
			}
			List {
				if self.action != .clone && self.action != .subBudget {
					FundSectionAllView(
						budget: self.budget,
						allFunds: self.allFunds,
						action: self.$action
					)
				}
				FundSectionAvailableView(
					budget: self.budget,
					fundStack: self.fundStack,
					availableFunds: self.availableFunds,
					allFunds: self.allFunds,
					newFundTop: self.$newFundTop,
					newFundBottom: self.$newFundBottom,
					action: self.$action
				)
				FundSectionSpentView(
					budget: self.budget,
					fundStack: self.fundStack,
					spentFunds: self.spentFunds,
					allFunds: self.allFunds,
					action: self.$action
				)
			}
			.navigationBarTitle("\(self.budget.name)", displayMode: .inline)
			.navigationBarItems(trailing: EditButton())
		}
	}
}

struct FundSectionAllView: View {
	let budget: TimeBudget
	var allFunds: FetchedResults<TimeFund>
	@Binding var action: FundBalanceAction
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
	let budget: TimeBudget
	let fundStack: [TimeFund]
	var availableFunds: FetchedResults<TimeFund>
	var allFunds: FetchedResults<TimeFund>
	@Binding var newFundTop: String
	@Binding var newFundBottom: String
	@Binding var action : FundBalanceAction
	@Environment(\.managedObjectContext) var managedObjectContext
	
	var body: some View {
		Section(header: Text("Available")) {
			NewFundRowView(newFundName: $newFundTop, funds: availableFunds, posOfNewFund: .before, budget: self.budget)
			ForEach(availableFunds, id: \.self) { fund in
				FundRowView(action: self.$action, fund: fund, budget: self.budget, fundStack: self.fundStack, funds: self.allFunds)
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
			NewFundRowView(newFundName: $newFundBottom, funds: availableFunds, posOfNewFund: .after, budget: self.budget)
		}
	}
}

struct FundSectionSpentView: View {
	let budget: TimeBudget
	let fundStack: [TimeFund]
	var spentFunds: FetchedResults<TimeFund>
	var allFunds: FetchedResults<TimeFund>
	@Binding var action : FundBalanceAction
	@Environment(\.managedObjectContext) var managedObjectContext
	
	var body: some View {
		Section(header: Text("Spent")) {
			ForEach(spentFunds, id: \.self) { fund in
				FundRowView(action: self.$action, fund: fund, budget: self.budget, fundStack: self.fundStack, funds: self.allFunds)
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
	@Binding var action: FundBalanceAction
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	@ObservedObject var fund: TimeFund
	let budget: TimeBudget
	let fundStack: [TimeFund]
	var funds: FetchedResults<TimeFund>
	
	var body: some View {
		VStack {
			if self.editMode?.wrappedValue == .active {
				TextField("Fund Name", text: $fund.name, onCommit: {
					self.fund.name = self.fund.name.trimmingCharacters(in: .whitespacesAndNewlines)
					if self.fund.name == "" {
						self.managedObjectContext.delete(self.fund)
					}
					saveData(self.managedObjectContext)
				})
			} else {
				if fund.subBudget != nil && self.action == .spend {
					NavigationLink(
						destination: FundListView(budget: fund.subBudget!, fundStack: self.fundStack, parentFund: self.fund)
					) {
						Text("\(fund.balance)")
							.frame(width: 40, alignment: .trailing)
						Divider()
						Text(fund.name)
							.frame(minWidth: 20, maxWidth: .infinity, alignment: .leading)
					}
				} else {
					Button(action: {
						switch self.action {
							case .spend:
								self.fund.adjustBalance(-1)
								for f in self.fundStack {
									f.adjustBalance(-1)
							}
							case .reset:
								self.fund.resetBalance()
							case .earn:
								self.fund.adjustBalance(1)
							case .subBudget:
								do {
									var subBudget: TimeBudget
									if let budgetWithSameName = try self.managedObjectContext.fetch(TimeBudget.fetchRequest(name: self.fund.name)).first {
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
								newFund.budget = self.budget
								for i in 0 ..< self.funds.count {
									self.funds[i].order = Int16(i)
								}
								newFund.order = Int16(self.funds.count)
								newFund.subBudget = self.fund.subBudget
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
	@Binding var newFundName: String
	var funds: FetchedResults<TimeFund>
	let posOfNewFund: ListPosition
	let budget: TimeBudget
	
	var body: some View {
		HStack {
			TextField("New Fund", text: self.$newFundName)
			Button(action: {
				self.newFundName = self.newFundName.trimmingCharacters(in: .whitespacesAndNewlines)
				
				if self.newFundName.count > 0 {
					let fund = TimeFund(context: self.managedObjectContext)
					fund.name = self.newFundName
					fund.budget = self.budget
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

enum FundBalanceAction: CaseIterable {
	case spend, reset, earn, subBudget, clone
}

struct FundListView_Previews: PreviewProvider {
	static var previews: some View {
		let mainBudgets = TimeBudget.fetchRequestMain()
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		let testDataBuilder = TestDataBuilder(context: context)
		testDataBuilder.createTestData()
		let budget = mainBudgets.wrappedValue.first!
		return FundListView(budget: budget)
			.environment(\.managedObjectContext, context)
	}
}



