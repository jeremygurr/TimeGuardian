//
//  NewFundRowView.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 7/31/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI

struct NewFundRowView: View {
	@Binding var budgetStack: BudgetStack
	@State var newFundName: String = ""
	var funds: FetchedResults<TimeFund>
	let posOfNewFund: ListPosition
	
	var body: some View {
		HStack {
			TextField("New Fund", text: self.$newFundName)
			Button(action: {
				self.newFundName = self.newFundName.trimmingCharacters(in: .whitespacesAndNewlines)
				
				if self.newFundName.count > 0 {
					let fund = TimeFund(context: managedObjectContext)
					fund.name = self.newFundName
					fund.budget = self.budgetStack.getTopBudget()
					var index = 0
					
					if self.posOfNewFund == .before {
						fund.order = 0
						index += 1
					}
					
					for i in 0 ..< self.funds.count {
						self.funds[i].order = Int16(i + index)
					}
					
					index += self.funds.count
					
					if self.posOfNewFund == .after {
						fund.order = Int16(index)
						index += 1
					}
					
					saveData()
					self.newFundName = ""
				}
			}) {
				Image(systemName: "plus.circle.fill")
					.foregroundColor(.green)
					.imageScale(.large)
			}
		}
	}
}

