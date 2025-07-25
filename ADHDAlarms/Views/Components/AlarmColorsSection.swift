import SwiftUI

struct AlarmColorsSection: View {
    @Binding var selectedButtonColor: Color
    @Binding var selectedTextColor: Color
    
    var body: some View {
        Section(header: Text("Alarm Colors")) {
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Button Color")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ColorPicker("Button Color", selection: $selectedButtonColor, supportsOpacity: false)
                            .labelsHidden()
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Text Color")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ColorPicker("Text Color", selection: $selectedTextColor, supportsOpacity: false)
                            .labelsHidden()
                    }
                    
                    Spacer()
                    
                    AlarmColorPreview(buttonColor: selectedButtonColor, textColor: selectedTextColor)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct AlarmColorPreview: View {
    let buttonColor: Color
    let textColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Preview")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Snooze") {
                // Preview only
            }
            .frame(width: 80, height: 36)
            .background(buttonColor)
            .foregroundColor(textColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .disabled(true)
        }
    }
}