//
//  Budgets.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/11/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation
import SwiftUI
import CoreData

class FrontModel: ObservableObject {
	
	@FetchRequest(
		entity: TimeBudget.entity(),
		sortDescriptors: [
			NSSortDescriptor(keyPath: \TimeBudget.name, ascending: true),
		]
	) private var currentBudgetList: FetchedResults<TimeBudget>
	
	@Published var budgetList: [TimeBudget] = []
	
	func load() throws {
		// We should not need to specify the type here, probably a bug
		let request: NSFetchRequest<TimeBudget> = TimeBudget.fetchRequest()
		
		let budgets = try masterContext?.fetch(request)
		
		var result: [TimeBudget] = []
		for budget in budgets! {
			result.append(budget)
		}
		budgetList = result
	}
	
}
