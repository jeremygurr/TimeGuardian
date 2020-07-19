//
//  TopView.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/19/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI

struct TopView: View {
	@State var budgetStack: [TimeBudget] = []
	
	var body: some View {
		VStack {
			if self.budgetStack.count == 0 {
				VStack {
					Text("Budgets")
						.font(.largeTitle)
						.frame(maxWidth: .infinity, alignment: .center)
					BudgetListView(budgetStack: self.$budgetStack)
				}
			} else {
				VStack {
					ZStack {
						Text("\(budgetStack.last!.name)")
							.font(.title)
							.frame(maxWidth: .infinity, alignment: .center)
						HStack {
							Button(
								action: {
									debugLog("not done")
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
					FundListView(budget: budgetStack.last!)
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
		return TopView(budgetStack: [tdb.budgets.first!])
			.environment(\.managedObjectContext, context)
	}
}
