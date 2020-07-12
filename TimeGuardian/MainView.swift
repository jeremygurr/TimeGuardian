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
	@EnvironmentObject private var frontModel: BudgetFrontModel
	
	var body: some View {
		NavigationView {
			VStack {
				List {
					ForEach(frontModel.budgetList, id: \.self) { budget in
						NavigationLink(
							destination: BudgetView(budget: budget)
						) {
							Text(budget.name)
						}
					}
					.onDelete { indexSet in
						for index in indexSet {
							self.frontModel.deleteBudget(index: index)
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
		frontModel.moveBudget(fromOffsets: source, toOffset: destination)
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

