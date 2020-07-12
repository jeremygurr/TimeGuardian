//
//  BudgetView.swift
//  Time Guardian
//
//  Created by Jeremy Gurr on 7/6/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI

struct BudgetView: View {
	let budget : TimeBudget
	@Environment(\.editMode) var mode
	@EnvironmentObject private var frontModel: BudgetFrontModel
	@State var action : BudgetViewAction = .minus
	
	var body: some View {
		VStack {
			Picker("Fund Action", selection: $action) {
				Text("-")
					.tag(BudgetViewAction.minus)
				Text("= 0")
					.tag(BudgetViewAction.zero)
				Text("+")
					.tag(BudgetViewAction.plus)
			}
			.pickerStyle(SegmentedPickerStyle())
			List {
				ForEach(frontModel.getFunds(budget: budget), id: \.self) { fund in
					BudgetViewRow(action: self.action, fund: fund)
				}
			}
			.navigationBarTitle(Text(budget.name))
		}
	}
}

struct BudgetView_Previews: PreviewProvider {
	static var previews: some View {
		do {
			let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
			let frontModel: BudgetFrontModel = try BudgetFrontModel(dataContext: context)
			let budget = frontModel.budgetList[0]
			return NavigationView {
				BudgetView(budget: budget)
			}.environmentObject(frontModel)
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
	}
}

enum BudgetViewAction: CaseIterable {
	case minus, zero, plus
}

struct BudgetViewRow: View {
	let action: BudgetViewAction
	var fund: TimeFund
	@EnvironmentObject private var frontModel: BudgetFrontModel

	var body: some View {
		VStack {
			if frontModel.hasSubBudget(fund: fund) {
				NavigationLink(
					destination: BudgetView(budget: fund.subBudget!)
				) {
					Text(fund.name)
				}
			} else {
				Button(fund.name) {
					switch self.action {
						case .minus:
							self.frontModel.adjustBalance(fund: self.fund, amount: -1)
						case .zero:
							self.frontModel.zeroBalance(fund: self.fund)
						case .plus:
							self.frontModel.adjustBalance(fund: self.fund, amount: 1)
					}
				}
			}
		}
	}
}
