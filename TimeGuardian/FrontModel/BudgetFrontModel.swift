//
//  Budgets.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/11/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData

class BudgetFrontModel: ObservableObject {

	let dataContext: NSManagedObjectContext
	
	init(dataContext: NSManagedObjectContext) throws {
		self.dataContext = dataContext
		TestDataBuilder(context: dataContext).createTestData()
		try load()
	}
	
	func deleteBudget(index: Int) {
		dataContext.delete(budgetList[index])
		budgetList.remove(at: index)
	}
	
	func moveBudget(fromOffsets: IndexSet, toOffset: Int) {
		budgetList.move(fromOffsets: fromOffsets, toOffset: toOffset)
		for (index, budget) in budgetList.enumerated() {
			budget.order = Int16(index)
		}
	}

	@Published var budgetList: [TimeBudget] = []
	
	func load() throws {
		// We should not need to specify the type here, probably a bug
		let request: NSFetchRequest<TimeBudget> = TimeBudget.fetchRequest()
		request.sortDescriptors = [
			NSSortDescriptor(keyPath: \TimeBudget.order, ascending: true),
			NSSortDescriptor(keyPath: \TimeBudget.name, ascending: true),
		]
		
		budgetList = try dataContext.fetch(request)
	}
	
}
