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
	
	func push(budget: TimeBudget) -> BudgetStack {
		budgetStack.append(budget)
		return self
	}
	
	func push(fund: TimeFund) -> BudgetStack {
		fundStack.append(fund)
		return self
	}
	
	func removeLastBudget() -> BudgetStack {
		budgetStack.removeLast()
		return self
	}
	
	func removeLastFund() -> BudgetStack {
		fundStack.removeLast()
		return self
	}
	
	func getTopBudget() -> TimeBudget {
		return budgetStack.last!
	}
}
