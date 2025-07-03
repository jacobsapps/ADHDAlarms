//
//  AppIntent.swift
//  Widgets
//
//  Created by Jacob Bartlett on 03/07/2025.
//

import WidgetKit
import AppIntents
import UserNotifications


struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "This is an example widget." }

    // An example configurable parameter.
    @Parameter(title: "Favorite Emoji", default: "😃")
    var favoriteEmoji: String
}

struct SnoozeAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Snooze Alarm"
    static var description = IntentDescription("Snooze the alarm for 5 minutes")
    static var openAppWhenRun: Bool = true // use supportedModes instead
    
    @Parameter(title: "Alarm Name")
    var alarmName: String
    
    init() {}
    
    init(alarmName: String) {
        self.alarmName = alarmName
    }
    
    func perform() async throws -> some IntentResult {
        print("🚨 HELLO WORLD - Snoozed alarm: \(alarmName)")
        return .result(dialog: "🚨 HELLO WORLD - Snoozed!")
    }
}

struct DismissAlarmIntent: AppIntent {
    static var title: LocalizedStringResource = "Dismiss Alarm"
    static var description = IntentDescription("Dismiss the alarm")
    static var openAppWhenRun: Bool = true // use supportedModes instead 
    
    @Parameter(title: "Alarm Name")
    var alarmName: String
    
    init() {}
    
    init(alarmName: String) {
        self.alarmName = alarmName
    }
    
    func perform() async throws -> some IntentResult {
        print("🚨 HELLO WORLD - Dismissed alarm: \(alarmName)")
        return .result(dialog: "🚨 HELLO WORLD - Dismissed!")
    }
}
