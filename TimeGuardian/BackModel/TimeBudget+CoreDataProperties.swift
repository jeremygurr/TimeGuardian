//
//  TimeBudget+CoreDataProperties.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/18/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//
//

import Foundation
import CoreData
import SwiftUI

extension TimeBudget {
	
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
	
	@nonobjc public class func fetchRequest() -> NSFetchRequest<TimeBudget> {
		return NSFetchRequest<TimeBudget>(entityName: "TimeBudget")
	}
	
	@NSManaged public var name: String
	@NSManaged public var order: Int16
	@NSManaged public var funds: NSSet?
	@NSManaged public var superFund: NSSet?
	
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

// MARK: Generated accessors for superFund
extension TimeBudget {
	
	@objc(addSuperFundObject:)
	@NSManaged public func addToSuperFund(_ value: TimeFund)
	
	@objc(removeSuperFundObject:)
	@NSManaged public func removeFromSuperFund(_ value: TimeFund)
	
	@objc(addSuperFund:)
	@NSManaged public func addToSuperFund(_ values: NSSet)
	
	@objc(removeSuperFund:)
	@NSManaged public func removeFromSuperFund(_ values: NSSet)
	
}
