//
//  TimeFund+CoreDataProperties.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 8/1/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//
//

import Foundation
import CoreData

extension TimeFund {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimeFund> {
        return NSFetchRequest<TimeFund>(entityName: "TimeFund")
    }

    @NSManaged public var balance: Float
    @NSManaged public var frozen: Bool
    @NSManaged public var name: String
    @NSManaged public var order: Int16
    @NSManaged public var recharge: Float
    @NSManaged public var budget: TimeBudget
    @NSManaged public var expenses: NSSet?
    @NSManaged public var subBudget: TimeBudget?

}

// MARK: Generated accessors for expenses
extension TimeFund {

    @objc(addExpensesObject:)
    @NSManaged public func addToExpenses(_ value: TimeExpense)

    @objc(removeExpensesObject:)
    @NSManaged public func removeFromExpenses(_ value: TimeExpense)

    @objc(addExpenses:)
    @NSManaged public func addToExpenses(_ values: NSSet)

    @objc(removeExpenses:)
    @NSManaged public func removeFromExpenses(_ values: NSSet)

}
