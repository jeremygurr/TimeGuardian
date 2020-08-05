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
	
	init() {
		debugLog("TopView.init")
		_budgetStack = AppState.get().$budgetStack
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
		TabView(selection: AppState.get().$mainTabSelection) {
			budgetFundView()
				.tabItem {
					Image(systemName: "list.bullet")
						.imageScale(.large)
					Text("Budget")
			}.tag(MainTabSelection.fund)
			DayView()
				.tabItem {
					Image(systemName: "calendar")
						.imageScale(.large)
					Text("Day")
			}.tag(MainTabSelection.day)
		}
		.onReceive(
			AppState.subject
				.filter({ $0 == .budgetStack || $0 == .topView })
				.collect(.byTime(RunLoop.main, .milliseconds(stateChangeCollectionTime)))
		) { x in
			self.viewState += 1
			debugLog("TopView: view state changed to \(self.viewState) (\(x.count) events)")
		}
	}
}

enum MainTabSelection: Int, Hashable {
	case fund = 0
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
	@Environment(\.managedObjectContext) var managedObjectContext
	
	init() {
		debugLog("FundListViewWindow.init")
		_budgetStack = AppState.get().$budgetStack
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
							AppState.get().titleOverride = nil
							self.editMode?.wrappedValue = .inactive
							self.managedObjectContext.rollback()
						}
				}
				.onLongPressGesture(
					minimumDuration: Double(longPressDuration), maximumDistance: longPressMaxDrift,
					pressing: {
						if $0 {
							AppState.get().titleOverride = "to Top"
						} else {
							AppState.get().titleOverride = nil
						}
				}, perform: {
					withAnimation(.none) {
						self.budgetStack.toFirstBudget()
						AppState.get().titleOverride = nil
						self.editMode?.wrappedValue = .inactive
						self.managedObjectContext.rollback()
					}
				}
				)
				Spacer()
				Text("\(AppState.get().title)")
					.font(Font.system(size: AppState.get().budgetNameFontSize))
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

