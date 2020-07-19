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
		createBudget(name: "Main")
		createBudget(name: "Home")
		createBudget(name: "Play")
		createBudget(name: "Sunday")
		let budget = self.budgets[0]
		createFund(budget: budget, name: "rest")
		createFund(budget: budget, name: "play")
		createFund(budget: budget, name: "exercise")
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
	
	func createFund(budget: TimeBudget, name: String) {
		let fund = TimeFund(context: context)
		fund.budget = budget
		fund.name = name
		funds.append(fund)
	}

	func createBudget(name: String) {
		let budget = TimeBudget(context: context)
		budget.name = name
		budgets.append(budget)
	}
}
