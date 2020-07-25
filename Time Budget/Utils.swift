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

func saveData(_ managedObjectContext: NSManagedObjectContext) {
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
