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
	
	// add to the balance of all funds in this budget if all have a balance of less than 1
	func earnIfSpent() {
		if funds == nil {
			return
		}
		var minBelowOne: Float = 9999999
		var allFundsSpent = true
		for fund in funds! {
			let belowOne = rechargeLevel - (fund as! TimeFund).balance
			if belowOne < 0 {
				allFundsSpent = false
				break
			}
			if belowOne < minBelowOne {
				minBelowOne = belowOne
			}
		}
		if allFundsSpent {
			for fund in funds! {
				(fund as! TimeFund).balance += minBelowOne
			}
		}
	}
	
}
