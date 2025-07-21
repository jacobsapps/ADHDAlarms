import Foundation
import SwiftData

@Model
class AlarmModel {
    @Attribute(.unique) var id: UUID
    var name: String
    var hour: Int
    var minute: Int
    var selectedDays: Set<Int>
    var isActive: Bool
    var createdAt: Date
    var selectedSound: String
    
    init(id: UUID = UUID(), name: String, hour: Int, minute: Int, selectedDays: Set<Int>, isActive: Bool = true, selectedSound: String = "default") {
        self.id = id
        self.name = name
        self.hour = hour
        self.minute = minute
        self.selectedDays = selectedDays
        self.isActive = isActive
        self.createdAt = Date()
        self.selectedSound = selectedSound
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
}