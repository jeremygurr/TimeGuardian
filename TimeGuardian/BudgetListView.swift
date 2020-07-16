//
//  BudgetListView2.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/16/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI

struct BudgetListView: View {
	@Environment(\.managedObjectContext) var managedObjectContext
	@FetchRequest(fetchRequest: TimeBudget.sortedFetchRequest()) var budgets: FetchedResults<TimeBudget>
	@State var newBudgetTop = ""
	@State var newBudgetBottom = ""
	
	var body: some View {
		NavigationView {
			List {
				NewBudgetRowView(newBudgetName: $newBudgetTop, budgets: budgets, posOfNewBudget: .before)
				ForEach(budgets, id: \.self) { budget in
					Text(budget.name)
				}.onDelete { indexSet in
					for index in indexSet {
						self.managedObjectContext.delete(self.budgets[index])
					}
					saveData(self.managedObjectContext)
				}.onMove() { (source: IndexSet, destination: Int) in
					debugLog("moved")
				}
				NewBudgetRowView(newBudgetName: $newBudgetBottom, budgets: budgets, posOfNewBudget: .after)
			}
			.navigationBarTitle("Budget List", displayMode: .inline)
			.navigationBarItems(trailing: EditButton())
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
			TextField("New Budget", text: self.$newBudgetName)
			Button(action: {
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
			}) {
				Image(systemName: "plus.circle.fill")
					.foregroundColor(.green)
					.imageScale(.large)
			}
		}
	}
}

struct BudgetListView2_Previews: PreviewProvider {
	static var previews: some View {
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		return BudgetListView()
			.environment(\.managedObjectContext, context)
	}
}

enum ListPosition {
	case before, after
}
