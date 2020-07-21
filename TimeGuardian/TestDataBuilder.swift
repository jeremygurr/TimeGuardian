//
//  UserData.swift
//  Time Guardian
//
//  Created by Jeremy Gurr on 7/6/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import CoreData

class TestDataBuilder {
	let context: NSManagedObjectContext
	var budgets: [TimeBudget] = []
	var funds: [TimeFund] = []

	init(context: NSManagedObjectContext) {
		self.context = context
	}
	
	func save() {
		if context.hasChanges {
			do {
				try context.save()
			} catch {
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}
	
	func createTestData() {
		debugLog("Creating test data")
		deleteExistingData()
		_ = createBudget(name: "Main")
		_ = createBudget(name: "Home")
		_ = createBudget(name: "Play")
		_ = createBudget(name: "Sunday")
		let mainBudget = self.budgets[0]
		_ = createFund(budget: mainBudget, name: "rest")
		_ = createFund(budget: mainBudget, name: "play")
		_ = createFund(budget: mainBudget, name: "exercise")
		let homeBudget = self.budgets[1]
		_ = createFund(budget: homeBudget, name: "short", subBudget: true)
		_ = createFund(budget: homeBudget, name: "medium length fund", subBudget: true)
		_ = createFund(budget: homeBudget, name: "long fund name that is so descriptive of what needs to happen", subBudget: true)
		save()
	}
	
	func deleteExistingData() {
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "TimeBudget")
		let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
		
		do {
			try context.execute(batchDeleteRequest)
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
		}
	}
	
	func createFund(budget: TimeBudget, name: String, subBudget: Bool = false) -> TimeFund {
		let fund = TimeFund(context: context)
		fund.budget = budget
		fund.name = name
		funds.append(fund)
		if subBudget {
			fund.subBudget = createBudget(name: name)
		}
		return fund
	}

	func createBudget(name: String) -> TimeBudget {
		let budget = TimeBudget(context: context)
		budget.name = name
		budget.order = Int16(budgets.count)
		budgets.append(budget)
		return budget
	}
}
