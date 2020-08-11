//
//  FundListView.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/16/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI
import Combine

struct FundListView: View {
	@State var viewState = 0
	
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	@Binding var budgetStack: BudgetStack
	@FetchRequest var availableFunds: FetchedResults<TimeFund>
	@FetchRequest var spentFunds: FetchedResults<TimeFund>
	@FetchRequest var allFunds: FetchedResults<TimeFund>
	@Binding var action: FundAction
	@Binding var actionDetail: String

	init() {
		debugLog("FundListView init()")
		let appState = AppState.get()
		_budgetStack = appState.$budgetStack
		let budget = appState.budgetStack.getTopBudget()
		_availableFunds = TimeFund.fetchAvailableRequest(budget: budget)
		_spentFunds = TimeFund.fetchSpentRequest(budget: budget)
		_allFunds = TimeFund.fetchAllRequest(budget: budget)
		_actionDetail = appState.$fundListActionDetail
		_action = appState.$fundListAction
	}
	
	var body: some View {
		VStack {
			MultiRowSegmentedPickerView(
				choices: FundAction.allCasesInRows,
				selectedIndex: self.$action,
				onChange: { (newValue: FundAction) in
					self.actionDetail = newValue.longDescription

					if newValue == .edit {
						self.editMode?.wrappedValue = .active
					} else {
						self.editMode?.wrappedValue = .inactive
						UIApplication.shared.endEditing(true)
					}
			}
			)
			Text(actionDetail)
				.font(.body)
			FundAllRowView(
				allFunds: self.allFunds
			).frame(maxHeight: 20)
			List {
				FundSectionAvailableView(
					availableFunds: self.availableFunds,
					allFunds: self.allFunds
				)
				FundSectionSpentView(
					spentFunds: self.spentFunds,
					allFunds: self.allFunds
				)
				Text("").frame(height: listViewExtension)
			}
		}
		.onReceive(
			AppState.subject
				.filter({ $0 == .fundList })
				.collect(.byTime(RunLoop.main, .milliseconds(stateChangeCollectionTime)))
		) { x in
			self.viewState += 1
			debugLog("FundListView: view state changed to \(self.viewState) (\(x.count) events)")
		}
	}
}

func fundInsets() -> EdgeInsets {
	return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20)
}

struct FundSectionAvailableView: View {
	var availableFunds: FetchedResults<TimeFund>
	var allFunds: FetchedResults<TimeFund>
	@Binding var action : FundAction
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext

	init(
		
		availableFunds: FetchedResults<TimeFund>,
		allFunds: FetchedResults<TimeFund>
	) {

		let appState = AppState.get()
		self.availableFunds = availableFunds
		self.allFunds = allFunds
		_action = appState.$fundListAction
		
	}
	
	var body: some View {
		Section(header: Text("Available")) {
			if self.editMode?.wrappedValue == .inactive {
				NewFundRowView(
					budgetStack: AppState.get().$budgetStack,
					funds: availableFunds,
					posOfNewFund: .before
				)
			}
			ForEach(availableFunds, id: \.self) { fund in
				FundRowView(
					fund: ObservedObject(initialValue: fund),
					funds: self.allFunds
				)
			}
			.onMove() { (source: IndexSet, destination: Int) in
				debugLog("FundListView.onMove")

				var newFunds: [TimeFund] = self.availableFunds.map() { $0 }
				newFunds.move(fromOffsets: source, toOffset: destination)
				for (index, fund) in newFunds.enumerated() {
					fund.order = Int16(index)
				}
				saveData(self.managedObjectContext)
			}
			.listRowInsets(fundInsets())
			if self.editMode?.wrappedValue == .inactive {
				NewFundRowView(
					budgetStack: AppState.get().$budgetStack,
					funds: availableFunds,
					posOfNewFund: .after
				)
			}
		}
	}
}

struct FundSectionSpentView: View {
	var spentFunds: FetchedResults<TimeFund>
	var allFunds: FetchedResults<TimeFund>
	@Binding var action : FundAction
	@Environment(\.managedObjectContext) var managedObjectContext
	@Binding var budgetStack: BudgetStack
	
	init(
		spentFunds: FetchedResults<TimeFund>,
		allFunds: FetchedResults<TimeFund>
	) {
		self.spentFunds = spentFunds
		self.allFunds = allFunds
		let appState = AppState.get()
		_action = appState.$fundListAction
		_budgetStack = appState.$budgetStack
	}

	var body: some View {
		Section(header: Text("Spent")) {
//			if self.action.canApplyToAll {
			FundAllSpentRowView(spentFunds: self.spentFunds)
				.listRowInsets(fundInsets())

//			}
			ForEach(self.spentFunds, id: \.self) { fund in
				FundRowView(fund: ObservedObject(initialValue: fund), funds: self.allFunds)
			}.onMove() { (source: IndexSet, destination: Int) in
				var newFunds: [TimeFund] = self.spentFunds.map() { $0 }
				newFunds.move(fromOffsets: source, toOffset: destination)
				for (index, fund) in newFunds.enumerated() {
					fund.order = Int16(index)
				}
				saveData(self.managedObjectContext)
			}.listRowInsets(fundInsets())
		}
	}
}

struct FundListView_Previews: PreviewProvider {
	static var previews: some View {
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		let testDataBuilder = TestDataBuilder(context: context)
		testDataBuilder.createTestData()
		let appState = AppState.get()
		let budget = testDataBuilder.budgets.first!
		appState.budgetStack.push(budget: budget)
		return FundListView()
			.environment(\.managedObjectContext, context)
//			.environment(\.colorScheme, .dark)
	}
}
