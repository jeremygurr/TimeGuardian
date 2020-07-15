//
//  TestFrontModel.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/15/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation
import SwiftUI

func generateTestFrontModel(empty: Bool) -> BudgetFrontModel {
	do {
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		if(empty) {
			return try BudgetFrontModel(dataContext: context)
		} else {
			return try BudgetFrontModel(dataContext: context, testData: TestDataBuilder(context: context))
		}
	} catch {
		let nserror = error as NSError
		fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
	}
}
