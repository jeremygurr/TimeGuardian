//
//  BudgetStack.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/19/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation

class BudgetStack: ObservableObject {
	@Published private var budgetStack: [TimeBudget] = []
	// fundStack will typically be one element shorter than budgetStack,
	//   unless budgetStack is empty
	@Published private var fundStack: [TimeFund] = []

	func getBudgets() -> [TimeBudget] {
		return budgetStack
	}
	
	func getFunds() -> [TimeFund] {
		return fundStack
	}
	
	func isEmpty() -> Bool {
		return budgetStack.count == 0
	}
	
	func push(budget: TimeBudget) {
		budgetStack.append(budget)
	}
	
	func push(fund: TimeFund) {
		fundStack.append(fund)
	}
	
	func removeLastBudget() {
		if budgetStack.count > 0 {
			budgetStack.removeLast()
		}
	}
	
	func removeLastFund() {
		if fundStack.count > 0 {
			fundStack.removeLast()
		}
	}
	
	func toTopBudget() {
		fundStack.removeAll()
		var s = budgetStack
		while s.count > 1 {
			s.removeLast()
		}
		budgetStack = s
	}
	
	func getTopBudget() -> TimeBudget {
		return budgetStack.last!
	}
}
