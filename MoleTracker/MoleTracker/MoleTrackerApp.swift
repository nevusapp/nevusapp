//
//  MoleTrackerApp.swift
//  MoleTracker
//
//  Created on 06.01.2026.
//

import SwiftUI
import SwiftData

@main
struct MoleTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Mole.self, MoleImage.self, BodyRegionOverview.self, MoleLocationMarker.self])
    }
}