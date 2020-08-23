//
//  Settings+CoreDataClass.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 8/14/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Settings)
public class Settings: NSManagedObject {
	static func fetch(context: NSManagedObjectContext) -> Settings {

		var settings: Settings? = nil
		let request: NSFetchRequest<Settings> = Settings.fetchRequest()
		
		do {
			let settingsArray = try context.fetch(request)
			if let s = settingsArray.first {
				settings = s
			}
		} catch {
			errorLog("Error fetching settings: \(error)")
		}
		
		if settings == nil {
			settings = Settings(context: context)
		}
		
		return settings!

	}
}
