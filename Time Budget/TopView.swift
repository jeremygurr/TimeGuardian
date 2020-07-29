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
	@EnvironmentObject var calendarSettings: CalendarSettings
	@Environment(\.injected) private var injected: AppState.Injection
	@State var currentPosition: Int? = nil

	private func budgetFundView() -> some View {
		VStack {
			if self.budgetStack.isEmpty() {
				BudgetListViewWindow()
			} else {
				FundListViewWindow()
			}
		}
	}
	
	var body: some View {
		TabView {
			budgetFundView()
				.tabItem {
					Image(systemName: "list.bullet")
						.imageScale(.large)
					Text("Budget")
			}
			CalendarView(calendarSettings: calendarSettings)
				.tabItem {
					Image(systemName: "calendar")
						.imageScale(.large)
					Text("Day")
			}
		}
	}
}

struct BudgetListViewWindow: View {
	var body: some View {
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
	}
}

struct FundListViewWindow: View {
	@EnvironmentObject var budgetStack: BudgetStack
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext

	var body: some View {
		VStack {
			HStack {
				Text("< Back")
					.font(.body)
					.padding()
					.contentShape(Rectangle())
					.onTapGesture {
						withAnimation(.none) {
							self.budgetStack.removeLastBudget()
							self.budgetStack.removeLastFund()
							self.budgetStack.titleOverride = nil
							self.editMode?.wrappedValue = .inactive
							self.managedObjectContext.rollback()
						}
				}
				.onLongPressGesture(
					minimumDuration: longPressDuration, maximumDistance: longPressMaxDrift,
					pressing: {
						if $0 {
							self.budgetStack.titleOverride = "to Top"
						} else {
							self.budgetStack.titleOverride = nil
						}
				}, perform: {
					withAnimation(.none) {
						self.budgetStack.toFirstBudget()
						self.budgetStack.titleOverride = nil
						self.editMode?.wrappedValue = .inactive
						self.managedObjectContext.rollback()
					}
				}
				)
				Spacer()
				Text("\(budgetStack.getTitle())")
					.font(Font.system(size: budgetStack.getBudgetNameFontSize()))
					.padding(Edge.Set([.trailing]), 10)
				//							.frame(maxWidth: .infinity, alignment: .leading)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			if self.budgetStack.hasTopBudget() {
				FundListView(budgetStack: self.budgetStack)
			}
		}
	}
}

struct TopView_Previews: PreviewProvider {
	static var previews: some View {
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		let appState = AppState.Injection(appState: .init(AppState()))
		let tdb = TestDataBuilder(context: context)
		tdb.createTestData()
		let budgetStack = BudgetStack()
		//		budgetStack.push(budget: tdb.budgets.first!)
		return TopView()
			.environment(\.managedObjectContext, context)
			.environment(\.injected, appState)
			.environmentObject(budgetStack)
			.environmentObject(CalendarSettings())
	}
}
