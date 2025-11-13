//
//  Managers.swift
//  Barpath
//
//  Settings and History persistence managers
//

import Foundation
import Combine

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    @Published var settings: AppSettings

    private let settingsKey = "app_settings"

    init() {
        // Load settings from UserDefaults
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = decoded
        } else {
            self.settings = .default
        }
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: settingsKey)
        }
    }

    func reset() {
        settings = .default
        save()
    }
}

// MARK: - History Manager
class HistoryManager: ObservableObject {
    @Published var sessions: [Session] = []

    private let sessionsKey = "sessions"
    private let documentsPath: URL

    init() {
        // Get documents directory
        documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        // Load sessions
        loadSessions()
    }

    func addSession(_ session: Session) {
        sessions.insert(session, at: 0) // Most recent first
        saveSessions()
    }

    func updateSession(_ session: Session) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
            saveSessions()
        }
    }

    func deleteSession(_ session: Session) {
        sessions.removeAll { $0.id == session.id }

        // Clean up files
        try? FileManager.default.removeItem(at: session.videoURL)
        if let overlayURL = session.overlayVideoURL {
            try? FileManager.default.removeItem(at: overlayURL)
        }
        if let csvURL = session.csvURL {
            try? FileManager.default.removeItem(at: csvURL)
        }

        saveSessions()
    }

    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([Session].self, from: data) {
            self.sessions = decoded
        }
    }

    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }

    // Get file URL for session
    func getVideoURL(for sessionId: UUID) -> URL {
        documentsPath.appendingPathComponent("\(sessionId.uuidString).mp4")
    }

    func getOverlayVideoURL(for sessionId: UUID) -> URL {
        documentsPath.appendingPathComponent("\(sessionId.uuidString)_overlay.mp4")
    }

    func getCSVURL(for sessionId: UUID) -> URL {
        documentsPath.appendingPathComponent("\(sessionId.uuidString).csv")
    }
}
