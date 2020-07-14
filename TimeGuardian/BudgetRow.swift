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
	
	var editingThisBudget: Bool { budget == editingBudget }
	
	var body: some View {
		if editingThisBudget {
			return AnyView(
				TextField("Budget Name", text: $budget.name, onCommit: {
					debugLog("Committed")
					if self.budget.name != "" {
						self.budget.managedObjectContext?.performAndWait {
							self.budget.save()
						}
					} else {
						self.frontModel.deleteBudget(budget: self.budget)
					}
					self.editingBudget = nil
				}).onDisappear(perform: {
					debugLog("Disappeared")
				}).introspectTextField { textField in
					textField.becomeFirstResponder()
				}
			)
		} else {
			if editMode == .active {
				return AnyView(
					Text(budget.name)
						.onTapGesture {
							self.editingBudget = self.budget
							self.editMode = .inactive
					}
				)
			} else {
				return AnyView(
					NavigationLink(
						destination: BudgetView(budget: budget)
					) {
						Text(budget.name)
					}
				)
			}
		}
	}
}

struct BudgetRow_Previews: PreviewProvider {
	@State static var editMode = EditMode.inactive
	@State static var editingBudget : TimeBudget? = nil

	static var previews: some View {
		do {
			let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
			let frontModel: BudgetFrontModel = try BudgetFrontModel(dataContext: context, testData: TestDataBuilder(context: context))
			
			return
				NavigationView {
					List {
						BudgetRow(budget: frontModel.budgetList[0], editingBudget: $editingBudget, editMode: $editMode)
					}
				}
				.environmentObject(frontModel)
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
	}
}
