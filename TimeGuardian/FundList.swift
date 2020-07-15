//
//  BudgetView.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/6/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI

struct FundList: View {
	let budget: TimeBudget
	@EnvironmentObject private var frontModel: BudgetFrontModel
	@State var fundList: [TimeFund]
	@State var editMode = EditMode.inactive
	@State var editingFund : TimeFund? = nil
	@State var action : FundBalanceAction = .minus
	
	var body: some View {
		VStack {
			Picker("Fund Action", selection: $action) {
				Text("-")
					.tag(FundBalanceAction.minus)
				Text("= 0")
					.tag(FundBalanceAction.zero)
				Text("+")
					.tag(FundBalanceAction.plus)
			}
			.pickerStyle(SegmentedPickerStyle())
			List {
				ForEach(fundList, id: \.self) { fund in
					FundRow(
						action: self.action,
						fund: fund,
						editingFund: self.$editingFund,
						editMode: self.$editMode
					)
				}
				.onDelete { indexSet in
					for index in indexSet {
						self.frontModel.deleteFund(index: index)
					}
				}
				.onMove() { (source: IndexSet, destination: Int) in
					self.frontModel.moveFund(fromOffsets: source, toOffset: destination)
				}
			}
			.navigationBarTitle(Text(budget.name), displayMode: .inline)
			.navigationBarItems(
				leading: EditFundListButton(editMode: $editMode),
				trailing: CreateNewFundButton(
					editMode: editMode,
					editingFund: $editingFund,
					budget: budget
				)
			)
		}
		.environment(\.editMode, $editMode)
	}
}

struct EditFundListButton: View {
	@EnvironmentObject var frontModel: BudgetFrontModel
	@Binding var editMode: EditMode
	
	var body: some View {
		VStack {
			if editMode == .active {
				Button(action: {
					self.editMode = .inactive
				}) {
					Text("Done")
						.fontWeight(.medium)
						.font(.headline)
						.frame(minWidth: 100, minHeight: 40, alignment: .leading)
					//				.border(Color.black, width: 2)
				}
			} else {
				Button(action: {
					self.editMode = .active
				}) {
					Text("Edit")
						.font(.headline)
						.fontWeight(.medium)
						.frame(minWidth: 100, minHeight: 40, alignment: .leading)
					//				.border(Color.black, width: 2)
				}
			}
		}
	}
}

struct CreateNewFundButton: View {
	@EnvironmentObject var frontModel: BudgetFrontModel
	let editMode: EditMode
	@Binding var editingFund : TimeFund?
	let budget: TimeBudget
	
	var body: some View {
		VStack {
			if editMode == .active {
				EmptyView()
			} else {
				Button(action: {
					debugLog("onAdd executed")
					do {
						self.editingFund = try self.frontModel.addFund(budget: self.budget)
					} catch {
						let nserror = error as NSError
						fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
					}
				}) {
					Image(systemName: "plus")
						.frame(minWidth: 100, minHeight: 40, alignment: .trailing)
				}
			}
		}
	}
}

enum FundBalanceAction: CaseIterable {
	case minus, zero, plus
}

struct FundRow: View {
	let action: FundBalanceAction
	@State var fund: TimeFund
	@Binding var editingFund: TimeFund?
	@Binding var editMode: EditMode
	@EnvironmentObject private var frontModel: BudgetFrontModel

	var body: some View {
		VStack {
			if self.fund == self.editingFund {
				TextField("Fund Name", text: self.$fund.name, onCommit: {
					debugLog("Committed Fund")
					if self.fund.name != "" {
						self.fund.managedObjectContext?.performAndWait {
							self.fund.save()
						}
					} else {
						self.frontModel.deleteFund(fund: self.fund)
					}
					self.editingFund = nil
				}).font(.body)
					.onDisappear(perform: {
						debugLog("Disappeared")
					}).introspectTextField { textField in
						textField.becomeFirstResponder()
				}
			} else {
				if self.editMode == .active {
					Text(self.fund.name)
						.font(.body)
						.frame(minWidth: 0, maxWidth: .infinity, minHeight: 40, alignment: .leading)
						.contentShape(Rectangle())
						.onTapGesture {
							self.editingFund = self.fund
							self.editMode = .inactive
					}
				} else {
					if frontModel.hasSubBudget(fund: fund) {
						NavigationLink(
							destination: FundList(budget: fund.subBudget!, fundList: self.frontModel.getFunds(budget: fund.subBudget!), action: self.action)
						) {
							Text(fund.name)
						}
					} else {
						Button(fund.name) {
							switch self.action {
								case .minus:
									self.frontModel.adjustBalance(fund: self.fund, amount: -1)
								case .zero:
									self.frontModel.zeroBalance(fund: self.fund)
								case .plus:
									self.frontModel.adjustBalance(fund: self.fund, amount: 1)
							}
						}
					}
				}
			}
		}
	}
}

struct FundList_Previews: PreviewProvider {
	static let frontModel = generateTestFrontModel(empty: false)
	
	static var previews: some View {
		let budget = frontModel.budgetList[0]
		return FundList(budget: budget, fundList: frontModel.fundList)
			.environmentObject(frontModel)
	}
}

