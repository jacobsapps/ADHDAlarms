//
//  ContentView.swift
//  ADHDAlarms
//
//  Created by Jacob Bartlett on 03/07/2025.
//

import SwiftUI
import ActivityKit
import AlarmKit
import AppIntents

struct ContentView: View {
    var body: some View {
        AlarmListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: AlarmModel.self, inMemory: true)
}

public struct OpenInApp: LiveActivityIntent {
    public func perform() async throws -> some IntentResult { .result() }
    
    public static var title: LocalizedStringResource = "Open App"
    public static var description = IntentDescription("Opens the Sample app")
    public static var openAppWhenRun = true
    
    @Parameter(title: "alarmID")
    public var alarmID: String
    
    public init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    public init() {
        self.alarmID = ""
    }
}
