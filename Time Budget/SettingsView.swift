//
//  SettingsView.swift
//  Time Budget
//
//  Created by Jeremy Gurr on 8/15/20.
//  Copyright © 2020 Pure Logic Enterprises. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
	
	init() {
		debugLog("SettingsView.init")
	}
	
	var body: some View {
		VStack {
			Text("Fund Time Unit")
			Picker("Fund Time Unit", selection: appState.$shortPeriod) {
				Text("10 minutes").tag(10 * minutes)
				Text("12 minutes").tag(12 * minutes)
				Text("15 minutes").tag(15 * minutes)
				Text("20 minutes").tag(20 * minutes)
				Text("30 minutes").tag(30 * minutes)
				Text("60 minutes").tag(60 * minutes)
				Text("2 hours").tag(2 * hours)
			}
			.labelsHidden()
		}
		.onDisappear() {
			saveData()
		}
	}
}

struct SettingsView_Previews: PreviewProvider {
	static var previews: some View {
		let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
		let testDataBuilder = TestDataBuilder(context: context)
		testDataBuilder.createTestData()
		
		return SettingsView()
	}
}

