//
//  CalendarSettings.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 7/26/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation
import SwiftUI

class CalendarSettings: ObservableObject {
	@Published private var currentDay: Date = Date()
	@Published var expensePeriod: Int = 30
	var periodsPerDay: Int {
		let minutesPerDay = 60 * 24
		return minutesPerDay / expensePeriod
	}
}

