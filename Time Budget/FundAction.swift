//
//  FundAction.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/19/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation

protocol Stringable: Hashable, RawRepresentable {
	var asString: String { get }
	var asInt: Int { get }
}

enum FundAction: Int, CaseIterable, Stringable {
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
		}
	}
	
	static var allCasesInRows: [[FundAction]] {
		[
			[.view, .spend, .qspend, .earn, .reset],
			[.subBudget, .copy, .edit, .delete, .freeze]
		]
	}
	
}

