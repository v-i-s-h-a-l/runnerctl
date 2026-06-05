import Foundation

/// A JSON error item.
struct CommandError: Codable, Equatable {
    var code: String
    var message: String
    var fix: String
}

/// JSON response for command failures.
struct ErrorResponse: Codable, Equatable {
    var schemaVersion: Int
    var command: String
    var ok: Bool
    var warnings: [String]
    var errors: [CommandError]
}

/// JSON response for `login`.
struct LoginResponse: Codable, Equatable {
    var schemaVersion: Int
    var command: String
    var ok: Bool
    var profile: String
    var githubLogin: String
    var hostname: String
    var credentialSource: String
    var warnings: [String]
    var errors: [CommandError]
}
