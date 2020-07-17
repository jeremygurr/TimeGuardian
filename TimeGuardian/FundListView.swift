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
	@FetchRequest var funds: FetchedResults<TimeFund>
	@State var newFundTop = ""
	@State var newFundBottom = ""
	@State var action : FundBalanceAction = .minus
	
	init(budget: TimeBudget) {
		self.budget = budget
		_funds = TimeFund.fetchRequest(budget: budget)
	}
	
	var body: some View {
		NavigationView {
			VStack {
				Picker("Fund Action", selection: $action) {
					Text("-")
						.font(.largeTitle)
						.tag(FundBalanceAction.minus)
					Text("0")
						.font(.largeTitle)
						.tag(FundBalanceAction.zero)
					Text("+")
						.font(.largeTitle)
						.tag(FundBalanceAction.plus)
				}
				.pickerStyle(SegmentedPickerStyle())
				List {
					NewFundRowView(newFundName: $newFundTop, funds: funds, posOfNewFund: .before, budget: self.budget)
					ForEach(funds, id: \.self) { fund in
						FundRowView(action: self.$action, fund: fund, budget: self.budget)
					}.onDelete { indexSet in
						var newFunds: [TimeFund] = []
						for index in 0 ..< self.funds.count {
							let fund = self.funds[index]
							if indexSet.contains(index) {
								self.managedObjectContext.delete(fund)
							} else {
								newFunds.append(fund)
							}
						}
						saveData(self.managedObjectContext)
					}.onMove() { (source: IndexSet, destination: Int) in
						var newFunds: [TimeFund] = self.funds.map() { $0 }
						newFunds.move(fromOffsets: source, toOffset: destination)
						for (index, fund) in newFunds.enumerated() {
							fund.order = Int16(index)
						}
						saveData(self.managedObjectContext)
					}
					NewFundRowView(newFundName: $newFundBottom, funds: funds, posOfNewFund: .after, budget: self.budget)
				}
				.navigationBarTitle("Funds of \(self.budget.name)", displayMode: .inline)
				.navigationBarItems(trailing: EditButton())
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
					if self.fund.name == "" {
						self.managedObjectContext.delete(self.fund)
					}
					saveData(self.managedObjectContext)
				})
			} else {
				Button(action: {
					switch self.action {
						case .minus:
							self.fund.adjustBalance(-1)
						case .zero:
							self.fund.zeroBalance()
						case .plus:
							self.fund.adjustBalance(1)
					}
					saveData(self.managedObjectContext)
					self.managedObjectContext.refresh(self.fund, mergeChanges: false)
				}, label: {
					HStack {
						Text(fund.name)
							.frame(minWidth: 20, maxWidth: .infinity, alignment: .leading)
						Text("\(fund.balance)")
							.frame(minWidth: 20, maxWidth: 40, alignment: .trailing)
					}
				})

//				Text(fund.name)
//					.font(.body)
//					.frame(minWidth: 0, maxWidth: .infinity, minHeight: 40, alignment: .leading)
//					.contentShape(Rectangle())
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

struct FundListView_Previews: PreviewProvider {
	@FetchRequest(fetchRequest: TimeBudget.sortedFetchRequest()) static var budgets: FetchedResults<TimeBudget>
	
	static var previews: some View {
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		let testDataBuilder = TestDataBuilder(context: context)
		testDataBuilder.createTestData()
		let budget = self.budgets.first!
		return FundListView(budget: budget)
			.environment(\.managedObjectContext, context)
	}
}



