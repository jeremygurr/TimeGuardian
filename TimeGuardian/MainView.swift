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
	//	@EnvironmentObject private var userData: UserData
	@Environment(\.managedObjectContext) var managedObjectContext
	@FetchRequest(
		entity: TimeBudget.entity(),
		sortDescriptors: [
			NSSortDescriptor(keyPath: \TimeBudget.name, ascending: true),
		]
	) var budgets: FetchedResults<TimeBudget>
	
	var body: some View {
		NavigationView {
			List {
				ForEach(budgets, id: \.self) { budget in
					NavigationLink(
						destination: Text("Stub")
						//						BudgetView(budget: budget)
					) {
						Text(budget.name)
					}
				}
				.onDelete { indexSet in
					for index in indexSet {
						self.managedObjectContext.delete(self.budgets[index])
					}
				}
			}
			.navigationBarTitle(Text("Budget List"), displayMode: .inline)
		}
	}
}

struct MainView_Previews: PreviewProvider {
	static var previews: some View {
		MainView()
			.environment(\.managedObjectContext, masterContext!)
		//			.environmentObject(UserData.sample)
	}
}

