//
//  TimeBudget+CoreDataProperties.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/17/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//
//

import Foundation
import CoreData


extension TimeBudget {
	
	@nonobjc public class func sortedFetchRequest() -> NSFetchRequest<TimeBudget> {
		let request: NSFetchRequest<TimeBudget> = TimeBudget.fetchRequest()
		request.sortDescriptors = [
			NSSortDescriptor(keyPath: \TimeBudget.order, ascending: true)
		]
		return request
	}

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimeBudget> {
        return NSFetchRequest<TimeBudget>(entityName: "TimeBudget")
    }

    @NSManaged public var name: String
    @NSManaged public var order: Int16
    @NSManaged public var funds: NSSet?
    @NSManaged public var superFund: TimeFund?

}

// MARK: Generated accessors for funds
extension TimeBudget {

    @objc(addFundsObject:)
    @NSManaged public func addToFunds(_ value: TimeFund)

    @objc(removeFundsObject:)
    @NSManaged public func removeFromFunds(_ value: TimeFund)

    @objc(addFunds:)
    @NSManaged public func addToFunds(_ values: NSSet)

    @objc(removeFunds:)
    @NSManaged public func removeFromFunds(_ values: NSSet)

}
