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
            Task {
                try await AlarmManager.shared.stop(id: alarm.id)
            }
            modelContext.delete(alarm)
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
                Text(alarm.daysString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    AlarmListView()
        .modelContainer(for: AlarmModel.self, inMemory: true)
}
