//
//  Utils.swift
//  TimeGuardian
//
//  Created by Jeremy Gurr on 7/16/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import Foundation

func arrayEquals<E: Equatable>(_ x: [E], _ y: [E]) -> Bool {
	var result = true
	for i in 0 ..< x.count {
		if x[i] != y[i] {
			result = false
			break
		}
	}
	return result
}
