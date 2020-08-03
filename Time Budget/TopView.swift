//
//  TopView.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/19/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI

struct TopView: View {
	@State var budgetStack: BudgetStack
	let appState: AppState
	
	init(appState: AppState) {
		debugLog("TopView.init")
		_budgetStack = appState.budgetStack
		self.appState = appState
	}

	private func budgetFundView() -> some View {
		VStack {
			if self.budgetStack.isEmpty() {
				BudgetListViewWindow(appState: self.appState)
			} else {
				FundListViewWindow(appState: appState)
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
			DayView(appState: self.appState)
				.tabItem {
					Image(systemName: "calendar")
						.imageScale(.large)
					Text("Day")
			}
		}
	}
}

struct BudgetListViewWindow: View {
	let appState: AppState
	
	init(appState: AppState) {
		debugLog("BudgetListViewWindow.init")
		self.appState = appState
	}

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
			BudgetListView(appState: self.appState)
		}
	}
}

struct FundListViewWindow: View {
	@Binding var budgetStack: BudgetStack
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	let appState: AppState
	
	init(appState: AppState) {
		debugLog("FundListViewWindow.init")
		self.appState = appState
		_budgetStack = appState.budgetStack.projectedValue
	}

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
							self.appState.titleOverride = nil
							self.editMode?.wrappedValue = .inactive
							self.managedObjectContext.rollback()
						}
				}
				.onLongPressGesture(
					minimumDuration: longPressDuration, maximumDistance: longPressMaxDrift,
					pressing: {
						if $0 {
							self.appState.titleOverride = "to Top"
						} else {
							self.appState.titleOverride = nil
						}
				}, perform: {
					withAnimation(.none) {
						self.budgetStack.toFirstBudget()
						self.appState.titleOverride = nil
						self.editMode?.wrappedValue = .inactive
						self.managedObjectContext.rollback()
					}
				}
				)
				Spacer()
				Text("\(appState.title)")
					.font(Font.system(size: appState.budgetNameFontSize))
					.padding(Edge.Set([.trailing]), 10)
				//							.frame(maxWidth: .infinity, alignment: .leading)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			if self.budgetStack.hasTopBudget() {
				FundListView(appState: appState)
			}
		}
	}
}

struct TopView_Previews: PreviewProvider {
	static var previews: some View {
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		let appState = AppState()
		let tdb = TestDataBuilder(context: context)
		tdb.createTestData()
		return TopView(appState: appState)
			.environment(\.managedObjectContext, context)
	}
}
