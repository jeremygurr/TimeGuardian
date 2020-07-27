//
//  BudgetStack.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/19/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation
import SwiftUI

class BudgetStack: ObservableObject {
	
	@Published private var budgetStack: [TimeBudget] = []
	// fundStack will typically be one element shorter than budgetStack,
	//   unless budgetStack is empty
	@Published private var fundStack: [TimeFund] = []
	@Published var lastSelectedFund: TimeFund? = nil
	
	var titleOverride: String? = nil {
		willSet {
			objectWillChange.send()
		}
	}
	
	var actionDetail: String = "No action selected" {
		willSet {
			objectWillChange.send()
		}
	}
	
	private var fundRatioStack: [Float] = []
	
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
		let ratio = fund.getRatio()
		fundStack.append(fund)
		fundRatioStack.append(ratio)
	}
	
	func removeLastBudget() {
		if budgetStack.count > 0 {
			budgetStack.removeLast()
		}
	}
	
	func removeLastFund() {
		if fundStack.count > 0 {
			fundStack.removeLast()
			fundRatioStack.removeLast()
		}
	}
	
	func toFirstBudget() {
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
	
	func getTitle() -> String {
		var title: String
		if titleOverride != nil {
			title = titleOverride!
		} else {
			title = getTopBudget().name
		}
		return title
	}
	
	func getBudgetNameFontSize() -> CGFloat {
		let budgetNameSize = getTitle().count
		var size: CGFloat
		if budgetNameSize > 20 {
			size = 15
		} else if budgetNameSize > 10 {
			size = 20
		} else {
			size = 30
		}
		return size
	}
	
	func getCurrentRatio() -> Float {
		var p: Float = 1
		for r in fundRatioStack {
			p *= r
		}
		return p
	}
}

