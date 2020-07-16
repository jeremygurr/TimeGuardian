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
	@State var funds: [TimeFund]
	@State var newFundTop = ""
	@State var newFundBottom = ""
	
	init(budget: TimeBudget) {
		self.budget = budget
		if let fundSet = budget.funds,
			let funds = fundSet.allObjects as? [TimeFund] {
			_funds = State(initialValue: funds)
			debugLog("fetched \(funds.count) funds from \(budget.name)")
		} else {
			_funds = State(initialValue: [])
		}
	}
	
	var body: some View {
		NavigationView {
			List {
				NewFundRowView(newFundName: $newFundTop, funds: $funds, posOfNewFund: .before, budget: self.budget)
				ForEach(funds, id: \.self) { fund in
					FundRowView(fund: fund, budget: self.budget)
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
					self.funds = newFunds
					self.managedObjectContext.refresh(self.budget, mergeChanges: false)
				}.onMove() { (source: IndexSet, destination: Int) in
					var newFunds: [TimeFund] = self.funds.map() { $0 }
					newFunds.move(fromOffsets: source, toOffset: destination)
					for (index, fund) in newFunds.enumerated() {
						fund.order = Int16(index)
					}
					self.funds = newFunds
					saveData(self.managedObjectContext)
					self.managedObjectContext.refresh(self.budget, mergeChanges: false)
				}
				NewFundRowView(newFundName: $newFundBottom, funds: $funds, posOfNewFund: .after, budget: self.budget)
			}
			.navigationBarTitle("Funds of \(self.budget.name)", displayMode: .inline)
			.navigationBarItems(trailing: EditButton())
		}
	}
}

struct FundRowView: View {
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	@State var fund: TimeFund
	let budget: TimeBudget
	
	var body: some View {
		VStack {
			if self.editMode?.wrappedValue == .active {
				TextField("Fund Name", text: $fund.name, onCommit: {
					if self.fund.name == "" {
						self.managedObjectContext.delete(self.fund)
					}
					saveData(self.managedObjectContext)
					self.managedObjectContext.refresh(self.budget, mergeChanges: false)
				})
			} else {
				Text(fund.name)
					.font(.body)
					.frame(minWidth: 0, maxWidth: .infinity, minHeight: 40, alignment: .leading)
					.contentShape(Rectangle())
			}
		}
	}
}

struct NewFundRowView: View {
	@Environment(\.managedObjectContext) var managedObjectContext
	@Binding var newFundName: String
	@Binding var funds: [TimeFund]
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
						self.funds.insert(fund, at: index)
						index += 1
					}
					for i in 0 ..< self.funds.count {
						self.funds[i].order = Int16(i + index)
					}
					index += self.funds.count
					if self.posOfNewFund == .after {
						fund.order = Int16(index)
						self.funds.insert(fund, at: index)
						index += 1
					}
					saveData(self.managedObjectContext)
					self.managedObjectContext.refresh(self.budget, mergeChanges: false)
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



