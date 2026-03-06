import Foundation
import FocusCore

struct AppSettings: Codable, Sendable {
    var selectedDurationMinutes: Int
    var blockedAppBundleIDs: [String]
    var notificationsEnabled: Bool

    static let `default` = AppSettings(
        selectedDurationMinutes: 25,
        blockedAppBundleIDs: [],
        notificationsEnabled: true
    )
}

struct SessionHistoryEntry: Codable, Identifiable, Sendable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let durationSeconds: Int
    let finalPhase: SessionPhase
    let blockedBundleIDs: [String]
}

struct PersistedState: Codable, Sendable {
    var settings: AppSettings
    var history: [SessionHistoryEntry]

    static let `default` = PersistedState(settings: .default, history: [])
}

actor PersistenceStore {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let settingsURL: URL
    private let historyURL: URL

    init(fileManager: FileManager = .default, bundleID: String = Bundle.main.bundleIdentifier ?? "MyFocus") {
        self.fileManager = fileManager

        let baseDirectory = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent(bundleID, isDirectory: true)

        settingsURL = baseDirectory.appendingPathComponent("settings.json", isDirectory: false)
        historyURL = baseDirectory.appendingPathComponent("history.json", isDirectory: false)

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func loadState() -> PersistedState {
        createDirectoryIfNeeded()

        let settings = loadSettings()
        let history = loadHistory()

        return PersistedState(settings: settings, history: history)
    }

    func saveSettings(_ settings: AppSettings) {
        createDirectoryIfNeeded()

        do {
            let data = try encoder.encode(settings)
            try data.write(to: settingsURL, options: [.atomic])
        } catch {
            print("[PersistenceStore] failed to save settings: \(error)")
        }
    }

    func appendHistory(_ entry: SessionHistoryEntry) {
        createDirectoryIfNeeded()

        var history = loadHistory()
        history.insert(entry, at: 0)

        do {
            let data = try encoder.encode(history)
            try data.write(to: historyURL, options: [.atomic])
        } catch {
            print("[PersistenceStore] failed to save history: \(error)")
        }
    }

    private func loadSettings() -> AppSettings {
        guard fileManager.fileExists(atPath: settingsURL.path) else {
            return .default
        }

        do {
            let data = try Data(contentsOf: settingsURL)
            return try decoder.decode(AppSettings.self, from: data)
        } catch {
            print("[PersistenceStore] failed to load settings: \(error)")
            return .default
        }
    }

    private func loadHistory() -> [SessionHistoryEntry] {
        guard fileManager.fileExists(atPath: historyURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: historyURL)
            return try decoder.decode([SessionHistoryEntry].self, from: data)
        } catch {
            print("[PersistenceStore] failed to load history: \(error)")
            return []
        }
    }

    private func createDirectoryIfNeeded() {
        let baseDirectory = settingsURL.deletingLastPathComponent()

        guard !fileManager.fileExists(atPath: baseDirectory.path) else {
            return
        }

        do {
            try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        } catch {
            print("[PersistenceStore] failed to create app support directory: \(error)")
        }
    }
}
