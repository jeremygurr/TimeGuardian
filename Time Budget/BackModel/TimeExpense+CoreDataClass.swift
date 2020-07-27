//
//  TimeExpense+CoreDataClass.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 7/27/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//
//

import Foundation
import CoreData
import SwiftUI

@objc(TimeExpense)
public class TimeExpense: NSManagedObject {
	
	@nonobjc public class func fetchRequestFor(date: Date) -> FetchRequest<TimeExpense> {
		let request = FetchRequest<TimeExpense>(
			entity: TimeExpense.entity(),
			sortDescriptors: [
				NSSortDescriptor(keyPath: \TimeExpense.timeSlot, ascending: true)
			],
			predicate: NSPredicate(format: "when == %@", getStartOfDay(of: date) as NSDate)
		)
		
		return request
	}

}
