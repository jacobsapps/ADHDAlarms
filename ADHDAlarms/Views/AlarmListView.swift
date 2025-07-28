import SwiftUI
import SwiftData
import AlarmKit

struct AlarmListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var alarms: [AlarmModel]
    @State private var showingAddAlarm = false
    @State private var editingAlarm: AlarmModel?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(alarms) { alarm in
                    AlarmRowView(alarm: alarm)
                        .onTapGesture {
                            editingAlarm = alarm
                        }
                }
                .onDelete(perform: deleteAlarms)
                
                if alarms.isEmpty {
                    Text("No alarms yet - tap + to create one")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
            .onAppear {
                print("🔍 AlarmListView appeared with \(alarms.count) alarms")
                for alarm in alarms {
                    print("  - \(alarm.name) at \(alarm.timeString)")
                }
            }
            .navigationTitle("Alarms")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddAlarm = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                AddAlarmView()
            }
            .sheet(item: $editingAlarm) { alarm in
                AddAlarmView(editingAlarm: alarm)
            }
        }
    }
    
    private func deleteAlarms(offsets: IndexSet) {
        for index in offsets {
            let alarm = alarms[index]
            let alarmId = alarm.id
            modelContext.delete(alarm)
            Task {
                try AlarmManager.shared.stop(id: alarmId)
            }
        }
    }
}

struct AlarmRowView: View {
    let alarm: AlarmModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(alarm.name)
                    .font(.headline)
                Spacer()
                AlarmColorDots(buttonColor: alarm.buttonColor, textColor: alarm.textColor)
            }
            
            HStack {
                Text(alarm.timeString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(alarm.daysString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Text("♪ \(alarm.selectedSound ?? "Default")")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("⏰ \(alarm.snoozeDelayString)")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AlarmListView()
        .modelContainer(for: AlarmModel.self, inMemory: true)
}
