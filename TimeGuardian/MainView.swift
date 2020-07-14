import SwiftUI
import os
import CoreData
import Introspect

func debugLog(_ message: String) {
	print(message)
}

func errorLog(_ message: String) {
	print(message)
}

struct MainView: View {
	@EnvironmentObject var frontModel: BudgetFrontModel
	@State var budgetList: [TimeBudget]
	@State var editMode = EditMode.inactive
	@State var editingBudget : TimeBudget? = nil
	
	var body: some View {
		NavigationView {
			VStack {
				List {
					ForEach(frontModel.budgetList, id: \.self) { budget in
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
					leading: MyEditButton(editMode: $editMode),
					trailing: MyAddButton(
						editMode: editMode,
						editingBudget: $editingBudget
					)
				)
			}
			.environment(\.editMode, $editMode)
		}
	}
}

struct MyEditButton: View {
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

struct MyAddButton: View {
	@EnvironmentObject var frontModel: BudgetFrontModel
	let editMode: EditMode
	@Binding var editingBudget : TimeBudget?

	var body: some View {
		if editMode == .active {
			return AnyView(EmptyView())
		} else {
			return AnyView(Button(action: {
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
//								.border(Color.black, width: 2)
				}
			)
		}
	}
}

struct MainView_Previews: PreviewProvider {
	static var previews: some View {
		do {
			let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
			let frontModel: BudgetFrontModel = try BudgetFrontModel(dataContext: context, testData: TestDataBuilder(context: context))
			return MainView(budgetList: frontModel.budgetList)
				.environmentObject(frontModel)
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
	}
}


