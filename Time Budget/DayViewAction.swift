//
//  DayViewAction.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 8/2/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation
import SwiftUI

enum DayViewAction: Int, CaseIterable, Buttonable {
	case add = 0
	case remove
	case toggle
	
	var asInt: Int {
		return self.rawValue
	}
	
	var asString: String {
		switch self {
			case .add: return "Add"
			case .remove: return "Remove"
			case .toggle: return "Toggle"
		}
	}
	
	var longDescription: String {
		switch self {
			case .add: return "add [***] to time slot"
			case .remove: return "remove fund from time slot"
			case .toggle: return "removes or adds [***]"
		}
	}
	
	var longPressVersion: DayViewAction? {
		switch self {
			default: return nil
		}
	}
	
	static var allCasesInRows: [[DayViewAction]] {
		[
			[.add, .remove, .toggle],
		]
	}

}
