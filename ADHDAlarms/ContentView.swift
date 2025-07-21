//
//  ContentView.swift
//  ADHDAlarms
//
//  Created by Jacob Bartlett on 03/07/2025.
//

import SwiftUI
import ActivityKit
import AlarmKit
import AppIntents

struct ContentView: View {
    var body: some View {
        AlarmListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: AlarmModel.self, inMemory: true)
}

public struct OpenInApp: LiveActivityIntent {
    public func perform() async throws -> some IntentResult { .result() }
    
    public static var title: LocalizedStringResource = "Open App"
    public static var description = IntentDescription("Opens the Sample app")
    public static var openAppWhenRun = true
    
    @Parameter(title: "alarmID")
    public var alarmID: String
    
    public init(alarmID: String) {
        self.alarmID = alarmID
    }
    
    public init() {
        self.alarmID = ""
    }
}

//⏺ Update(ADHDAlarms/ContentView.swift)
//  ⎿  Updated ADHDAlarms/ContentView.swift with 2 additions and 121 removals
//        11    import AppIntents
//        12
//        13    struct ContentView: View {
//        14 -      @State private var alarmName = "Take Medicine"
//        15 -      @State private var alarmTime = Date()
//        16 -      @State private var showPermissionsDeniedAlert = false
//        17 -
//        14        var body: some View {
//        15 -          NavigationView {
//        16 -              Text("Hello, world!")
//        17 -          }
//        18 -          .navigationTitle("ADHD Alarms")
//        19 -          .padding()
//        20 -          .task {
//        21 -              do {
//        22 -                  try await alarmAuthorization()
//        23 -              } catch {
//        24 -                  print(error)
//        25 -                  print()
//        26 -              }
//        27 -          }
//        15 +          AlarmListView()
//        16        }
//        17 -
//        18 -      private func alarmAuthorization() async throws {
//        19 -          switch try await AlarmManager.shared.requestAuthorization() {
//        20 -          case .notDetermined:
//        21 -              try await alarmAuthorization()
//        22 -          case .authorized:
//        23 -              try await setupImminentAlarm()
//        24 -          case .denied:
//        25 -              showPermissionsDeniedAlert = true
//        26 -          @unknown default:
//        27 -              break
//        28 -          }
//        29 -      }
//        30 -
//        31 -      private func setupImminentAlarm() async throws {
//        32 -          let tenSecondsFromNow = Date().addingTimeInterval(3)
//        33 -          let schedule = Alarm.Schedule.fixed(tenSecondsFromNow)
//        34 -          try await scheduleAlarm(at: schedule)
//        35 -      }
//        36 -
//        37 -      private func setFixedDateAlarm() async throws {
//        38 -          let specificComponents = DateComponents(
//        39 -              calendar: Calendar.current,
//        40 -              year: 2025,
//        41 -              month: 7,
//        42 -              day: 4,
//        43 -              hour: 17,
//        44 -              minute: 0,
//        45 -              second: 0
//        46 -          )
//        47 -          guard let date = specificComponents.date else {
//        48 -              return
//        49 -          }
//        50 -          let schedule = Alarm.Schedule.fixed(date)
//        51 -          try await scheduleAlarm(at: schedule)
//        52 -      }
//        53 -
//        54 -      private func setStandupAlarm() async throws {
//        55 -          let schedule = Alarm.Schedule.relative(Alarm.Schedule.Relative(
//        56 -              time: Alarm.Schedule.Relative.Time(hour: 10, minute: 0),
//        57 -              repeats: Alarm.Schedule.Relative.Recurrence.weekly(
//        58 -                  [.monday, .tuesday, .wednesday, .thursday, .friday]
//        59 -              ))
//        60 -          )
//        61 -          try await scheduleAlarm(at: schedule)
//        62 -      }
//        63 -
//        64 -      func scheduleAlarm(at schedule: Alarm.Schedule) async throws {
//        65 -
//        66 -          let id = UUID()
//        67 -
//        68 -          let stopButton = AlarmButton(
//        69 -              text: "Mmm, Elvanse",
//        70 -              textColor: .white,
//        71 -              systemImageName: "checkmark.seal.fill"
//        72 -          )
//        73 -
//        74 -          let repeatButton = AlarmButton(
//        75 -              text: "I forgot",
//        76 -              textColor: .red,
//        77 -              systemImageName: "repeat.circle.fill"
//        78 -          )
//        79 -
//        80 -          let alertPresentation = AlarmPresentation.Alert(
//        81 -              title: "Take your meds!",
//        82 -              stopButton: stopButton,
//        83 -              secondaryButton: repeatButton,
//        84 -              secondaryButtonBehavior: .countdown
//        85 -          )
//        86 -
//        87 -          let attributes = AlarmAttributes(
//        88 -              presentation: AlarmPresentation(alert: alertPresentation),
//        89 -              metadata: ADHDMetadata(),
//        90 -              tintColor: Color.orange
//        91 -          )
//        92 -
//        93 -          let alarmConfiguration = AlarmManager.AlarmConfiguration<ADHDMetadata>
//        94 -              .alarm(
//        95 -                  schedule: schedule,
//        96 -                  attributes: attributes
//        97 -  //                stopIntent: myStopIntent,
//        98 -  //                secondaryIntent: myCustomIntent,
//        99 -  //                sound: AlertConfiguration.AlertSound.named("customSound")
//       100 -              )
//       101 -
//       102 -  //        let timerConfiguration = AlarmManager.AlarmConfiguration<ADHDMetadata>
//       103 -  //            .timer(
//       104 -  //                duration: 10,
//       105 -  //                attributes: attributes
//       106 -  //            )
//       107 -  //
//       108 -  //        let countdownConfiguration =
//           - AlarmManager.AlarmConfiguration<ADHDMetadata>
//       109 -  //            .init(
//       110 -  //                countdownDuration: Alarm.CountdownDuration(preAlert: 10,
//           - postAlert: 10),
//       111 -  //                attributes: attributes
//       112 -  //            )
//       113 -
//       114 -          _ = try await AlarmManager.shared.schedule(id: id, configuration:
//           - alarmConfiguration)
//       115 -      }
//        17    }
//        18
//        19    #Preview {
//        20        ContentView()
//        21 +          .modelContainer(for: AlarmModel.self, inMemory: true)
//        22    }
//        23
//        24 -
//        25 -  struct ADHDMetadata: AlarmMetadata {
//        26 -      init() {}
//        27 -  }
//        28 -
