//
//  ADHDAlarmsApp.swift
//  ADHDAlarms
//
//  Created by Jacob Bartlett on 03/07/2025.
//

import SwiftUI
import SwiftData

@main
struct ADHDAlarmsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: AlarmModel.self)
    }
}
