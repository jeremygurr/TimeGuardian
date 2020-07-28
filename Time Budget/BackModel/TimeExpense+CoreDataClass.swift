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

	@nonobjc public class func fetchRequestFor(date: Date, period: Int) -> NSFetchRequest<TimeExpense> {
		
		let request = NSFetchRequest<TimeExpense>(entityName: "TimeExpense")
		request.sortDescriptors = [ NSSortDescriptor(keyPath: \TimeExpense.timeSlot, ascending: true) ]
		request.predicate = NSPredicate(format: "when == %@ AND timeSlot == '%@'", getStartOfDay(of: date) as NSDate, Int16(period))

		return request
		
	}
	
}

func addExpense(period: Int, fund: TimeFund, budgetStack: BudgetStack, managedObjectContext: NSManagedObjectContext) {
	
	let expense = TimeExpense(context: managedObjectContext)
	expense.fund = fund
	expense.timeSlot = Int16(period)
	var pathString = ""
	
	for b in budgetStack.getBudgets() {
		if pathString.count > 0 {
			pathString.append(space)
		}
		pathString.append(contentsOf: "\(b.name)")
	}
	
	expense.path = pathString
	expense.when = getStartOfDay()
	fund.deepSpend(budgetStack: budgetStack)
	
}

func getItemIndexOfCurrentTime(calendarSettings: CalendarSettings) -> Int {
	let now = Date()
	let startOfDay = getStartOfDay()
	let difference = Int(startOfDay.distance(to: now))
	let itemIndex = difference / 60 / calendarSettings.expensePeriod
	return itemIndex
}

func addExpenseToCurrentTimeIfEmpty(fund: TimeFund, budgetStack: BudgetStack, calendarSettings: CalendarSettings, managedObjectContext: NSManagedObjectContext) {
	let period = getItemIndexOfCurrentTime(calendarSettings: calendarSettings)
	let request = TimeExpense.fetchRequestFor(date: Date(), period: period)
	
	do {
		let expenses = try managedObjectContext.fetch(request)
		if expenses.first == nil {
			addExpense(period: period, fund: fund, budgetStack: budgetStack, managedObjectContext: managedObjectContext)
		} else {
			fund.deepSpend(budgetStack: budgetStack)
		}
	} catch {
		errorLog("Error fetching expense: fund = \(fund.name), \(error)")
	}

}
