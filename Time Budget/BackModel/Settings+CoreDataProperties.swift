//
//  Settings+CoreDataProperties.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 8/14/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//
//

import Foundation
import CoreData


extension Settings {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Settings> {
        return NSFetchRequest<Settings>(entityName: "Settings")
    }

    @NSManaged public var dataVersion: Int16
    @NSManaged public var shortPeriod: Double   // needed for day view
    @NSManaged public var longPeriod: Double		// needed for fundlist
    @NSManaged public var balanceDisplayMode: Int16 // fundlist
    @NSManaged public var ratioDisplayMode: Int16 // fundlist

}
