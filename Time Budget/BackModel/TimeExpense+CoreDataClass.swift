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
	
	var fundPath: FundPath {
		var fundPath: [TimeFund] = []
		var paths = path.split(separator: newline)

		if paths.count > 0 {
			paths.reverse()
			for i in 0 ..< paths.count - 1 {
				let fundName = String(paths[i])
				let budgetName = String(paths[i+1])
				let request = TimeFund.fetchRequest(budgetName: budgetName, fundName: fundName)
				
				do {
					let funds = try self.managedObjectContext?.fetch(request)
					if let fund = funds?.first {
						fundPath.append(fund)
					} else {
						errorLog("Missing fund: budgetName = \(budgetName), fundName = \(fundName)")
					}
				} catch {
					errorLog("Error fetching fund: budgetName = \(budgetName), fundName = \(fundName), \(error)")
				}

			}
		}
		
		return FundPath(fundPath: fundPath)
	}
	
}

func addExpense(timeSlot: TimeSlot, fundPath: FundPath, managedObjectContext: NSManagedObjectContext) {
	if let fund = fundPath.last {
		debugLog("addExpense: { timeSlot: \(timeSlot), fund: \(fund.name) }")
		
		let expense = TimeExpense(context: managedObjectContext)
		expense.fund = fund
		expense.timeSlot = Int16(timeSlot.slotIndex)
		var pathString = ""
		
		for f: TimeFund in fundPath {
			let b = f.budget
			if pathString.count > 0 {
				pathString.append(newline)
			}
			pathString.append(contentsOf: "\(b.name)")
		}
		
		expense.path = pathString
		expense.when = timeSlot.baseDate
		fund.deepSpend(fundPath: fundPath)
	}
}

func getTimeSlotOfCurrentTime(expensePeriod: TimeInterval) -> TimeSlot {
	let now = Date()
	let startOfDay = getStartOfDay()
	let difference = startOfDay.distance(to: now)
	let itemIndex = Int(difference / expensePeriod)
	return TimeSlot(baseDate: startOfDay, slotIndex: itemIndex, slotSize: expensePeriod)
}

func addExpenseToCurrentTimeIfEmpty(fundPath: FundPath, expensePeriod: TimeInterval, managedObjectContext: NSManagedObjectContext) {
	if let fund = fundPath.last {
		let slot = getTimeSlotOfCurrentTime(expensePeriod: expensePeriod)
		let request = TimeExpense.fetchRequestFor(timeSlot: slot)
		
		do {
			let expenses = try managedObjectContext.fetch(request)
			let firstExpense: TimeExpense? = expenses.first
			if firstExpense == nil {
				debugLog("No expense found for this slot, so we will create one")
				addExpense(timeSlot: slot, fundPath: fundPath, managedObjectContext: managedObjectContext)
			} else {
				fund.deepSpend(fundPath: fundPath)
			}
		} catch {
			errorLog("Error fetching expense: fund = \(fund.name), \(error)")
		}
	}
}
