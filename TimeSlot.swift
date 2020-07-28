//
//  TimeSlot.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 7/28/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI

struct TimeSlot: Equatable {
	
	let baseDate: Date
	let slotIndex: Int
	let slotSize: TimeInterval
	let timeIntervalFromBeginning: TimeInterval

	init(baseDate: Date, slotIndex: Int, slotSize: TimeInterval) {
		self.baseDate = baseDate
		self.slotIndex = slotIndex
		self.slotSize = slotSize
		self.timeIntervalFromBeginning = slotSize * Double(slotIndex)
	}
	
	var coversCurrentTime: Bool {
		let today = Date()
		let currentDate = getStartOfDay()
		let currentSlot = Int(currentDate.distance(to: today) / slotSize)
		return currentSlot == slotIndex
	}

}
