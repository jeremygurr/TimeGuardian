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
	@Environment(\.editMode) var mode
	@EnvironmentObject private var budgetFrontModel: BudgetFrontModel
	
	var body: some View {
		NavigationView {
			VStack {
				List {
					ForEach(budgetFrontModel.budgetList, id: \.self) { budget in
						NavigationLink(
							destination: Text("Stub")
							//						BudgetView(budget: budget)
						) {
							Text(budget.name)
						}
					}
					.onDelete { indexSet in
						for index in indexSet {
							self.budgetFrontModel.deleteBudget(index: index)
						}
					}
					.onMove(perform: move)
				}
				.navigationBarTitle("Budget List", displayMode: .inline)
				.navigationBarItems(trailing: EditButton())
			}
		}
	}
	
	func move(from source: IndexSet, to destination: Int) {
		budgetFrontModel.moveBudget(fromOffsets: source, toOffset: destination)
		//			withAnimation {
		//				isEditable = false
		//			}
	}
}

struct MainView_Previews: PreviewProvider {
	static var previews: some View {
		do {
			let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
			let frontModel: BudgetFrontModel = try BudgetFrontModel(dataContext: context)
			return MainView()
				.environmentObject(frontModel)
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
	}
}

