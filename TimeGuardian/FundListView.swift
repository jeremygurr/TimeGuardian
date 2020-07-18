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
	@FetchRequest var availableFunds: FetchedResults<TimeFund>
	@FetchRequest var spentFunds: FetchedResults<TimeFund>
	@State var newFundTop = ""
	@State var newFundBottom = ""
	@State var action : FundBalanceAction = .minus
	
	init(budget: TimeBudget) {
		self.budget = budget
		_availableFunds = TimeFund.fetchAvailableRequest(budget: budget)
		_spentFunds = TimeFund.fetchSpentRequest(budget: budget)
	}
	
	var body: some View {
		VStack {
			Picker("Fund Action", selection: $action) {
				Text("Spend")
					.tag(FundBalanceAction.minus)
				Text("Reset")
					.tag(FundBalanceAction.reset)
				Text("Earn")
					.tag(FundBalanceAction.plus)
				Text("Sub Budget")
					.tag(FundBalanceAction.subBudget)
			}
			.font(.largeTitle)
			.pickerStyle(SegmentedPickerStyle())
			List {
				FundSectionAllView(
					budget: self.budget,
					availableFunds: self.availableFunds,
					spentFunds: self.spentFunds,
					action: self.$action
				)
				FundSectionAvailableView(
					budget: self.budget,
					availableFunds: self.availableFunds,
					newFundTop: self.$newFundTop,
					newFundBottom: self.$newFundBottom,
					action: self.$action
				)
				FundSectionSpentView(
					budget: self.budget,
					spentFunds: self.spentFunds,
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
	var availableFunds: FetchedResults<TimeFund>
	var spentFunds: FetchedResults<TimeFund>
	@Binding var action: FundBalanceAction
	@Environment(\.managedObjectContext) var managedObjectContext
	var allFundBalance: Int16 {
		var total: Int16 = 0
		for fund in self.availableFunds {
			total += fund.balance
		}
		for fund in self.spentFunds {
			total += fund.balance
		}
		return total
	}
	
	var body: some View {
		Section() {
			Button(action: {
				switch self.action {
					case .minus:
						for fund in self.availableFunds {
							fund.adjustBalance(-1)
						}
						for fund in self.spentFunds {
							fund.adjustBalance(-1)
						}
					case .reset:
						for fund in self.availableFunds {
							fund.resetBalance()
						}
						for fund in self.spentFunds {
							fund.resetBalance()
						}
					case .plus:
						for fund in self.availableFunds {
							fund.adjustBalance(1)
						}
						for fund in self.spentFunds {
							fund.adjustBalance(1)
						}
					case .subBudget:
					  debugLog("Can't create subBudget on all")
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
	var availableFunds: FetchedResults<TimeFund>
	@Binding var newFundTop: String
	@Binding var newFundBottom: String
	@Binding var action : FundBalanceAction
	@Environment(\.managedObjectContext) var managedObjectContext
	
	var body: some View {
		Section(header: Text("Available")) {
			NewFundRowView(newFundName: $newFundTop, funds: availableFunds, posOfNewFund: .before, budget: self.budget)
			ForEach(availableFunds, id: \.self) { fund in
				FundRowView(action: self.$action, fund: fund, budget: self.budget)
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
	var spentFunds: FetchedResults<TimeFund>
	@Binding var action : FundBalanceAction
	@Environment(\.managedObjectContext) var managedObjectContext
	
	var body: some View {
		Section(header: Text("Spent")) {
			ForEach(spentFunds, id: \.self) { fund in
				FundRowView(action: self.$action, fund: fund, budget: self.budget)
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
				if fund.subBudget != nil {
					NavigationLink(
						destination: FundListView(budget: fund.subBudget!)
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
							case .minus:
								self.fund.adjustBalance(-1)
							case .reset:
								self.fund.resetBalance()
							case .plus:
								self.fund.adjustBalance(1)
							case .subBudget:
								let subBudget = TimeBudget(context: self.managedObjectContext)
								subBudget.name = self.fund.name
								self.fund.subBudget = subBudget
						}
						saveData(self.managedObjectContext)
					}, label: {
						HStack {
							Text("\(fund.balance)")
								.frame(width: 40, alignment: .trailing)
							Divider()
							Text(fund.name)
								.frame(minWidth: 20, maxWidth: .infinity, alignment: .leading)
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
	case minus, reset, plus, subBudget
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



