import SwiftUI

struct AlarmDetailsSection: View {
    @Binding var alarmName: String
    @Binding var selectedTime: Date
    @FocusState.Binding var isTextFieldFocused: Bool
    
    var body: some View {
        Section(header: Text("Alarm Details")) {
            TextField("Alarm Name", text: $alarmName)
                .focused($isTextFieldFocused)
            DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
        }
    }
}