import SwiftUI
import SwiftData
import AlarmKit
import AVFoundation

struct AddAlarmView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var alarmName = ""
    @State private var selectedTime = Date()
    @State private var selectedDays: Set<Int> = []
    @State private var showPermissionsDeniedAlert = false
    @State private var selectedSound = "default"
    @FocusState private var isTextFieldFocused: Bool
    
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
                Section(header: Text("Alarm Details")) {
                    TextField("Alarm Name", text: $alarmName)
                        .focused($isTextFieldFocused)
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                }
                
                Section(header: Text("Sound")) {
                    SoundPickerView(availableSounds: availableSounds, selectedSound: $selectedSound)
                }
                
                Section(header: Text("Days")) {
                    VStack(spacing: 16) {
                        HStack {
                            ForEach(0..<7) { dayIndex in
                                Button(action: {
                                    toggleDay(dayIndex)
                                }) {
                                    Text(daysOfWeek[dayIndex])
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(selectedDays.contains(dayIndex) ? .white : .primary)
                                        .frame(width: 40, height: 40)
                                        .background(selectedDays.contains(dayIndex) ? Color.blue : Color.gray.opacity(0.2))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        
                        HStack {
                            Button("Select All") {
                                selectedDays = Set(0..<7)
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            Button("Deselect All") {
                                selectedDays.removeAll()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .onTapGesture {
                isTextFieldFocused = false
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
    
    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
    
    @MainActor
    private func saveAlarm() async {
        do {
            try await requestAlarmAuthorization()
            
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: selectedTime)
            let minute = calendar.component(.minute, from: selectedTime)
            
            let alarm = AlarmModel(
                name: alarmName,
                hour: hour,
                minute: minute,
                selectedDays: selectedDays,
                selectedSound: selectedSound
            )
            
            modelContext.insert(alarm)
            try modelContext.save()
            
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
                textColor: .white,
                systemImageName: "checkmark.seal.fill"
            )
            
            let repeatButton = AlarmButton(
                text: "Snooze",
                textColor: .red,
                systemImageName: "repeat.circle.fill"
            )
            
            let alertPresentation = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: alarm.name),
                stopButton: stopButton,
                secondaryButton: repeatButton,
                secondaryButtonBehavior: .countdown
            )
            
            let attributes = AlarmAttributes(
                presentation: AlarmPresentation(alert: alertPresentation),
                metadata: ADHDMetadata(),
                tintColor: Color.blue
            )
            
            // TODO: Build sound options 
            let soundURL = Bundle.main.url(forResource: alarm.selectedSound, withExtension: "mp3")
            
            let alarmConfiguration = AlarmManager.AlarmConfiguration<ADHDMetadata>
                .alarm(
                    schedule: schedule,
                    attributes: attributes,
                    sound: .default // AlertConfiguration.AlertSound.named("customSound")
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
