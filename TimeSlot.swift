//
//  TimeSlot.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 7/28/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI

struct TimeSlot: Equatable, CustomStringConvertible {
	
	let baseDate: Date
	let slotIndex: Int
	let slotSize: TimeInterval
	let minutesFromBeginning: TimeInterval

	init(baseDate: Date, slotIndex: Int, slotSize: TimeInterval) {
		self.baseDate = baseDate
		self.slotIndex = slotIndex
		self.slotSize = slotSize
		self.minutesFromBeginning = slotSize * Double(slotIndex)
	}
	
	public var description: String {
		return "TimeSlot: { baseDate: \(baseDate), slotIndex: \(slotIndex), slotSize: \(slotSize), minutesFromBeginning: \(minutesFromBeginning) }"
	}

	var coversCurrentTime: Bool {
		let today = Date()
		let currentDate = getStartOfDay()
		let currentSlot = Int(currentDate.distance(to: today) / 60 / slotSize)
		let slotSame = currentSlot == slotIndex
		let dateSame = baseDate == currentDate
		return slotSame && dateSame
	}

}
