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
	@State var isPressingBack = false
	
	func getTitle() -> String {
		var title: String
		if isPressingBack {
			title = "to Top"
		} else {
			title = budgetStack.getTopBudget().name
		}
		return title
	}
	
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
						Text("< Back")
							.font(.body)
							.padding()
							.contentShape(Rectangle())
							.onTapGesture {
								self.budgetStack.removeLastBudget()
								self.budgetStack.removeLastFund()
								self.editMode?.wrappedValue = .inactive
								self.managedObjectContext.rollback()
						}
							.onLongPressGesture(
								minimumDuration: longPressDuration, maximumDistance: longPressMaxDrift,
								pressing: {
									self.isPressingBack = $0
							}, perform: {
								self.budgetStack.toFirstBudget()
								self.editMode?.wrappedValue = .inactive
								self.managedObjectContext.rollback()
							}
						)
						Text("\(getTitle())")
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
