//
//  BudgetRow.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/14/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI

struct BudgetRow: View {
	@State var budget: TimeBudget
	@Binding var editingBudget: TimeBudget?
	@Binding var editMode: EditMode
	@EnvironmentObject var frontModel: BudgetFrontModel
	
	var body: some View {
		VStack {
			if self.budget == self.editingBudget {
				TextField("Budget Name", text: self.$budget.name, onCommit: {
					debugLog("Committed")
					if self.budget.name != "" {
						self.budget.managedObjectContext?.performAndWait {
							self.budget.save()
						}
					} else {
						self.frontModel.deleteBudget(budget: self.budget)
					}
					self.editingBudget = nil
				}).font(.body)
					.onDisappear(perform: {
						debugLog("Disappeared")
					}).introspectTextField { textField in
						textField.becomeFirstResponder()
				}
			} else {
				if self.editMode == .active {
					Text(self.budget.name)
						.font(.body)
						.frame(minWidth: 0, maxWidth: .infinity, minHeight: 40, alignment: .leading)
						.contentShape(Rectangle())
						.onTapGesture {
							self.editingBudget = self.budget
							self.editMode = .inactive
					}
				} else {
//					Text("not")
					NavigationLink(
						destination: FundListOld(budget: self.budget, fundList: self.frontModel.getFunds(budget: self.budget))
					) {
						Text(self.budget.name)
							.font(.body)
					}
				}
			}
		}
	}
}

struct BudgetRow_Previews: PreviewProvider {
	@State static var editMode = EditMode.active
	@State static var editingBudget: TimeBudget? = nil
	static let frontModel = generateTestFrontModel(empty: false)
	
	static var previews: some View {
		BudgetRow(budget: frontModel.budgetList[0], editingBudget: $editingBudget, editMode: $editMode).padding()
			.environmentObject(frontModel)
	}
}
