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
	case reset
	case earn
	case subBudget
	case clone
	case edit
	case delete
	
	var asInt: Int {
		return self.rawValue
	}
	
	var asString: String {
		switch self {
			case .view: return "View"
			case .spend: return "Spend"
			case .reset: return "Reset"
			case .earn: return "Earn"
			case .subBudget: return "Sub"
			case .clone: return "Clone"
			case .edit: return "Edit"
			case .delete: return "Delete"
		}
	}
	
	static var allCasesInRows: [[FundAction]] {
		[
			[.view, .spend, .earn, .reset],
			[.subBudget, .clone, .edit, .delete]
		]
	}
	
}

