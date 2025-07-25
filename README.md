# AlarmKit iOS 26 - Complete Implementation Guide

A comprehensive SwiftUI app demonstrating AlarmKit usage in iOS 26, featuring custom alarm scheduling, snooze functionality, color customization, and SwiftData persistence.

## 📱 Features

- **System-Level Alarms**: AlarmKit integration with Lock Screen and Dynamic Island support
- **Custom Snooze Duration**: Configurable snooze interval (1m, 5m, 10m, 30m, 1h, 2h, 4h, 1d)
- **Color Customization**: Custom button and text colors for alarm presentations
- **Alarm Editing**: Full CRUD operations with tap-to-edit functionality
- **SwiftData Persistence**: Modern data persistence with custom color storage
- **Rich UI Components**: Modular SwiftUI architecture with reusable components

## 🚀 Getting Started

### Prerequisites

- iOS 26.0+
- Xcode 26.0+
- Swift 6.0+

### Setup

1. **Add AlarmKit Framework**
   ```swift
   import AlarmKit
   ```

2. **Configure Info.plist**
   Add the required usage description:
   ```xml
   <key>NSAlarmKitUsageDescription</key>
   <string>This app needs alarm permissions to schedule custom alarms with snooze functionality.</string>
   ```

3. **Request Authorization**
   ```swift
   let status = try await AlarmManager.shared.requestAuthorization()
   ```

## 🔧 AlarmKit API Overview

### Core Components

#### 1. AlarmManager
The central coordinator for all alarm operations:

```swift
// Request permission
let status = try await AlarmManager.shared.requestAuthorization()

// Schedule an alarm
let alarmID = try await AlarmManager.shared.schedule(
    id: UUID(),
    configuration: alarmConfiguration
)

// Stop an alarm
try await AlarmManager.shared.stop(id: alarmID)
```

#### 2. AlarmPresentation
Controls how alarms appear to users with three distinct states:

**Alert Presentation** (when alarm fires):
```swift
let alertPresentation = AlarmPresentation.Alert(
    title: LocalizedStringResource(stringLiteral: "Wake Up!"),
    stopButton: AlarmButton(
        text: "Done",
        textColor: .white,
        systemImageName: "checkmark.seal.fill"
    ),
    secondaryButton: AlarmButton(
        text: "Snooze",
        textColor: .white,
        systemImageName: "repeat.circle.fill"
    ),
    secondaryButtonBehavior: .countdown
)
```

**Countdown Presentation** (during snooze):
```swift
let countdownPresentation = AlarmPresentation.Countdown(
    title: LocalizedStringResource(stringLiteral: "Snoozing - 5 minutes remaining"),
    pauseButton: AlarmButton(
        text: "Snooze",
        textColor: .white,
        systemImageName: "repeat.circle.fill"
    )
)
```

**Complete Presentation**:
```swift
let presentation = AlarmPresentation(
    alert: alertPresentation,
    countdown: countdownPresentation
)
```

#### 3. AlarmConfiguration
Defines the complete alarm behavior:

```swift
// Countdown duration for snooze functionality
let countdownDuration = Alarm.CountdownDuration(
    preAlert: nil,                   // No pre-alert countdown
    postAlert: TimeInterval(300)     // 5-minute snooze duration
)

// Alarm schedule
let schedule = Alarm.Schedule.relative(Alarm.Schedule.Relative(
    time: Alarm.Schedule.Relative.Time(hour: 7, minute: 30),
    repeats: Alarm.Schedule.Relative.Recurrence.weekly([.monday, .tuesday, .wednesday, .thursday, .friday])
))

// Alarm attributes
let attributes = AlarmAttributes(
    presentation: presentation,
    metadata: CustomMetadata(),
    tintColor: .blue
)

// Complete configuration
let alarmConfiguration = AlarmManager.AlarmConfiguration(
    countdownDuration: countdownDuration,
    schedule: schedule,
    attributes: attributes,
    secondaryIntent: nil,
    sound: .default
)
```

## 🎨 Custom Implementation Details

### SwiftData Model with Color Storage

Since SwiftData doesn't natively support Color storage, we use hex strings:

```swift
@Model
class AlarmModel {
    // Core properties
    var name: String
    var hour: Int
    var minute: Int
    var selectedDays: Set<Int>
    var snoozeDelay: Int
    
    // Color storage as hex strings
    var buttonColorHex: String
    var textColorHex: String
    
    // Computed properties for SwiftUI
    var buttonColor: Color {
        return Color(hex: buttonColorHex) ?? .blue
    }
    
    var textColor: Color {
        return Color(hex: textColorHex) ?? .white
    }
    
    init(/* parameters */) {
        // Convert colors to hex for storage
        self.buttonColorHex = buttonColor.toHex()
        self.textColorHex = textColor.toHex()
    }
}
```

### Color Utility Extension

