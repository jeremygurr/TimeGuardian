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
	
	init(allFunds: FetchedResults<TimeFund>) {
		self.allFunds = allFunds
		_action = appState.$fundListAction
	}
	
	var allFundBalance: Int {
		return self.allFunds.count
	}
	
	var ratioString: String {
		let ratioString: String
		let budgetStack = appState.budgetStack
		
		var ratioSum : Float = 0
		var rechargeSum : Float = 0
		for fund in allFunds {
			if !fund.frozen {
				ratioSum += fund.getRatio()
				rechargeSum += fund.recharge
			}
		}
		
		let percentage = formatPercentage(ratioSum * budgetStack.getCurrentRatio())
		let longPeriod = appState.longPeriod
		let time = formatTime(TimeInterval(ratioSum * budgetStack.getCurrentRatio()) * longPeriod)
		let rechargeAmount = formatRecharge(rechargeSum)
		switch appState.ratioDisplayMode {
			case .percentage:
				ratioString = percentage
			case .timePerDay:
				ratioString = time
			case .rechargeAmount:
				ratioString = rechargeAmount
		}
		return ratioString
	}
	
	
	var body: some View {
		Section() {
			Button(action: {
				switch self.action {
					case .reset:
						for fund in self.allFunds {
							fund.resetBalance()
					}
					case .earn:
						for fund in self.allFunds {
							fund.earn()
					}
					case .delete:
						for fund in self.allFunds {
							managedObjectContext.delete(fund)
					}
					case .qspend:
						for fund in self.allFunds {
							fund.adjustBalance(-1)
					}
					case .freeze:
						for fund in self.allFunds {
							fund.frozen = !fund.frozen
					}
					default:
						debugLog("Impossible")
				}
				saveData()
			}, label: {
				HStack {
					Text("\(allFundBalance)")
						.frame(width: 55, alignment: .trailing)
					Divider()
					Text("\(ratioString)")
						.frame(width: 55, alignment: .trailing)
						.contentShape(Rectangle())
						.onTapGesture {
							debugLog("clicked on ratio button")
							appState.ratioDisplayMode = appState.ratioDisplayMode.next()
					}
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
	
	var ratioString: String {
		let ratioString: String
		let budgetStack = appState.budgetStack
		
		var ratioSum : Float = 0
		var rechargeSum : Float = 0
		for fund in spentFunds {
			if !fund.frozen {
				ratioSum += fund.getRatio()
				rechargeSum += fund.recharge
			}
		}
		
		let percentage = formatPercentage(ratioSum * budgetStack.getCurrentRatio())
		let longPeriod = appState.longPeriod
		let time = formatTime(TimeInterval(ratioSum * budgetStack.getCurrentRatio()) * longPeriod)
		let rechargeAmount = formatRecharge(rechargeSum)
		switch appState.ratioDisplayMode {
			case .percentage:
				ratioString = percentage
			case .timePerDay:
				ratioString = time
			case .rechargeAmount:
				ratioString = rechargeAmount
		}
		return ratioString
	}
	
	init(spentFunds: FetchedResults<TimeFund>) {
		self.spentFunds = spentFunds
		_action = appState.$fundListAction
	}
	
	var allSpentFundBalance: Int {
		return self.spentFunds.count
	}
	
	var body: some View {
		Section() {
			Button(action: {
				switch self.action {
					case .reset:
						for fund in self.spentFunds {
							fund.resetBalance()
					}
					case .earn:
						for fund in self.spentFunds {
							fund.adjustBalance(1)
					}
					case .delete:
						for fund in self.spentFunds {
							managedObjectContext.delete(fund)
					}
					case .qspend:
						for fund in self.spentFunds {
							fund.adjustBalance(-1)
					}
					case .freeze:
						for fund in self.spentFunds {
							fund.frozen = !fund.frozen
					}
					default:
						debugLog("Impossible")
				}
				saveData()
			}, label: {
				HStack {
					Text("\(allSpentFundBalance)")
						.frame(width: 55, alignment: .trailing)
					Divider()
					Text("\(ratioString)")
						.frame(width: 55, alignment: .trailing)
						.contentShape(Rectangle())
						.onTapGesture {
							debugLog("clicked on ratio button")
							appState.ratioDisplayMode = appState.ratioDisplayMode.next()
					}
					Divider()
					Text("All Spent Funds")
						.fontWeight(.heavy)
						.frame(minWidth: 20, maxWidth: .infinity, alignment: .leading)
				}
			})
		}
	}
}


