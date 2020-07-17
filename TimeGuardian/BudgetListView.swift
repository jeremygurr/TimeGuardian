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
	@FetchRequest(fetchRequest: TimeBudget.sortedFetchRequest()) var budgets: FetchedResults<TimeBudget>
	@State var newBudgetTop = ""
	@State var newBudgetBottom = ""
	
	var body: some View {
		NavigationView {
			List {
				NewBudgetRowView(newBudgetName: $newBudgetTop, budgets: budgets, posOfNewBudget: .before)
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
				NewBudgetRowView(newBudgetName: $newBudgetBottom, budgets: budgets, posOfNewBudget: .after)
			}
			.navigationBarTitle("Budget List", displayMode: .inline)
			.navigationBarItems(trailing: EditButton())
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
					if self.budget.name != "" {
						self.budget.managedObjectContext?.performAndWait {
							saveData(self.managedObjectContext)
						}
					} else {
						self.budget.managedObjectContext?.performAndWait {
							self.managedObjectContext.delete(self.budget)
							saveData(self.managedObjectContext)
						}
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

