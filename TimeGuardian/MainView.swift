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
	//	@Environment(\.editMode) var editMode
	@EnvironmentObject var frontModel: BudgetFrontModel
	@State var budgetList: [TimeBudget]
	@State var editMode = EditMode.inactive
	@State var editingBudget : TimeBudget? = nil
//
//	init(budgetList: [TimeBudget]) {
//		self.budgetList = budgetList
//		debugLog("Created a new MainView")
//	}
	
	var body: some View {
		NavigationView {
			VStack {
				List {
					ForEach(frontModel.budgetList, id: \.self) { budget in
						BudgetRow(budget: budget, editingBudget: self.$editingBudget)
					}
					.onDelete { indexSet in
						for index in indexSet {
							self.frontModel.deleteBudget(index: index)
						}
					}
					.onMove(perform: move)
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
	
	func move(from source: IndexSet, to destination: Int) {
		frontModel.moveBudget(fromOffsets: source, toOffset: destination)
		//			withAnimation {
		//				isEditable = false
		//			}
	}	
}

struct BudgetRow: View {
	@State var budget: TimeBudget
	@Binding var editingBudget: TimeBudget?
	@EnvironmentObject var frontModel: BudgetFrontModel
	
	var isEditing: Bool { budget == editingBudget }
	
	var body: some View {
		if isEditing {
			return AnyView(
				TextField("Budget Name", text: $budget.name, onCommit: {
					debugLog("Committed")
					self.budget.managedObjectContext?.performAndWait {
						self.budget.save()
					}
					self.editingBudget = nil
				}).onDisappear(perform: {
					debugLog("Disappeared")
				}).introspectTextField { textField in
					textField.becomeFirstResponder()
				}
			)
		} else {
			return AnyView(NavigationLink(
				destination: BudgetView(budget: budget)
			) {
				Text(budget.name)
			})
		}
	}
}

struct MyEditButton: View {
	@EnvironmentObject var frontModel: BudgetFrontModel
	@Binding var editMode: EditMode
	
	var body: some View {
		if editMode == .active {
			return Button(action: {
				self.editMode = .inactive
			}) {
				Text("Done")
					.fontWeight(.medium)
					.font(.headline)
					.frame(minWidth: 100, minHeight: 40, alignment: .leading)
				//				.border(Color.black, width: 2)
			}
		} else {
			return Button(action: {
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


