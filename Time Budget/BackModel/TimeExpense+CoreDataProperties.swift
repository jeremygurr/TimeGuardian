//
//  TimeExpense+CoreDataProperties.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 7/27/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//
//

import Foundation
import CoreData


extension TimeExpense {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TimeExpense> {
        return NSFetchRequest<TimeExpense>(entityName: "TimeExpense")
    }

    @NSManaged public var when: Date
    @NSManaged public var timeSlot: Int16
    @NSManaged public var path: String
    @NSManaged public var fund: TimeFund

}
