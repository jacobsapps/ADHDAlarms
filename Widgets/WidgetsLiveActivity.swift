//
//  WidgetsLiveActivity.swift
//  Widgets
//
//  Created by Jacob Bartlett on 03/07/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AlarmAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var alarmTime: Date
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text(context.attributes.name)
                    .font(.headline)
                Text(context.state.alarmTime, style: .time)
                    .font(.title)
                    .foregroundColor(.white)
                
                HStack(spacing: 20) {
                    Button(intent: SnoozeAlarmIntent(alarmName: context.attributes.name)) {
                        Text("Snooze")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(intent: DismissAlarmIntent(alarmName: context.attributes.name)) {
                        Text("Dismiss")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 8)
            }
            .activityBackgroundTint(Color.blue)
            .activitySystemActionForegroundColor(Color.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "alarm")
                        .foregroundColor(.blue)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.alarmTime, style: .time)
                        .font(.caption)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack {
                        Text(context.attributes.name)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            Button(intent: SnoozeAlarmIntent(alarmName: context.attributes.name)) {
                                Text("Snooze")
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                            
                            Button(intent: DismissAlarmIntent(alarmName: context.attributes.name)) {
                                Text("Dismiss")
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(6)
                            }
                        }
                        .padding(.top, 4)
                    }
                }
            } compactLeading: {
                Image(systemName: "alarm")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text(context.state.alarmTime, style: .time)
                    .font(.caption2)
            } minimal: {
                Image(systemName: "alarm")
                    .foregroundColor(.blue)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.blue)
        }
    }
}

extension AlarmAttributes {
    fileprivate static var preview: AlarmAttributes {
        AlarmAttributes(name: "Take Medicine")
    }
}

extension AlarmAttributes.ContentState {
    fileprivate static var sampleAlarm: AlarmAttributes.ContentState {
        AlarmAttributes.ContentState(alarmTime: Date())
     }
     
     fileprivate static var futureAlarm: AlarmAttributes.ContentState {
         AlarmAttributes.ContentState(alarmTime: Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date())
     }
}

#Preview("Notification", as: .content, using: AlarmAttributes.preview) {
   WidgetsLiveActivity()
} contentStates: {
    AlarmAttributes.ContentState.sampleAlarm
    AlarmAttributes.ContentState.futureAlarm
}
