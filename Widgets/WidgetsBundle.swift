//
//  WidgetsBundle.swift
//  Widgets
//
//  Created by Jacob Bartlett on 03/07/2025.
//

import WidgetKit
import SwiftUI

@main
struct WidgetsBundle: WidgetBundle {
    var body: some Widget {
        Widgets()
        WidgetsControl()
        WidgetsLiveActivity()
    }
}
