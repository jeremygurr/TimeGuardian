//
//  TopView.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/19/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI

struct TopView: View {
	@EnvironmentObject var budgetStack: BudgetStack
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	
	var body: some View {
		VStack {
			if self.budgetStack.isEmpty() {
				VStack {
					ZStack {
						Text("Budgets")
							.font(.largeTitle)
							.frame(maxWidth: .infinity, alignment: .center)
						EditButton()
							.padding()
							.font(.title)
							.frame(maxWidth: .infinity, alignment: .trailing)
					}
					BudgetListView()
				}
			} else {
				VStack {
					ZStack {
						Text("\(budgetStack.getTopBudget().name)")
							.font(.title)
							.frame(maxWidth: .infinity, alignment: .center)
						HStack {
							Button(
								action: {
									self.budgetStack.removeLastBudget()
									self.budgetStack.removeLastFund()
									self.editMode?.wrappedValue = .inactive
									self.managedObjectContext.rollback()
							},
								label: {
									Text("< Back")
										.font(.headline)
									.padding()
							}
							)
						}
						.frame(maxWidth: .infinity, alignment: .leading)
					}
					FundListView(budgetStack: self.budgetStack)
				}
			}
		}
	}
}

struct TopView_Previews: PreviewProvider {
	static var previews: some View {
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		let tdb = TestDataBuilder(context: context)
		tdb.createTestData()
		let budgetStack = BudgetStack()
//		budgetStack.push(budget: tdb.budgets.first!)
		return TopView()
			.environment(\.managedObjectContext, context)
			.environmentObject(budgetStack)
	}
}
