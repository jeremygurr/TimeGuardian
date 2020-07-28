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
	
	@nonobjc class func fetchRequestFor(startDate: Date, endDate: Date) -> FetchRequest<TimeExpense> {
		
		let request = FetchRequest<TimeExpense>(
			entity: TimeExpense.entity(),
			sortDescriptors: [
				NSSortDescriptor(keyPath: \TimeExpense.timeSlot, ascending: true)
			],
			predicate: NSPredicate(format: "when >= %@ AND when <= %@", startDate as NSDate, endDate as NSDate)
		)
		
		return request
		
	}

	@nonobjc class func fetchRequestFor(timeSlot: TimeSlot) -> NSFetchRequest<TimeExpense> {
		
		let request = NSFetchRequest<TimeExpense>(entityName: "TimeExpense")
		request.sortDescriptors = [ NSSortDescriptor(keyPath: \TimeExpense.timeSlot, ascending: true) ]
		request.predicate = NSPredicate(format: "when == %@ AND timeSlot == '%@'", timeSlot.baseDate as NSDate, Int16(timeSlot.slotIndex))

		return request
		
	}
	
}

func addExpense(timeSlot: TimeSlot, fund: TimeFund, budgetStack: BudgetStack, managedObjectContext: NSManagedObjectContext) {
	
	let expense = TimeExpense(context: managedObjectContext)
	expense.fund = fund
	expense.timeSlot = Int16(timeSlot.slotIndex)
	var pathString = ""
	
	for b in budgetStack.getBudgets() {
		if pathString.count > 0 {
			pathString.append(space)
		}
		pathString.append(contentsOf: "\(b.name)")
	}
	
	expense.path = pathString
	expense.when = timeSlot.baseDate
	fund.deepSpend(budgetStack: budgetStack)
	
}

func getTimeSlotOfCurrentTime(calendarSettings: CalendarSettings) -> TimeSlot {
	let now = Date()
	let startOfDay = getStartOfDay()
	let difference = startOfDay.distance(to: now)
	let itemIndex = Int(difference / 60 / calendarSettings.expensePeriod)
	return TimeSlot(baseDate: startOfDay, slotIndex: itemIndex, slotSize: calendarSettings.expensePeriod)
}

func addExpenseToCurrentTimeIfEmpty(fund: TimeFund, budgetStack: BudgetStack, calendarSettings: CalendarSettings, managedObjectContext: NSManagedObjectContext) {
	let slot = getTimeSlotOfCurrentTime(calendarSettings: calendarSettings)
	let request = TimeExpense.fetchRequestFor(timeSlot: slot)
	
	do {
		let expenses = try managedObjectContext.fetch(request)
		if expenses.first == nil {
			addExpense(timeSlot: slot, fund: fund, budgetStack: budgetStack, managedObjectContext: managedObjectContext)
		} else {
			fund.deepSpend(budgetStack: budgetStack)
		}
	} catch {
		errorLog("Error fetching expense: fund = \(fund.name), \(error)")
	}

}
