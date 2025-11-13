//
//  BarpathApp.swift
//  Barpath
//
//  Track barbell movement during lifts
//

import SwiftUI

@main
struct BarpathApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var settingsManager = SettingsManager()
    @StateObject private var historyManager = HistoryManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(settingsManager)
                .environmentObject(historyManager)
        }
    }
}