```swift
extension Color {
    func toHex() -> String {
        let uiColor = UIColor(self)
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        let rgb: Int = (Int)(red * 255) << 16 | (Int)(green * 255) << 8 | (Int)(blue * 255)
        return String(format: "#%06x", rgb)
    }
    
    init?(hex: String) {
        guard hex.hasPrefix("#"), hex.count == 7 else { return nil }
        
        let scanner = Scanner(string: String(hex.dropFirst()))
        var hexNumber: UInt64 = 0
        
        guard scanner.scanHexInt64(&hexNumber) else { return nil }
        
        self.init(
            red: CGFloat((hexNumber & 0xff0000) >> 16) / 255,
            green: CGFloat((hexNumber & 0x00ff00) >> 8) / 255,
            blue: CGFloat(hexNumber & 0x0000ff) / 255
        )
    }
}
```

## 🔄 Alarm Lifecycle Management

### Creating Alarms

```swift
@MainActor
private func saveAlarm() async {
    do {
        // 1. Request authorization
        try await requestAlarmAuthorization()
        
        // 2. Create or update alarm model
        let alarm = createAlarmModel()
        modelContext.insert(alarm)
        try modelContext.save()
        
        // 3. Schedule with AlarmKit
        let weekdays = convertToAlarmKitWeekdays(selectedDays)
        await scheduleAlarm(alarm: alarm, weekdays: weekdays)
        
    } catch {
        print("Error saving alarm: \(error)")
    }
}
```

### Updating Alarms

```swift
// Stop existing alarm
try await AlarmManager.shared.stop(id: existingAlarm.id)

// Update alarm properties
existingAlarm.name = newName
existingAlarm.snoozeDelays = newSnoozeDelays
// ... other updates

// Reschedule with new configuration
await scheduleAlarm(alarm: existingAlarm, weekdays: newWeekdays)
```

### Deleting Alarms

```swift
private func deleteAlarms(offsets: IndexSet) {
    for index in offsets {
        let alarm = alarms[index]
        modelContext.delete(alarm)
        
        // Stop the scheduled alarm
        Task {
            try await AlarmManager.shared.stop(id: alarm.id)
        }
    }
}
```

## 🎯 Best Practices

### 1. Authorization Handling
Always check authorization status before scheduling:

```swift
@MainActor
private func requestAlarmAuthorization() async throws {
    let status = try await AlarmManager.shared.requestAuthorization()
    switch status {
    case .authorized:
        break
    case .denied, .notDetermined:
        throw AlarmError.permissionDenied
    @unknown default:
        throw AlarmError.permissionDenied
    }
}
```

### 2. Error Handling
Implement comprehensive error handling:

```swift
enum AlarmError: Error, Sendable {
    case permissionDenied
    case schedulingFailed
    case invalidConfiguration
}
```

### 3. SwiftUI Architecture
Use modular components for maintainability:

- `AlarmDetailsSection`: Name and time configuration
- `DaysSelectionSection`: Day selection with toggle logic
- `SnoozeDelaySection`: Single-selection snooze duration
- `AlarmColorsSection`: Color customization with preview

### 4. Data Validation
Validate alarm configuration before scheduling:

```swift
.disabled(alarmName.isEmpty || selectedDays.isEmpty)
```

## 🔍 Advanced Features

### Snooze Duration Configuration
The app supports a single configurable snooze duration:

```swift
let countdownDuration = Alarm.CountdownDuration(
    preAlert: nil,
    postAlert: TimeInterval(alarm.snoozeDelay)
)
```

### Custom Metadata
Implement `AlarmMetadata` for additional data:

```swift
struct ADHDMetadata: AlarmMetadata {
    // Add custom properties as needed
    init() {}
}
```

### Live Activities Integration
For countdown display, implement Live Activities:

```swift
// Live Activity configuration would go here
// Required for countdown functionality
```

## 🐛 Common Issues & Solutions

### Issue: "Extra argument in call"
**Solution**: Ensure you're using the correct AlarmKit API parameters:
- `AlarmPresentation.Countdown` only accepts `title` and `pauseButton`
- `AlarmManager.AlarmConfiguration` uses direct initializer, not `.alarm()` static method
- Use `preAlert: nil` instead of `preAlert: TimeInterval(0)` in `Alarm.CountdownDuration`

### Issue: Colors not persisting
**Solution**: Use hex string storage with computed properties for SwiftData compatibility

### Issue: Snooze not working
**Solution**: Configure `postAlert` interval in `Alarm.CountdownDuration` and set `secondaryButtonBehavior: .countdown`

## 📚 Additional Resources

- [Apple Developer Documentation - AlarmKit](https://developer.apple.com/documentation/AlarmKit)
- [WWDC 2025 - Wake up to the AlarmKit API](https://developer.apple.com/videos/play/wwdc2025/230/)
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)

## 🤝 Contributing

This project serves as a comprehensive example of AlarmKit implementation. Feel free to use this code as a reference for your own AlarmKit integrations.

## 📄 License

MIT License - Feel free to use this code in your own projects.

---

**Note**: This implementation requires iOS 26.0+ and demonstrates the complete AlarmKit API usage as of WWDC 2025. The framework provides system-level alarm capabilities that were previously exclusive to Apple's built-in Clock app.