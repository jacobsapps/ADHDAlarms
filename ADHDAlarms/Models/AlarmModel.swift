import Foundation
import SwiftData
import SwiftUI

@Model
class AlarmModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var hour: Int
    var minute: Int
    var selectedDays: Set<Int>
    var isActive: Bool
    var createdAt: Date
    var selectedSound: String?
    var snoozeDelay: Int
    var buttonColorHex: String
    var textColorHex: String
    var stopButtonTitle: String?
    var snoozeButtonTitle: String?
    
    init(id: UUID = UUID(), name: String, hour: Int, minute: Int, selectedDays: Set<Int>, isActive: Bool = true, selectedSound: String? = nil, snoozeDelay: Int = 300, buttonColor: Color = .blue, textColor: Color = .white, stopButtonTitle: String? = nil, snoozeButtonTitle: String? = nil) {
        self.id = id
        self.name = name
        self.hour = hour
        self.minute = minute
        self.selectedDays = selectedDays
        self.isActive = isActive
        self.createdAt = Date()
        self.selectedSound = selectedSound
        self.snoozeDelay = snoozeDelay
        self.buttonColorHex = buttonColor.toHex()
        self.textColorHex = textColor.toHex()
        self.stopButtonTitle = stopButtonTitle
        self.snoozeButtonTitle = snoozeButtonTitle
    }
    
    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let date = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    var daysString: String {
        let dayNames = ["S", "M", "T", "W", "T", "F", "S"]
        return selectedDays.sorted().map { dayNames[$0] }.joined(separator: " ")
    }
    
    var buttonColor: Color {
        return Color(hex: buttonColorHex) ?? .blue
    }
    
    var textColor: Color {
        return Color(hex: textColorHex) ?? .white
    }
    
    var snoozeDelayString: String {
        switch snoozeDelay {
        case 60: return "1m"
        case 300: return "5m"
        case 600: return "10m"
        case 1800: return "30m"
        case 3600: return "1h"
        case 7200: return "2h"
        case 14400: return "4h"
        case 86400: return "1d"
        default: return "\(snoozeDelay)s"
        }
    }
}

