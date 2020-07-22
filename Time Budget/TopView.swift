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
							.font(.title)
							.frame(maxWidth: .infinity, alignment: .center)
						EditButton()
							.padding()
							.font(.body)
							.frame(maxWidth: .infinity, alignment: .trailing)
					}
					BudgetListView()
				}
			} else {
				VStack {
					HStack {
						if self.budgetStack.getFunds().count > 1 {
							Button(
								action: {
									self.budgetStack.toFirstBudget()
									self.editMode?.wrappedValue = .inactive
									self.managedObjectContext.rollback()
							},
								label: {
									Text("< Top")
										.font(.body)
										.padding()
							}
							)
						}
						Button(
							action: {
								self.budgetStack.removeLastBudget()
								self.budgetStack.removeLastFund()
								self.editMode?.wrappedValue = .inactive
								self.managedObjectContext.rollback()
						},
							label: {
								Text("< Back")
									.font(.body)
									.padding()
						}
						)
						Text("\(budgetStack.getTopBudget().name)")
							.font(Font.system(size: budgetStack.getBudgetNameFontSize()))
							.frame(maxWidth: .infinity, alignment: .leading)
					}
					.frame(maxWidth: .infinity, alignment: .leading)
					FundListView(budgetStack: self.budgetStack)
				}
			}
		}
	}
}

struct TopView_Previews: PreviewProvider {
	static var previews: some View {
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
//		let tdb = TestDataBuilder(context: context)
//		tdb.createTestData()
		let budgetStack = BudgetStack()
//		budgetStack.push(budget: tdb.budgets.first!)
		return TopView()
			.environment(\.managedObjectContext, context)
			.environmentObject(budgetStack)
	}
}
