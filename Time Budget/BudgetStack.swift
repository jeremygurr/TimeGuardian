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
	private var fundStack = FundPath(fundPath: [])
	private var fundRatioStack: [Float] = []
	
	init() {
		debugLog("BudgetStack.init")
	}

	func getBudgets() -> [TimeBudget] {
		return budgetStack
	}
	
	func getFunds() -> [TimeFund] {
		return fundStack.fundPath
	}
	
	func getFundPath() -> FundPath {
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
	
	func getTopFund() -> TimeFund? {
		return fundStack.last
	}
	
	func getCurrentRatio() -> Float {
		var p: Float = 1
		for r in fundRatioStack {
			p *= r
		}
		return p
	}
}

struct FundPath: Equatable, Sequence {

	var fundPath: [TimeFund]
	var count: Int {fundPath.count}
	var last: TimeFund? {fundPath.last}
	
	func makeIterator() -> IndexingIterator<[TimeFund]> {
		fundPath.makeIterator()
	}
	
	mutating func removeLast() {
		fundPath.removeLast()
	}
	
	mutating func removeAll() {
		fundPath.removeAll()
	}
	
	mutating func append(_ fund: TimeFund) {
		fundPath.append(fund)
	}
	
}
