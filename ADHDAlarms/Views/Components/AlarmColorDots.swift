import SwiftUI

struct AlarmColorDots: View {
    let buttonColor: Color
    let textColor: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(buttonColor)
                .frame(width: 6, height: 6)
            
            Circle()
                .fill(textColor)
                .frame(width: 6, height: 6)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                )
        }
    }
}