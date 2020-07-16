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
				HStack {
					TextField("New Budget", text: self.$newBudgetTop)
					Button(action: {
						
					}) {
						Image(systemName: "plus.circle.fill")
							.foregroundColor(.green)
							.imageScale(.large)
					}
				}
				ForEach(budgets, id: \.self) { budget in
					Text(budget.name)
				}.onDelete { indexSet in
					for index in indexSet {
						debugLog("deleted")
					}
				}.onMove() { (source: IndexSet, destination: Int) in
					debugLog("moved")
				}
			}
			.navigationBarTitle("Budget List", displayMode: .inline)
			.navigationBarItems(trailing: EditButton())
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
