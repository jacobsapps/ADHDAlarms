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
    @State private var selectedDays: Set<Int> = []
    @State private var showPermissionsDeniedAlert = false
    @State private var selectedSound = "default"
    @State private var selectedSnoozeDelay: Int = 300
    @State private var selectedButtonColor: Color = .blue
    @State private var selectedTextColor: Color = .white
    @FocusState private var isTextFieldFocused: Bool
    
    init(editingAlarm: AlarmModel? = nil) {
        self.editingAlarm = editingAlarm
    }
    
    private let availableSounds = ["default", "airhorn", "2sad4me", "wrongnumber", "sandstorm"]
    
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
                
                Section(header: Text("Sound")) {
                    SoundPickerView(availableSounds: availableSounds, selectedSound: $selectedSound)
                }
                
                DaysSelectionSection(
                    selectedDays: $selectedDays,
                    daysOfWeek: daysOfWeek
                )
                
                SnoozeDelaySection(selectedSnoozeDelay: $selectedSnoozeDelay)
                
                AlarmColorsSection(
                    selectedButtonColor: $selectedButtonColor,
                    selectedTextColor: $selectedTextColor
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
            
            let alarm: AlarmModel
            if let editingAlarm = editingAlarm {
                // Update existing alarm
                try await AlarmManager.shared.stop(id: editingAlarm.id)
                
                editingAlarm.name = alarmName
                editingAlarm.hour = hour
                editingAlarm.minute = minute
                editingAlarm.selectedDays = selectedDays
                editingAlarm.selectedSound = selectedSound
                editingAlarm.snoozeDelay = selectedSnoozeDelay
                editingAlarm.buttonColorHex = selectedButtonColor.toHex()
                editingAlarm.textColorHex = selectedTextColor.toHex()
                
                alarm = editingAlarm
            } else {
                // Create new alarm
                alarm = AlarmModel(
                    name: alarmName,
                    hour: hour,
                    minute: minute,
                    selectedDays: selectedDays,
                    selectedSound: selectedSound,
                    snoozeDelay: selectedSnoozeDelay,
                    buttonColor: selectedButtonColor,
                    textColor: selectedTextColor
                )
                modelContext.insert(alarm)
            }
            
            try modelContext.save()
            print("✅ Alarm saved to SwiftData: \(alarm.name) at \(alarm.timeString)")
            
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
                text: "Done",
                textColor: alarm.textColor,
                systemImageName: "checkmark.seal.fill"
            )
            
            let repeatButton = AlarmButton(
                text: "Snooze",
                textColor: alarm.textColor,
                systemImageName: "repeat.circle.fill"
            )
            
            // Configure snooze countdown presentation (correct API)
            let countdownPresentation = AlarmPresentation.Countdown(
                title: LocalizedStringResource(stringLiteral: "\\(alarm.name) - Snoozing"),
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
            
            let alarmConfiguration = AlarmManager.AlarmConfiguration(
                countdownDuration: countdownDuration,
                schedule: schedule,
                attributes: attributes,
                secondaryIntent: nil,
                sound: AlertConfiguration.AlertSound.named("2sad4me")
            )
            
            _ = try await AlarmManager.shared.schedule(id: alarm.id, configuration: alarmConfiguration)
            
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

struct SoundPickerView: View {
    let availableSounds: [String]
    @Binding var selectedSound: String
    @State private var audioPlayer: AVAudioPlayer?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(availableSounds, id: \.self) { sound in
                    SoundItemView(
                        soundName: sound,
                        isSelected: selectedSound == sound,
                        onTap: {
                            selectedSound = sound
                        },
                        onPlay: {
                            playSound(sound)
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func playSound(_ soundName: String) {
        guard let soundURL = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("Could not find sound file: \(soundName).mp3")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            print("Error playing sound: \(error)")
        }
    }
}

struct SoundItemView: View {
    let soundName: String
    let isSelected: Bool
    let onTap: () -> Void
    let onPlay: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Text(soundName.capitalized)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
            
            Button(action: onPlay) {
                Image(systemName: "play.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(width: 80, height: 60)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    AddAlarmView()
        .modelContainer(for: AlarmModel.self, inMemory: true)
}
