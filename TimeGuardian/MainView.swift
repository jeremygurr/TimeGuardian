import SwiftUI
import os
import CoreData

func debugLog(_ message: String) {
	print(message)
}

func errorLog(_ message: String) {
	print(message)
}

struct MainView: View {
	//	@Environment(\.editMode) var editMode
	@State private var editMode = EditMode.inactive
	@EnvironmentObject private var frontModel: BudgetFrontModel
	@State private var budgetList: [TimeBudget] = []
	
	init(budgetList: [TimeBudget]) {
		self.budgetList = budgetList
		debugLog("Created a new MainView")
	}
	
	var body: some View {
		NavigationView {
			VStack {
				List {
					ForEach(frontModel.budgetList, id: \.self) { budget in
						BudgetRow(budget: budget)
					}
					.onDelete { indexSet in
						for index in indexSet {
							self.frontModel.deleteBudget(index: index)
						}
					}
					.onMove(perform: move)
				}
				.navigationBarTitle("Budget List", displayMode: .inline)
				.navigationBarItems(leading: EditButton(), trailing: addButton)
			}
			.environment(\.editMode, $editMode)
		}
	}
	
	func onAdd() {
		debugLog("onAdd executed")
		do {
			frontModel.editingBudget = try frontModel.addBudget()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
	}
	
	var addButton: some View {
		switch self.editMode {
			case .active:
				return AnyView(Button(action: self.onAdd) { Image(systemName: "plus") })
			default:
				return AnyView(EmptyView())
		}
	}
	
	func move(from source: IndexSet, to destination: Int) {
		frontModel.moveBudget(fromOffsets: source, toOffset: destination)
		//			withAnimation {
		//				isEditable = false
		//			}
	}
	
	struct BudgetRow: View {
		@State var budget: TimeBudget
		@EnvironmentObject private var frontModel: BudgetFrontModel

		var isEditing: Bool { budget == frontModel.editingBudget }
		
		var body: some View {
			debugLog("Created a new BudgetRow")
			if isEditing {
				return AnyView(
					TextField("Budget Name", text: $budget.name, onCommit: {
						debugLog("Committed")
						self.budget.managedObjectContext?.performAndWait {
							self.budget.save()
						}
						self.frontModel.editingBudget = nil
					}).onDisappear(perform: {
						debugLog("Disappeared")
					})
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


