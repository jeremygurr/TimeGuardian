//
//  TimeFund+CoreDataClass.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/10/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//
//

import Foundation
import CoreData
import SwiftUI

@objc(TimeFund)
public class TimeFund: NSManagedObject, Identifiable {
	
	func save() {
		debugLog("save fund called")
		if(hasChanges) {
			do {
				debugLog("has changes, call save on context")
				try managedObjectContext?.save()
			} catch {
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}
	
	@nonobjc public class func fetchAllRequest(budget: TimeBudget) -> FetchRequest<TimeFund> {
		let request = FetchRequest<TimeFund>(
			entity: TimeFund.entity(),
			sortDescriptors: [
				NSSortDescriptor(keyPath: \TimeFund.order, ascending: true)
			],
			predicate: NSPredicate(format: "budget == %@", budget)
		)
		
		return request
	}
	
	@nonobjc public class func fetchAvailableRequest(budget: TimeBudget) -> FetchRequest<TimeFund> {
		let request = FetchRequest<TimeFund>(
			entity: TimeFund.entity(),
			sortDescriptors: [
				NSSortDescriptor(keyPath: \TimeFund.order, ascending: true)
			],
			predicate: NSPredicate(format: "budget == %@ AND balance > 0", budget)
		)
		
		return request
	}
	
	@nonobjc public class func fetchSpentRequest(budget: TimeBudget) -> FetchRequest<TimeFund> {
		let request = FetchRequest<TimeFund>(
			entity: TimeFund.entity(),
			sortDescriptors: [
				NSSortDescriptor(keyPath: \TimeFund.order, ascending: true)
			],
			predicate: NSPredicate(format: "budget == %@ AND balance <= 0", budget)
		)
		
		return request
	}
	
	@nonobjc public class func fetchRequest(name: String) -> FetchRequest<TimeFund> {
		let request = FetchRequest<TimeFund>(
			entity: TimeFund.entity(),
			sortDescriptors: [
				NSSortDescriptor(keyPath: \TimeFund.order, ascending: true)
			],
			predicate: NSPredicate(format: "name == %@", name)
		)
		
		return request
	}
	
	func deepSpend(budgetStack: BudgetStack) {
		adjustBalance(-1)
		budget.earnIfSpent()
		for f in budgetStack.getFunds().reversed() {
			f.adjustBalance(-1)
			f.budget.earnIfSpent()
		}
	}
	
	func adjustBalance(_ amount: Float) {
		self.balance += amount
		if self.balance < -0.5 && amount < 0 {
			// charge interest on time debt
			self.balance *= 1.1
		}
	}
	
	func resetBalance() {
		self.balance = 1
	}
	
	public var roundedBalance: Int {
		return Int(balance.rounded(.up))
	}
	
	func getRatio() -> Float {
		var result: Float = 0
		if let funds = self.budget.funds {
			var totalFunds: Float = 0.0
			var fundsWithSameName: Float = 0.0
			for fund in funds {
				totalFunds += 1
				if (fund as! TimeFund).name == self.name {
					fundsWithSameName += 1
				}
			}
			result = fundsWithSameName / totalFunds
		}
		return result
	}
	

}
