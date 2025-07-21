import SwiftUI
import SwiftData
import AlarmKit

struct AlarmListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var alarms: [AlarmModel]
    @State private var showingAddAlarm = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(alarms) { alarm in
                    AlarmRowView(alarm: alarm)
                }
                .onDelete(perform: deleteAlarms)
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
        VStack(alignment: .leading, spacing: 4) {
            Text(alarm.name)
                .font(.headline)
            HStack {
                Text(alarm.timeString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(alarm.daysString)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("♪ \(alarm.selectedSound)")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AlarmListView()
        .modelContainer(for: AlarmModel.self, inMemory: true)
}
