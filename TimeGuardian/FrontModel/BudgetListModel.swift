//
//  BudgetListModel.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/16/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation
import CoreData

class BudgetListModel: ObservableObject {
	let dataContext: NSManagedObjectContext
	@Published var budgetList: [TimeBudget] = []
	
	init(dataContext: NSManagedObjectContext) {
		self.dataContext = dataContext
		do {
			try load()
		} catch {
			errorLog("\(error)")
		}
	}
	
	func load() throws {
		// We should not need to specify the type here, probably a bug
		let request: NSFetchRequest<TimeBudget> = TimeBudget.fetchRequest()
		request.sortDescriptors = [
			NSSortDescriptor(keyPath: \TimeBudget.order, ascending: true),
		]
		
		budgetList = try dataContext.fetch(request)		
	}
	

}
