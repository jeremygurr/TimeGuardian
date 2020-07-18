//
//  BudgetListView2.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/16/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI

struct BudgetListView: View {
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	@FetchRequest var mainBudgets: FetchedResults<TimeBudget>
	@FetchRequest var subBudgets: FetchedResults<TimeBudget>
	@State var newBudgetTop = ""
	@State var newBudgetBottom = ""

	init() {
		_mainBudgets = TimeBudget.fetchRequestMain()
		_subBudgets = TimeBudget.fetchRequestSub()
	}

	var body: some View {
		NavigationView {
			List {
				Section(header: Text("Top Level Budgets")) {
					NewBudgetRowView(newBudgetName: $newBudgetTop, budgets: mainBudgets, posOfNewBudget: .before)
					BudgetListSection(budgets: self.mainBudgets)
					NewBudgetRowView(newBudgetName: $newBudgetBottom, budgets: mainBudgets, posOfNewBudget: .after)
				}
				Section(header: Text("Sub Budgets")) {
					BudgetListSection(budgets: self.subBudgets)
				}
			}
			.navigationBarTitle("Budget List", displayMode: .inline)
			.navigationBarItems(trailing: EditButton())
		}
	}
}

struct BudgetListSection: View {
	var budgets: FetchedResults<TimeBudget>
	@Environment(\.managedObjectContext) var managedObjectContext

	var body: some View {
		ForEach(budgets, id: \.self) { budget in
			BudgetRowView(budget: budget)
		}.onDelete { indexSet in
			for index in indexSet {
				self.managedObjectContext.delete(self.budgets[index])
			}
			saveData(self.managedObjectContext)
		}.onMove() { (source: IndexSet, destination: Int) in
			var newBudgets: [TimeBudget] = self.budgets.map() { $0 }
			newBudgets.move(fromOffsets: source, toOffset: destination)
			for (index, budget) in newBudgets.enumerated() {
				budget.order = Int16(index)
			}
			saveData(self.managedObjectContext)
		}
	}
	
}

struct BudgetRowView: View {
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	@State var budget: TimeBudget
	
	var body: some View {
		VStack {
			if self.editMode?.wrappedValue == .active {
				TextField("Budget Name", text: $budget.name, onCommit: {
					self.budget.name = self.budget.name.trimmingCharacters(in: .whitespacesAndNewlines)
					if self.budget.name != "" {
						saveData(self.managedObjectContext)
					} else {
						self.managedObjectContext.delete(self.budget)
						saveData(self.managedObjectContext)
					}
				})
			} else {
				NavigationLink(
					destination: FundListView(budget: budget)
				) {
					Text(budget.name)
						.font(.body)
						.frame(minWidth: 0, maxWidth: .infinity, minHeight: 40, alignment: .leading)
						.contentShape(Rectangle())
				}
			}
		}
	}
}

struct NewBudgetRowView: View {
	@Environment(\.managedObjectContext) var managedObjectContext
	@Binding var newBudgetName: String
	var budgets: FetchedResults<TimeBudget>
	let posOfNewBudget: ListPosition
	
	var body: some View {
		HStack {
			TextField("New Budget", text: self.$newBudgetName, onCommit: addBudget)
				.frame(minWidth: 20, maxWidth: .infinity, alignment: .leading)
				.contentShape(Rectangle())
			Button(action: addBudget) {
				Image(systemName: "plus.circle.fill")
					.foregroundColor(.green)
					.imageScale(.large)
			}
		}
	}
	
	func addBudget() {
		self.newBudgetName = self.newBudgetName.trimmingCharacters(in: .whitespacesAndNewlines)
		
		if self.newBudgetName.count > 0 {
			let budget = TimeBudget(context: self.managedObjectContext)
			budget.name = self.newBudgetName
			var index = 0
			
			if self.posOfNewBudget == .before {
				budget.order = 0
				index += 1
			}
			
			for i in 0 ..< self.budgets.count {
				self.budgets[i].order = Int16(i + index)
			}
			
			index += self.budgets.count
			
			if self.posOfNewBudget == .after {
				budget.order = Int16(index)
				index += 1
			}
			
			saveData(self.managedObjectContext)
			self.newBudgetName = ""
		}
	}
}

enum ListPosition {
	case before, after
}

struct BudgetListView_Previews: PreviewProvider {
	static var previews: some View {
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		return BudgetListView()
			.environment(\.managedObjectContext, context)
	}
}

