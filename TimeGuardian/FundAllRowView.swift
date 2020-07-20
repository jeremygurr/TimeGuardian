//
//  FundAllRowView.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/19/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation
import SwiftUI

struct FundAllRowView: View {
	var allFunds: FetchedResults<TimeFund>
	@Binding var action: FundAction
	@Environment(\.managedObjectContext) var managedObjectContext
	var allFundBalance: Int {
		return self.allFunds.count
	}
	
	var body: some View {
		Section() {
			Button(action: {
				switch self.action {
					case .spend:
						for fund in self.allFunds {
							fund.adjustBalance(-1)
					}
					case .reset:
						for fund in self.allFunds {
							fund.resetBalance()
					}
					case .earn:
						for fund in self.allFunds {
							fund.adjustBalance(1)
					}
					case .subBudget:
						debugLog("Can't create subBudget on all")
					case .clone:
						debugLog("Can't clone all")
					case .edit:
						debugLog("Can't edit all")
					case .delete:
						for fund in self.allFunds {
							self.managedObjectContext.delete(fund)
					}
				}
				saveData(self.managedObjectContext)
			}, label: {
				HStack {
					Text("\(allFundBalance)")
						.frame(width: 40, alignment: .trailing)
					Divider()
					Text("All Funds")
						.fontWeight(.heavy)
						.frame(minWidth: 20, maxWidth: .infinity, alignment: .leading)
				}
			})
		}
	}
}

struct FundAllSpentRowView: View {
	var spentFunds: FetchedResults<TimeFund>
	@Binding var action: FundAction
	@Environment(\.managedObjectContext) var managedObjectContext
	var allSpentFundBalance: Int {
		return self.spentFunds.count
	}
	
	var body: some View {
		Section() {
			Button(action: {
				switch self.action {
					case .spend:
						for fund in self.spentFunds {
							fund.adjustBalance(-1)
					}
					case .reset:
						for fund in self.spentFunds {
							fund.resetBalance()
					}
					case .earn:
						for fund in self.spentFunds {
							fund.adjustBalance(1)
					}
					case .subBudget:
						debugLog("Can't create subBudget on all")
					case .clone:
						debugLog("Can't clone all")
					case .edit:
						debugLog("Can't edit all")
					case .delete:
						for fund in self.spentFunds {
							self.managedObjectContext.delete(fund)
					}
				}
				saveData(self.managedObjectContext)
			}, label: {
				HStack {
					Text("\(allSpentFundBalance)")
						.frame(width: 40, alignment: .trailing)
					Divider()
					Text("All Spent Funds")
						.fontWeight(.heavy)
						.frame(minWidth: 20, maxWidth: .infinity, alignment: .leading)
				}
			})
		}
	}
}
