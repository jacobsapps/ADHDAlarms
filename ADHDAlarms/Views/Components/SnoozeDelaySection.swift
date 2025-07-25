import SwiftUI

struct SnoozeDelaySection: View {
    @Binding var selectedSnoozeDelay: Int
    
    private let snoozeOptions: [(label: String, seconds: Int)] = [
        ("1m", 60),
        ("5m", 300),
        ("10m", 600),
        ("30m", 1800),
        ("1h", 3600),
        ("2h", 7200),
        ("4h", 14400),
        ("1d", 86400)
    ]
    
    var body: some View {
        Section(header: Text("Snooze Delay")) {
            VStack(spacing: 12) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ForEach(snoozeOptions, id: \.seconds) { option in
                        Button(action: {
                            selectedSnoozeDelay = option.seconds
                        }) {
                            Text(option.label)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(selectedSnoozeDelay == option.seconds ? .white : .primary)
                                .frame(height: 36)
                                .frame(maxWidth: .infinity)
                                .background(selectedSnoozeDelay == option.seconds ? Color.blue : Color.gray.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}