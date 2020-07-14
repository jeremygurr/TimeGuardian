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
	@Published var budgetList: [TimeBudget] = []
	
	init(dataContext: NSManagedObjectContext, testData: TestDataBuilder? = nil) throws {
		self.dataContext = dataContext
		try load()
		if let t = testData {
			t.createTestData()
		}
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

	func load() throws {
		// We should not need to specify the type here, probably a bug
		let request: NSFetchRequest<TimeBudget> = TimeBudget.fetchRequest()
		request.sortDescriptors = [
			NSSortDescriptor(keyPath: \TimeBudget.order, ascending: true),
			NSSortDescriptor(keyPath: \TimeBudget.name, ascending: true),
		]
		
		budgetList = try dataContext.fetch(request)
		
	}
	
	func addBudget() throws -> TimeBudget {
		debugLog("addBudget called")
		let budget = TimeBudget(context: dataContext)
		budget.name = ""
		budget.order = Int16(budgetList.count)
		dataContext.insert(budget)
		try dataContext.save()
		budgetList.append(budget)
		return budget
	}
	
	func getFunds(budget: TimeBudget) -> [TimeFund] {
		guard let fundSet = budget.funds,
			let funds = fundSet.allObjects as? [TimeFund]
			else {
				return []
		}
		return funds
	}
	
	func hasSubBudget(fund: TimeFund) -> Bool {
		return false
	}
	
	func adjustBalance(fund: TimeFund, amount: Int) {
		
	}
	
	func zeroBalance(fund: TimeFund) {
		
	}
	
}
