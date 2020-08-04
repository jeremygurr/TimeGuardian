//
//  BudgetStack.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/19/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation
import SwiftUI

struct BudgetStack: Equatable {
	
	private var budgetStack: [TimeBudget] = []
	// fundStack will typically be one element shorter than budgetStack,
	//   unless budgetStack is empty
	private var fundStack: [TimeFund] = []
	private var fundRatioStack: [Float] = []
	
	init() {
		debugLog("BudgetStack.init")
	}

	func getBudgets() -> [TimeBudget] {
		return budgetStack
	}
	
	func getFunds() -> [TimeFund] {
		return fundStack
	}
	
	func isEmpty() -> Bool {
		return budgetStack.count == 0
	}
	
	mutating func push(budget: TimeBudget) {
		debugLog("budgetStack.push budget \(budget.name)")
		budgetStack.append(budget)
		debugLog("budgetStack has \(budgetStack.count) items")
	}
	
	mutating func push(fund: TimeFund) {
		debugLog("budgetStack.push fund \(fund.name)")
		let ratio = fund.getRatio()
		fundStack.append(fund)
		fundRatioStack.append(ratio)
		debugLog("fundStack has \(fundStack.count) items")
	}
	
	mutating func removeLastBudget() {
		debugLog("budgetStack.removeLastBudget")
		if budgetStack.count > 0 {
			budgetStack.removeLast()
		}
	}
	
	mutating func removeLastFund() {
		debugLog("budgetStack.removeLastFund")
		if fundStack.count > 0 {
			fundStack.removeLast()
			fundRatioStack.removeLast()
		}
	}
	
	mutating func toFirstBudget() {
		debugLog("budgetStack.toFirstBudget")
		fundStack.removeAll()
		fundRatioStack.removeAll()
		var s = budgetStack
		while s.count > 1 {
			s.removeLast()
		}
		budgetStack = s
	}
	
	func hasTopBudget() -> Bool {
		return budgetStack.last != nil
	}
	
  // should never get called if the stack is empty
	func getTopBudget() -> TimeBudget {
		return budgetStack.last!
	}
	
	func getCurrentRatio() -> Float {
		var p: Float = 1
		for r in fundRatioStack {
			p *= r
		}
		return p
	}
}

