import SwiftUI
import SwiftData
import AlarmKit

struct AddAlarmView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var alarmName = ""
    @State private var selectedTime = Date()
    @State private var selectedDays: Set<Int> = []
    @State private var showPermissionsDeniedAlert = false
    
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    private let fullDayNames = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Alarm Details")) {
                    TextField("Alarm Name", text: $alarmName)
                    DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
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
                selectedDays: selectedDays
            )
            
            modelContext.insert(alarm)
            try modelContext.save()
            
            await scheduleAlarm(alarm: alarm)
            
            dismiss()
        } catch {
            print("Error saving alarm: \(error)")
        }
    }
    
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
    
    private func scheduleAlarm(alarm: AlarmModel) async {
        do {
            let weekdays: [Locale.Weekday] = selectedDays.map { dayIndex in
                switch dayIndex {
                case 0: return .sunday
                case 1: return .monday
                case 2: return .tuesday
                case 3: return .wednesday
                case 4: return .thursday
                case 5: return .friday
                case 6: return .saturday
                default: return .monday
                }
            }
            
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
            
            let alarmConfiguration = AlarmManager.AlarmConfiguration<ADHDMetadata>
                .alarm(
                    schedule: schedule,
                    attributes: attributes
                )
            
            _ = try await AlarmManager.shared.schedule(id: alarm.id, configuration: alarmConfiguration)
            
        } catch {
            print("Error scheduling alarm: \(error)")
        }
    }
}

enum AlarmError: Error {
    case permissionDenied
}

struct ADHDMetadata: AlarmMetadata {
    init() {}
}

#Preview {
    AddAlarmView()
        .modelContainer(for: AlarmModel.self, inMemory: true)
}
