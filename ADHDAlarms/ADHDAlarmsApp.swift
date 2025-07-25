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
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: AlarmModel.self)
            print("✅ SwiftData container initialized successfully")
        } catch {
            print("❌ SwiftData container failed to initialize: \(error)")
            fatalError("Failed to initialize SwiftData container")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
