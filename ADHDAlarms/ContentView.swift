//
//  ContentView.swift
//  ADHDAlarms
//
//  Created by Jacob Bartlett on 03/07/2025.
//

import SwiftUI
import ActivityKit

struct AlarmAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var alarmTime: Date
    }
    
    var name: String
}

struct ContentView: View {
    @State private var alarmName = "Take Medicine"
    @State private var alarmTime = Date()
    @State private var currentActivity: Activity<AlarmAttributes>?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("ADHD Alarms")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Alarm Name:")
                TextField("Enter alarm name", text: $alarmName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("Time:")
                DatePicker("Alarm Time", selection: $alarmTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
            }
            
            Button(action: {
                if currentActivity == nil {
                    startAlarmActivity()
                } else {
                    stopAlarmActivity()
                }
            }) {
                Text(currentActivity == nil ? "Start Alarm" : "Stop Alarm")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(currentActivity == nil ? Color.blue : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
    
    private func startAlarmActivity() {
        let attributes = AlarmAttributes(name: alarmName)
        let contentState = AlarmAttributes.ContentState(alarmTime: alarmTime)
        
        do {
            currentActivity = try Activity<AlarmAttributes>.request(
                attributes: attributes,
                contentState: contentState,
                pushType: nil
            )
        } catch {
            print("Error starting activity: \(error)")
        }
    }
    
    private func stopAlarmActivity() {
        Task {
            await currentActivity?.end(dismissalPolicy: .immediate)
            currentActivity = nil
        }
    }
}

#Preview {
    ContentView()
}
