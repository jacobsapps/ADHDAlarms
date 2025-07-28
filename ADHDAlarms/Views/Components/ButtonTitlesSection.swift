import SwiftUI

struct ButtonTitlesSection: View {
    @Binding var stopButtonTitle: String
    @Binding var snoozeButtonTitle: String
    @FocusState.Binding var isTextFieldFocused: Bool
    
    var body: some View {
        Section(header: Text("Button Titles")) {
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stop Button Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Stop", text: $stopButtonTitle)
                        .focused($isTextFieldFocused)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Snooze Button Title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("Snooze", text: $snoozeButtonTitle)
                        .focused($isTextFieldFocused)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            .padding(.vertical, 8)
        }
    }
}