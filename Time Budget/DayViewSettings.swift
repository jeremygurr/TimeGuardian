//
//  CalendarSettings.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 7/26/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation
import SwiftUI

class DayViewSettings: ObservableObject {
//	@Published private var currentDay: Date = Date()
	@Published var expensePeriod: TimeInterval = 30
	@Published var plusMinusDays: Int = 1
	var periodsPerDay: Int {
		let minutesPerDay: Double = 60 * 24
		return Int(minutesPerDay / expensePeriod)
	}
}

