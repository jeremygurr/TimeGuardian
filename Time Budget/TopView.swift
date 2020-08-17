//
//  TopView.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/19/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI
import Combine

struct TopView: View {
	@Binding var budgetStack: BudgetStack
	@State var viewState = 0
	@Environment(\.editMode) var editMode
	
	init() {
		debugLog("TopView.init")
		_budgetStack = appState.$budgetStack
	}
	
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
		TabView(selection: appState.$mainTabSelection) {
			budgetFundView()
				.tabItem {
					Image(systemName: "list.bullet")
						.imageScale(.large)
					Text("Budget")
			}.tag(MainTabSelection.fund)
			SettingsView()
				.tabItem {
					Image(systemName: "gear")
						.imageScale(.large)
					Text("Settings")
			}.tag(MainTabSelection.settings)
			DayView()
				.tabItem {
					Image(systemName: "calendar")
						.imageScale(.large)
					Text("Day")
			}.tag(MainTabSelection.day)
		}
		.onReceive(
			AppState.subject
				.filter({ $0 == .topView })
				.collect(.byTime(RunLoop.main, .milliseconds(stateChangeCollectionTime)))
		) { x in
			self.viewState += 1
			debugLog("TopView: view state changed to \(self.viewState) (\(x.count) events)")
		}
	}
}

enum MainTabSelection: Int, Hashable {
	case fund = 0
	case settings
	case day
}

struct BudgetListViewWindow: View {
	init() {
		debugLog("BudgetListViewWindow.init")
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
			BudgetListView()
		}
	}
}

struct FundListViewWindow: View {
	@Binding var budgetStack: BudgetStack
	@Environment(\.editMode) var editMode
	
	init() {
		debugLog("FundListViewWindow.init")
		_budgetStack = appState.$budgetStack
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
							appState.titleOverride = nil
							self.editMode?.wrappedValue = .inactive
							managedObjectContext.rollback()
						}
				}
				//				.onLongPressGesture(
				//					minimumDuration: Double(longPressDuration), maximumDistance: longPressMaxDrift,
				//					pressing: {
				//						if $0 {
				//							appState.titleOverride = "to Top"
				//						} else {
				//							appState.titleOverride = nil
				//						}
				//				}, perform: {
				//					withAnimation(.none) {
				//						self.budgetStack.toFirstBudget()
				//						appState.titleOverride = nil
				//						self.editMode?.wrappedValue = .inactive
				//						self.managedObjectContext.rollback()
				//					}
				//				}
				//				)
				Spacer()
				Text("\(appState.title)")
					.font(Font.system(size: appState.budgetNameFontSize))
					.padding(Edge.Set([.trailing]), 10)
			}
			.frame(maxWidth: .infinity, alignment: .leading)
			if self.budgetStack.hasTopBudget() {
				FundListView()
			}
		}
	}
}

struct TopView_Previews: PreviewProvider {
	static var previews: some View {
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		let tdb = TestDataBuilder(context: context)
		tdb.createTestData()
		return TopView()
			.environment(\.managedObjectContext, context)
	}
}


