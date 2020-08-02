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
	
//	public override var description: String {
//		return "TimeFund: { name: \(name), balance: \(balance), budget: \(budget) }"
//	}

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
				NSSortDescriptor(keyPath: \TimeFund.balance, ascending: false),
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
				NSSortDescriptor(keyPath: \TimeFund.balance, ascending: false),
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
				NSSortDescriptor(keyPath: \TimeFund.balance, ascending: false),
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
	
	@nonobjc public class func fetchRequest(budgetName: String, fundName: String) -> NSFetchRequest<TimeFund> {
		let request = NSFetchRequest<TimeFund>(entityName: "TimeFund")
		request.sortDescriptors = [ NSSortDescriptor(keyPath: \TimeFund.order, ascending: true) ]
		request.predicate = NSPredicate(format: "name == %@ AND budget.name == %@", fundName, budgetName)
		return request
	}
	
	func balancedSpend() {
		budget.balancedSpend(fundName: name)
	}
	
	func deepSpend(budgetStack: BudgetStack) {
		debugLog("deepSpend on \(self.name)")
		
		balancedSpend()
		budget.rechargeIfSpent()
		for f in budgetStack.getFunds().reversed() {
			f.balancedSpend()
			if !f.frozen {
				f.budget.rechargeIfSpent()
			}
		}
	}
	
	func adjustBalance(_ amount: Float) {
		debugLog("adjustBalance on \(self.name) amount: \(amount)")
		if !frozen {
			balance += amount
			if balance < interestThreshold && amount < 0 {
				// charge interest on time debt
				balance *= 1.1
			}
		} else {
			debugLog("fund \(self.name) is frozen")
		}
		debugLog("new balance on \(self.name) is: \(balance)")
	}
	
	func resetBalance() {
		debugLog("resetBalance on \(self.name)")
		if !frozen {
			balance = recharge
		}
	}
	
	public var roundedBalance: Int {
		return Int(balance.rounded(.up))
	}
	
	func getRatio() -> Float {
		var result: Float = 0
		if let funds = self.budget.funds {
			var totalFunds: Float = 0.0
			var fundsWithSameName: Float = 0.0
			for f in funds {
				let fund = f as! TimeFund
				totalFunds += fund.recharge
				if fund.name == self.name {
					fundsWithSameName += fund.recharge
				}
			}
			result = fundsWithSameName / totalFunds
		}
		return result
	}
	
}
