//
//  FundAction.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/19/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation

protocol Buttonable: Hashable, RawRepresentable {
	var asString: String { get }
	var asInt: Int { get }
	var longPressVersion: Self? { get }
	var longDescription: String { get }
}

enum FundAction: Int, CaseIterable, Buttonable {
	case view = 0
	case spend
	case qspend
	case reset
	case earn
	case subBudget
	case copy
	case edit
	case delete
	case freeze
	case unSubBudget

	var asInt: Int {
		return self.rawValue
	}
	
	var asString: String {
		switch self {
			case .view: return "View"
			case .spend: return "Spend"
			case .qspend: return "QSpend"
			case .reset: return "Reset"
			case .earn: return "Earn"
			case .subBudget: return "Sub"
			case .copy: return "Copy"
			case .edit: return "Edit"
			case .delete: return "Delete"
			case .freeze: return "Freeze"
			case .unSubBudget: return "UnSub"
		}
	}
	
	var longDescription: String {
		switch self {
			case .view: return "navigate without changing any balances"
			case .spend: return "spend fund (balance - 1)"
			case .qspend: return "quick spend fund (don't return to top)"
			case .reset: return "reset fund to recharge level"
			case .earn: return "earn fund (balance + recharge)"
			case .subBudget: return "attach sub budget"
			case .copy: return "copy (duplicate a fund)"
			case .edit: return "edit fund name or position"
			case .delete: return "delete fund"
			case .freeze: return "freeze (marks a fund as frozen, which prevents it from being spent)"
			case .unSubBudget: return "UnSub (detatch sub budget from fund)"
		}
	}
	
	var canApplyToAll: Bool {
		switch self {
			case .qspend, .reset, .earn, .delete, .freeze: return true
			default: return false
		}
	}
	
	var goesToSubIfPossible: Bool {
		switch self {
			case .spend, .view, .subBudget: return true
			default: return false
		}
	}
	
	var longPressVersion: FundAction? {
		switch self {
			case .spend: return .freeze
			case .subBudget: return .unSubBudget
			case .earn: return .reset
			default: return nil
		}
	}
	
	static var allCasesInRows: [[FundAction]] {
		[
			[.view, .spend, .qspend, .earn],
			[.subBudget, .copy, .edit, .delete]
		]
	}
	
}

