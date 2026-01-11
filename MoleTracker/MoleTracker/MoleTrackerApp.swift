//
//  MoleTrackerApp.swift
//  MoleTracker
//
//  Created by Wolfram Richter on 06.01.26.
//


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
        .modelContainer(for: [Mole.self, MoleImage.self])
    }
}