import SwiftUI

struct DaysSelectionSection: View {
    @Binding var selectedDays: Set<Int>
    let daysOfWeek: [String]
    
    var body: some View {
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
    
    private func toggleDay(_ day: Int) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}