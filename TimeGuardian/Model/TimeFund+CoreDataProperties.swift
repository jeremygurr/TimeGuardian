//
//  TimeFund+CoreDataProperties.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/10/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//
//

import Foundation
import CoreData


extension TimeFund {
	
	@nonobjc public class func fetchRequest() -> NSFetchRequest<TimeFund> {
		return NSFetchRequest<TimeFund>(entityName: "TimeFund")
	}
	
	@NSManaged public var balance: Int16
	@NSManaged public var name: String
	@NSManaged public var budget: TimeBudget
	@NSManaged public var order: Int16
	@NSManaged public var subBudget: TimeBudget?
	
}
