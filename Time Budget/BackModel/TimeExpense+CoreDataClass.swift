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
				NSSortDescriptor(keyPath: \TimeExpense.when, ascending: true),
				NSSortDescriptor(keyPath: \TimeExpense.timeSlot, ascending: true)
			],
			predicate: NSPredicate(format: "when >= %@ AND when <= %@", startDate as NSDate, endDate as NSDate)
		)
		
		return request
		
	}

	@nonobjc class func fetchRequestFor(timeSlot: TimeSlot) -> NSFetchRequest<TimeExpense> {
		
		let request = NSFetchRequest<TimeExpense>(entityName: "TimeExpense")
		request.sortDescriptors = [ NSSortDescriptor(keyPath: \TimeExpense.timeSlot, ascending: true) ]
		request.predicate = NSPredicate(format: "when == %@ AND timeSlot == %@", timeSlot.baseDate as NSDate, timeSlot.slotIndex as NSNumber)

		return request
		
	}
	
//	public override var description: String {
//		return "TimeExpense: { fund: \(fund), when: \(when), timeSlot: \(timeSlot), path: \(path) }"
//	}
	
}

func addExpense(timeSlot: TimeSlot, fund: TimeFund, budgetStack: BudgetStack, managedObjectContext: NSManagedObjectContext) {
	debugLog("addExpense: { timeSlot: \(timeSlot), fund: \(fund) }")

	let expense = TimeExpense(context: managedObjectContext)
	expense.fund = fund
	expense.timeSlot = Int16(timeSlot.slotIndex)
	var pathString = ""
	
	for b in budgetStack.getBudgets() {
		if pathString.count > 0 {
			pathString.append(newline)
		}
		pathString.append(contentsOf: "\(b.name)")
	}
	
	expense.path = pathString
	expense.when = timeSlot.baseDate
	fund.deepSpend(budgetStack: budgetStack)
	
}

func getTimeSlotOfCurrentTime(expensePeriod: TimeInterval) -> TimeSlot {
	let now = Date()
	let startOfDay = getStartOfDay()
	let difference = startOfDay.distance(to: now)
	let itemIndex = Int(difference / 60 / expensePeriod)
	return TimeSlot(baseDate: startOfDay, slotIndex: itemIndex, slotSize: expensePeriod)
}

func addExpenseToCurrentTimeIfEmpty(fund: TimeFund, budgetStack: BudgetStack, expensePeriod: TimeInterval, managedObjectContext: NSManagedObjectContext) {
	let slot = getTimeSlotOfCurrentTime(expensePeriod: expensePeriod)
	let request = TimeExpense.fetchRequestFor(timeSlot: slot)
	
	do {
		let expenses = try managedObjectContext.fetch(request)
		let firstExpense: TimeExpense? = expenses.first
		if firstExpense == nil {
			debugLog("No expense found for this slot, so we will create one")
			addExpense(timeSlot: slot, fund: fund, budgetStack: budgetStack, managedObjectContext: managedObjectContext)
		} else {
			fund.deepSpend(budgetStack: budgetStack)
		}
	} catch {
		errorLog("Error fetching expense: fund = \(fund.name), \(error)")
	}

}
