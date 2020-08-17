//
//  Utils.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/16/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation
import CoreData
import SwiftUI
import Combine

func arrayEquals<E: Equatable>(_ x: [E], _ y: [E]) -> Bool {
	var result = true
	if y.count != x.count {
		result = false
	} else {
		for i in 0 ..< x.count {
			if x[i] != y[i] {
				result = false
				break
			}
		}
	}
	return result
}

func debugLog(_ message: String) {
	print(message)
}

func errorLog(_ message: String) {
	print(message)
}

func saveData() {
	debugLog("saveData")

	managedObjectContext.performAndWait {
		do {
			try managedObjectContext.save()
		} catch {
			let nserror = error as NSError
			fatalError("Unresolved error \(nserror)")
		}
	}
}

extension UIApplication {
	func endEditing(_ force: Bool) {
		self.windows
			.filter{$0.isKeyWindow}
			.first?
			.endEditing(force)
	}
}

func getStartOfDay(of date: Date = Date()) -> Date {
	let cal = Calendar(identifier: .gregorian)
	let startOfDay = cal.startOfDay(for: date)
	return startOfDay
}

extension CaseIterable where Self: Equatable {
	func next() -> Self {
		let all = Self.allCases
		let idx = all.firstIndex(of: self)!
		let next = all.index(after: idx)
		return all[next == all.endIndex ? all.startIndex : next]
	}
}

let seconds:TimeInterval = 1.0
let oneSecond = seconds
let minutes:TimeInterval = 60.0
let oneMinute = minutes
let hours:TimeInterval = 60.0 * minutes
let oneHour = hours
let days:TimeInterval = 24 * hours
let oneDay = days

let space : Character = " "
let newline : Character = "\n"
