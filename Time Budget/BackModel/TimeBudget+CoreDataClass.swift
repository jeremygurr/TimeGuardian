//
//  TimeBudget+CoreDataClass.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/10/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//
//

import Foundation
import CoreData
import SwiftUI

@objc(TimeBudget)
public class TimeBudget: NSManagedObject, Identifiable {
	
	func save() {
		debugLog("save budget called")
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
	
	@nonobjc public class func fetchRequestMain() -> FetchRequest<TimeBudget> {
		let request = FetchRequest<TimeBudget>(
			entity: TimeBudget.entity(),
			sortDescriptors: [
				NSSortDescriptor(keyPath: \TimeBudget.order, ascending: true)
			],
			predicate: NSPredicate(format: "superFund.@count == 0")
		)
		
		return request
	}
	
	@nonobjc public class func fetchRequestSub() -> FetchRequest<TimeBudget> {
		let request = FetchRequest<TimeBudget>(
			entity: TimeBudget.entity(),
			sortDescriptors: [
				NSSortDescriptor(keyPath: \TimeBudget.name, ascending: true)
			],
			predicate: NSPredicate(format: "superFund.@count > 0")
		)
		
		return request
	}
	
	@nonobjc public class func fetchRequest(name: String) -> NSFetchRequest<TimeBudget> {
		let request: NSFetchRequest<TimeBudget> = TimeBudget.fetchRequest()
		request.predicate = NSPredicate(format: "name == %@", name)
		return request
	}

	func allFundsSpent() -> Bool {
		if funds == nil {
			return false
		}

		var spent = true
		var allFrozen = true
		
		for f in funds! {
			let fund = f as! TimeFund
			if !fund.frozen {
				if fund.balance >= 1 {
					spent = false
					break
				}
				
				allFrozen = false
			}
		}
		
		if allFrozen {
			spent = false
		}
		
		return spent
	}

	func rechargeFunds() {
		if funds == nil {
			return
		}

		for f in funds! {
			let fund = f as! TimeFund
			fund.adjustBalance(fund.recharge)
		}
	}
	
	// add to the balance of all funds in this budget if all have a balance of less than 1
	func rechargeIfSpent() {
		if funds == nil {
			return
		}
		
		while allFundsSpent() {
			rechargeFunds()
		}
	}
	
	func balancedSpend(fundName: String) {
		debugLog("TimeBudget.balancedSpend(\(fundName))")
		if let funds = funds?.allObjects as! [TimeFund]? {
			var highestFund: TimeFund? = nil
			var highestAmount: Float = -9999999

			for fund in funds {
				if fund.name == fundName && fund.balance > highestAmount {
					highestFund = fund
					highestAmount = fund.balance
				}
			}

			if let fund = highestFund {
				fund.adjustBalance(-1)
			}

		}
	}
	
}
