import SwiftUI
import os
import CoreData
import Introspect


struct BudgetListViewOld: View {
	@EnvironmentObject var frontModel: BudgetFrontModel
	@State var budgetList: [TimeBudget]
	@State var editMode = EditMode.inactive
	@State var editingBudget : TimeBudget? = nil
	
	var body: some View {
		NavigationView {
			VStack {
				List {
					ForEach(budgetList, id: \.self) { budget in
						BudgetRow(
							budget: budget,
							editingBudget: self.$editingBudget,
							editMode: self.$editMode
						)
					}
					.onDelete { indexSet in
						for index in indexSet {
							self.frontModel.deleteBudget(index: index)
						}
					}
					.onMove() { (source: IndexSet, destination: Int) in
						self.frontModel.moveBudget(fromOffsets: source, toOffset: destination)
					}
				}
				.navigationBarTitle("Budget List", displayMode: .inline)
				.navigationBarItems(
					leading: EditBudgetListButton(editMode: $editMode),
					trailing: CreateNewBudgetButton(
						editMode: editMode,
						editingBudget: $editingBudget
					)
				)
			}
			.environment(\.editMode, $editMode)
		}
	}
}

struct EditBudgetListButton: View {
	@EnvironmentObject var frontModel: BudgetFrontModel
	@Binding var editMode: EditMode
	
	var body: some View {
		VStack {
			if editMode == .active {
				Button(action: {
					self.editMode = .inactive
				}) {
					Text("Done")
						.fontWeight(.medium)
						.font(.headline)
						.frame(minWidth: 100, minHeight: 40, alignment: .leading)
					//				.border(Color.black, width: 2)
				}
			} else {
				Button(action: {
					self.editMode = .active
				}) {
					Text("Edit")
						.font(.headline)
						.fontWeight(.medium)
						.frame(minWidth: 100, minHeight: 40, alignment: .leading)
					//				.border(Color.black, width: 2)
				}
			}
		}
	}
}

struct CreateNewBudgetButton: View {
	@EnvironmentObject var frontModel: BudgetFrontModel
	let editMode: EditMode
	@Binding var editingBudget : TimeBudget?
	
	var body: some View {
		VStack {
			if editMode == .active {
				EmptyView()
			} else {
				Button(action: {
					debugLog("onAdd executed")
					do {
						self.editingBudget = try self.frontModel.addBudget()
					} catch {
						let nserror = error as NSError
						fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
					}
				}) {
					Image(systemName: "plus")
						.frame(minWidth: 100, minHeight: 40, alignment: .trailing)
				}				
			}
		}
	}
}

struct BudgetList_Previews: PreviewProvider {
	static let frontModel = generateTestFrontModel(empty: false)

	static var previews: some View {
		BudgetListViewOld(budgetList: frontModel.budgetList)
			.environmentObject(frontModel)
	}
}


