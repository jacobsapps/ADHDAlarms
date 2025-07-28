import SwiftUI
import ActivityKit
import SwiftData
import AlarmKit
import AVFoundation

struct AddAlarmView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let editingAlarm: AlarmModel?
    
    @State private var alarmName = ""
    @State private var selectedTime = Date()
    @State private var selectedDays: Set<Int> = {
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        let firstWeekday = calendar.firstWeekday
        let adjustedToday = (today - firstWeekday + 7) % 7
        return [adjustedToday]
    }()
    @State private var showPermissionsDeniedAlert = false
    @State private var selectedSound: String? = nil
    @State private var selectedSnoozeDelay: Int = 300
    @State private var selectedButtonColor: Color = .blue
    @State private var selectedTextColor: Color = .white
    @State private var stopButtonTitle: String = "Stop"
    @State private var snoozeButtonTitle: String = "Snooze"
    @FocusState private var isTextFieldFocused: Bool
    
    init(editingAlarm: AlarmModel? = nil) {
        self.editingAlarm = editingAlarm
    }
    
    
    private var daysOfWeek: [String] {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday
        let shortDaySymbols = calendar.shortWeekdaySymbols
        var orderedDays: [String] = []
        
        for i in 0..<7 {
            let dayIndex = (firstWeekday - 1 + i) % 7
            orderedDays.append(String(shortDaySymbols[dayIndex].prefix(1)))
        }
        return orderedDays
    }
    
    private var fullDayNames: [String] {
        let calendar = Calendar.current
        let firstWeekday = calendar.firstWeekday
        let weekdaySymbols = calendar.weekdaySymbols
        var orderedDays: [String] = []
        
        for i in 0..<7 {
            let dayIndex = (firstWeekday - 1 + i) % 7
            orderedDays.append(weekdaySymbols[dayIndex])
        }
        return orderedDays
    }
    
    var body: some View {
        NavigationStack {
            Form {
                AlarmDetailsSection(
                    alarmName: $alarmName,
                    selectedTime: $selectedTime,
                    isTextFieldFocused: $isTextFieldFocused
                )
                
                SoundSelectionSection(selectedSound: $selectedSound)
                
                DaysSelectionSection(
                    selectedDays: $selectedDays,
                    daysOfWeek: daysOfWeek
                )
                
                SnoozeDelaySection(selectedSnoozeDelay: $selectedSnoozeDelay)
                
                AlarmColorsSection(
                    selectedButtonColor: $selectedButtonColor,
                    selectedTextColor: $selectedTextColor
                )
                
                ButtonTitlesSection(
                    stopButtonTitle: $stopButtonTitle,
                    snoozeButtonTitle: $snoozeButtonTitle,
                    isTextFieldFocused: $isTextFieldFocused
                )
            }
            .navigationTitle(isEditing ? "Edit Alarm" : "New Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                isTextFieldFocused = false
            }
            .onAppear {
                loadAlarmData()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { @MainActor in
                            await saveAlarm()
                        }
                    }
                    .disabled(alarmName.isEmpty || selectedDays.isEmpty)
                }
            }
        }
        .alert("Permissions Required", isPresented: $showPermissionsDeniedAlert) {
            Button("OK") { }
        } message: {
            Text("Please allow alarm permissions in Settings to schedule alarms.")
        }
    }
    
    private var isEditing: Bool {
        editingAlarm != nil
    }
    
    private func loadAlarmData() {
        guard let alarm = editingAlarm else { return }
        
        alarmName = alarm.name
        selectedDays = alarm.selectedDays
        selectedSound = alarm.selectedSound
        selectedSnoozeDelay = alarm.snoozeDelay
        selectedButtonColor = alarm.buttonColor
        selectedTextColor = alarm.textColor
        stopButtonTitle = alarm.stopButtonTitle ?? "Stop"
        snoozeButtonTitle = alarm.snoozeButtonTitle ?? "Snooze"
        
        let calendar = Calendar.current
        selectedTime = calendar.date(bySettingHour: alarm.hour, minute: alarm.minute, second: 0, of: Date()) ?? Date()
    }
    
    
    @MainActor
    private func saveAlarm() async {
        do {
            try await requestAlarmAuthorization()
            
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: selectedTime)
            let minute = calendar.component(.minute, from: selectedTime)
            
            // For existing alarms, stop and delete the current alarm first
            if let editingAlarm = editingAlarm {
                print("🗑️ Deleting existing alarm: \(editingAlarm.name)")
                
                // Stop the alarm in AlarmManager
                do {
                    try await AlarmManager.shared.stop(id: editingAlarm.id)
                    print("✅ Stopped existing alarm with ID: \(editingAlarm.id)")
                } catch {
                    print("⚠️ Failed to stop existing alarm (continuing anyway): \(error)")
                }
                
                // Delete from SwiftData and save immediately
                modelContext.delete(editingAlarm)
                do {
                    try modelContext.save()
                    print("✅ Deleted existing alarm from SwiftData")
                } catch {
                    print("❌ Failed to delete existing alarm: \(error)")
                    throw error
                }
            }
            
            // Create a new alarm (whether editing or creating new)
            print("➕ Creating new alarm")
            let alarm = AlarmModel(
                name: alarmName,
                hour: hour,
                minute: minute,
                selectedDays: selectedDays,
                selectedSound: selectedSound,
                snoozeDelay: selectedSnoozeDelay,
                buttonColor: selectedButtonColor,
                textColor: selectedTextColor,
                stopButtonTitle: stopButtonTitle.isEmpty ? nil : stopButtonTitle,
                snoozeButtonTitle: snoozeButtonTitle.isEmpty ? nil : snoozeButtonTitle
            )
            modelContext.insert(alarm)
            
            // Save the new alarm
            do {
                try modelContext.save()
                print("✅ Alarm saved to SwiftData: \(alarm.name) at \(alarm.timeString)")
            } catch {
                print("❌ Failed to save alarm to SwiftData: \(error)")
                throw error
            }
            
            let weekdays: [Locale.Weekday] = selectedDays.compactMap { dayIndex in
                let calendar = Calendar.current
                let firstWeekday = calendar.firstWeekday
                let actualDayIndex = (firstWeekday - 1 + dayIndex) % 7 + 1
                
                switch actualDayIndex {
                case 1: return .sunday
                case 2: return .monday
                case 3: return .tuesday
                case 4: return .wednesday
                case 5: return .thursday
                case 6: return .friday
                case 7: return .saturday
                default: return nil
                }
            }
            
            // Always schedule the alarm (whether new or updated)
            print("🔄 Scheduling alarm with AlarmManager...")
            await scheduleAlarm(alarm: alarm, weekdays: weekdays)
            
            dismiss()
        } catch {
            print("Error saving alarm: \(error)")
        }
    }
    
    @MainActor
    private func requestAlarmAuthorization() async throws {
        let status = try await AlarmManager.shared.requestAuthorization()
        switch status {
        case .authorized:
            break
        case .denied:
            showPermissionsDeniedAlert = true
            throw AlarmError.permissionDenied
        case .notDetermined:
            showPermissionsDeniedAlert = true
            throw AlarmError.permissionDenied
        @unknown default:
            showPermissionsDeniedAlert = true
            throw AlarmError.permissionDenied
        }
    }
    
    private func scheduleAlarm(alarm: AlarmModel, weekdays: [Locale.Weekday]) async {
        do {
            let schedule = Alarm.Schedule.relative(Alarm.Schedule.Relative(
                time: Alarm.Schedule.Relative.Time(hour: alarm.hour, minute: alarm.minute),
                repeats: Alarm.Schedule.Relative.Recurrence.weekly(weekdays)
            ))
            
            let stopButton = AlarmButton(
                text: LocalizedStringResource(stringLiteral: alarm.stopButtonTitle ?? "Stop"),
                textColor: alarm.textColor,
                systemImageName: "checkmark.seal.fill"
            )
            
            let repeatButton = AlarmButton(
                text: LocalizedStringResource(stringLiteral: alarm.snoozeButtonTitle ?? "Snooze"),
                textColor: alarm.textColor,
                systemImageName: "repeat.circle.fill"
            )
            
            // Configure snooze countdown presentation (correct API)
            let countdownPresentation = AlarmPresentation.Countdown(
                title: LocalizedStringResource(stringLiteral: alarm.name),
                pauseButton: repeatButton
            )
            
            let alertPresentation = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: alarm.name),
                stopButton: stopButton,
                secondaryButton: repeatButton,
                secondaryButtonBehavior: .countdown
            )
            
            let presentation = AlarmPresentation(
                alert: alertPresentation,
                countdown: countdownPresentation
            )
            
            let attributes = AlarmAttributes(
                presentation: presentation,
                metadata: ADHDMetadata(),
                tintColor: alarm.buttonColor
            )
            
            // Use the selected snooze delay for countdown duration
            let countdownDuration = Alarm.CountdownDuration(
                preAlert: nil,
                postAlert: TimeInterval(alarm.snoozeDelay)
            )
            
            // Configure sound with detailed logging
            let soundConfig: AlertConfiguration.AlertSound
            if let selectedSoundName = alarm.selectedSound {
                // Verify the sound file exists
                if let soundURL = Bundle.main.url(forResource: selectedSoundName, withExtension: "mp3") {
                    soundConfig = AlertConfiguration.AlertSound.named(selectedSoundName)
                    print("🔊 Using custom sound: \(selectedSoundName) (found at \(soundURL))")
                } else {
                    soundConfig = .default
                    print("⚠️ Custom sound \(selectedSoundName).mp3 not found in bundle, using default")
                }
            } else {
                soundConfig = .default
                print("🔊 Using default sound")
            }
            
            let alarmConfiguration = AlarmManager.AlarmConfiguration(
                countdownDuration: countdownDuration,
                schedule: schedule,
                attributes: attributes,
                secondaryIntent: nil,
                sound: soundConfig
            )
            
            print("🚀 Scheduling alarm with ID: \(alarm.id)")
            let scheduledAlarm = try await AlarmManager.shared.schedule(id: alarm.id, configuration: alarmConfiguration)
            print("✅ Successfully scheduled alarm: \(scheduledAlarm)")
            
        } catch {
            print("Error scheduling alarm: \(error)")
        }
    }
}

enum AlarmError: Error, Sendable {
    case permissionDenied
}

struct ADHDMetadata: AlarmMetadata {
    init() {}
}


#Preview {
    AddAlarmView()
        .modelContainer(for: AlarmModel.self, inMemory: true)
}
