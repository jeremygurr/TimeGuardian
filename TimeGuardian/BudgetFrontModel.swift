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
	@Published var fundList: [TimeFund] = []
	
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
	
	func deleteBudget(budget: TimeBudget) {
		var indexFound = -1
		
		for (i, b) in budgetList.enumerated() {
			if b == budget {
				indexFound = i
			}
		}

		if indexFound > -1 {
			deleteBudget(index: indexFound)
		}
	}
	
	func deleteFund(index: Int) {
		dataContext.delete(fundList[index])
		fundList.remove(at: index)
	}
	
	func deleteFund(fund: TimeFund) {
		var indexFound = -1
		
		for (i, b) in fundList.enumerated() {
			if b == fund {
				indexFound = i
			}
		}
		
		if indexFound > -1 {
			deleteFund(index: indexFound)
		}
	}
	
	func moveBudget(fromOffsets: IndexSet, toOffset: Int) {
		budgetList.move(fromOffsets: fromOffsets, toOffset: toOffset)
		for (index, budget) in budgetList.enumerated() {
			budget.order = Int16(index)
		}
	}

	func moveFund(fromOffsets: IndexSet, toOffset: Int) {
		fundList.move(fromOffsets: fromOffsets, toOffset: toOffset)
		for (index, fund) in fundList.enumerated() {
			fund.order = Int16(index)
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
	
	func addFund(budget: TimeBudget) throws -> TimeFund {
		debugLog("addFund called")
		let fund = TimeFund(context: dataContext)
		fund.name = ""
		fund.order = Int16(fundList.count)
		fund.budget = budget
		dataContext.insert(fund)
		try dataContext.save()
		fundList.append(fund)
		return fund
	}
	
	func getFunds(budget: TimeBudget) -> [TimeFund] {
		var result: [TimeFund] = []
		
		if let fundSet = budget.funds,
			let funds = fundSet.allObjects as? [TimeFund] {
			result = funds
		}

		fundList = result
		return result
	}
	
	func hasSubBudget(fund: TimeFund) -> Bool {
		return false
	}
	
	func adjustBalance(fund: TimeFund, amount: Int) {
		
	}
	
	func zeroBalance(fund: TimeFund) {
		
	}
	
}
