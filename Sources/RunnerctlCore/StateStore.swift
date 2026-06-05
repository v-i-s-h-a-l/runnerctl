import Foundation

/// Persistent Runnerctl state.
struct RunnerctlState: Codable, Equatable {
    var schemaVersion: Int
    var profiles: [Profile]
    var runners: [RunnerRecord]
    var lastDoctorRun: Date?

    static let currentSchemaVersion = 1

    static var empty: RunnerctlState {
        RunnerctlState(schemaVersion: currentSchemaVersion, profiles: [], runners: [], lastDoctorRun: nil)
    }

    mutating func upsertProfile(_ profile: Profile) {
        if let index = profiles.firstIndex(where: { $0.name == profile.name }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
    }
}

/// A saved GitHub authentication profile.
struct Profile: Codable, Equatable {
    var name: String
    var githubLogin: String
    var hostname: String
    var credentialSource: String
    var active: Bool
    var updatedAt: Date
}

/// A local runner record.
struct RunnerRecord: Codable, Equatable {
    var target: String
    var scope: String
    var name: String
    var directory: String
    var labels: [String]
    var profile: String
}

/// Loads and saves Runnerctl's state file.
struct StateStore {
    let homePath: String

    var stateFilePath: String {
        "\(homePath)/state.json"
    }

    /// Loads state, creating the state directory and empty state file if needed.
    func loadOrCreate() throws -> RunnerctlState {
        try ensureDirectories()
        let fileURL = URL(fileURLWithPath: stateFilePath)
        guard FileManager.default.fileExists(atPath: stateFilePath) else {
            let state = RunnerctlState.empty
            try save(state)
            return state
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder.runnerctl.decode(RunnerctlState.self, from: data)
        } catch {
            throw RunnerctlError.state("Could not read Runnerctl state at \(stateFilePath): \(error)")
        }
    }

    /// Loads state if the state file exists.
    func loadExisting() throws -> RunnerctlState? {
        try ensureDirectories()
        guard FileManager.default.fileExists(atPath: stateFilePath) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: stateFilePath))
            return try JSONDecoder.runnerctl.decode(RunnerctlState.self, from: data)
        } catch {
            throw RunnerctlError.state("Could not read Runnerctl state at \(stateFilePath): \(error)")
        }
    }

    /// Saves state to disk.
    func save(_ state: RunnerctlState) throws {
        try ensureDirectories()
        let encoder = JSONEncoder.runnerctl
        do {
            let data = try encoder.encode(state)
            try data.write(to: URL(fileURLWithPath: stateFilePath), options: [.atomic])
        } catch {
            throw RunnerctlError.state("Could not write Runnerctl state at \(stateFilePath): \(error)")
        }
    }

    /// Updates the timestamp of the latest doctor run.
    func updateLastDoctorRun(_ date: Date) throws {
        var state = try loadOrCreate()
        state.lastDoctorRun = date
        try save(state)
    }

    func ensureDirectories() throws {
        do {
            try FileManager.default.createDirectory(atPath: homePath, withIntermediateDirectories: true)
            try FileManager.default.createDirectory(atPath: "\(homePath)/logs", withIntermediateDirectories: true)
            try FileManager.default.createDirectory(atPath: "\(homePath)/cache", withIntermediateDirectories: true)
            try FileManager.default.createDirectory(atPath: "\(homePath)/runners", withIntermediateDirectories: true)
        } catch {
            throw RunnerctlError.state("Could not create Runnerctl state directories under \(homePath): \(error)")
        }
    }
}

private extension JSONDecoder {
    static var runnerctl: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private extension JSONEncoder {
    static var runnerctl: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
