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
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	@Binding var budgetStack: BudgetStack
	@FetchRequest var availableFunds: FetchedResults<TimeFund>
	@FetchRequest var spentFunds: FetchedResults<TimeFund>
	@FetchRequest var allFunds: FetchedResults<TimeFund>
	@State var newFundTop = ""
	@State var newFundBottom = ""
	@Binding var action: FundAction
	@Binding var actionDetail: String
	let appState: AppState

	init(appState: AppState) {
		self.appState = appState
		_budgetStack = appState.budgetStack.projectedValue
		let budget = appState.budgetStack.wrappedValue.getTopBudget()
		_availableFunds = TimeFund.fetchAvailableRequest(budget: budget)
		_spentFunds = TimeFund.fetchSpentRequest(budget: budget)
		_allFunds = TimeFund.fetchAllRequest(budget: budget)
		_actionDetail = appState.$fundListActionDetail
		_action = appState.$fundListAction
	}
	
	var body: some View {
		VStack {
			MultiRowSegmentedPickerView(
				actionDetail: self.$actionDetail,
				choices: FundAction.allCasesInRows,
				selectedIndex: self.$action,
				onChange: { (newValue: FundAction) in
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
			List {
				if self.action.canApplyToAll {
					FundAllRowView(
						allFunds: self.allFunds,
						action: $action,
						appState: self.appState
					)
				}
				FundSectionAvailableView(
					availableFunds: self.availableFunds,
					allFunds: self.allFunds,
					newFundTop: self.$newFundTop,
					newFundBottom: self.$newFundBottom,
					appState: self.appState
				)
				FundSectionSpentView(
					spentFunds: self.spentFunds,
					allFunds: self.allFunds,
					appState: self.appState
				)
				Text("").frame(height: listViewExtension)
			}
		}
	}
}

func fundInsets() -> EdgeInsets {
	return EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 20)
}

struct FundSectionAvailableView: View {
	var availableFunds: FetchedResults<TimeFund>
	var allFunds: FetchedResults<TimeFund>
	@Binding var newFundTop: String
	@Binding var newFundBottom: String
	@Binding var action : FundAction
	@Environment(\.editMode) var editMode
	@Environment(\.managedObjectContext) var managedObjectContext
	let appState: AppState

	init(
		availableFunds: FetchedResults<TimeFund>,
		allFunds: FetchedResults<TimeFund>,
		newFundTop: Binding<String>,
		newFundBottom: Binding<String>,
		appState: AppState) {
		self.availableFunds = availableFunds
		self.allFunds = allFunds
		self.appState = appState
		_newFundTop = newFundTop
		_newFundBottom = newFundBottom
		_action = appState.$fundListAction
	}
	
	var body: some View {
		Section(header: Text("Available")) {
			if self.editMode?.wrappedValue == .inactive {
				NewFundRowView(
					budgetStack: self.appState.budgetStack.projectedValue,
					newFundName: $newFundTop,
					funds: availableFunds,
					posOfNewFund: .before
				)
			}
			ForEach(availableFunds, id: \.self) { fund in
				FundRowView(
					fund: ObservedObject(initialValue: fund),
					funds: self.allFunds,
					appState: self.appState
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
					budgetStack: self.appState.budgetStack.projectedValue,
					newFundName: $newFundBottom,
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
	let appState: AppState
	
	init(
		spentFunds: FetchedResults<TimeFund>,
		allFunds: FetchedResults<TimeFund>,
		appState: AppState
	) {
		self.spentFunds = spentFunds
		self.allFunds = allFunds
		self.appState = appState
		_action = appState.$fundListAction
		_budgetStack = appState.budgetStack.projectedValue
	}

	var body: some View {
		Section(header: Text("Spent")) {
			if self.action.canApplyToAll {
				FundAllSpentRowView(spentFunds: self.spentFunds, action: self.$action)
			}
			ForEach(self.spentFunds, id: \.self) { fund in
				FundRowView(fund: ObservedObject(initialValue: fund), funds: self.allFunds, appState: self.appState)
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
		let appState = AppState()
		let budget = testDataBuilder.budgets.first!
		appState.budgetStack.wrappedValue.push(budget: budget)
		return FundListView(appState: appState)
			.environment(\.managedObjectContext, context)
//			.environment(\.colorScheme, .dark)
	}
}
