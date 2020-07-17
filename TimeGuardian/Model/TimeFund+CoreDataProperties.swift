//
//  TimeFund+CoreDataProperties.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/17/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//
//

import Foundation
import CoreData
import SwiftUI

extension TimeFund {
	
	@nonobjc public class func fetchRequest() -> NSFetchRequest<TimeFund> {
		return NSFetchRequest<TimeFund>(entityName: "TimeFund")
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
	
	func adjustBalance(_ amount: Int) {
		self.balance += Int16(amount)
	}
	
	func resetBalance() {
		self.balance = 1
	}
	
    @NSManaged public var balance: Int16
    @NSManaged public var name: String
    @NSManaged public var order: Int16
    @NSManaged public var budget: TimeBudget?
    @NSManaged public var subBudget: TimeBudget?

}
