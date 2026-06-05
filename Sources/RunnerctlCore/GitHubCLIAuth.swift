import Foundation

/// A GitHub credential discovered from `gh auth status`.
struct GitHubCredential: Equatable {
    var login: String
    var hostname: String
    var isActive: Bool
    var warnings: [String]
}

/// Detects usable GitHub CLI credentials without reading token material.
struct GitHubCLICredentialDetector {
    let executor: CommandExecuting

    /// Returns a usable GitHub CLI credential.
    func detectCredential(account: String?) throws -> GitHubCredential {
        let result = executor.run("/usr/bin/env", arguments: ["gh", "auth", "status"])
        let credentials = Self.parseAuthStatus(result.output)

        guard !credentials.isEmpty else {
            throw RunnerctlError.authUnavailable("No valid GitHub CLI credential was found.")
        }

        if let account {
            guard let credential = credentials.first(where: { $0.login == account }) else {
                throw RunnerctlError.authAccountNotFound("No valid GitHub CLI credential was found for account \(account).")
            }
            return credential
        }

        if let active = credentials.first(where: { $0.isActive }) {
            return active
        }

        return credentials[0]
    }

    /// Parses `gh auth status` output.
    static func parseAuthStatus(_ output: String) -> [GitHubCredential] {
        var hostname = "github.com"
        var parsed: [GitHubCredential] = []
        var currentIndex: Int?

        for line in output.split(separator: "\n", omittingEmptySubsequences: false).map(String.init) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.hasPrefix("-"), !trimmed.hasPrefix("X "), !trimmed.hasPrefix("✓ "), !trimmed.isEmpty {
                hostname = trimmed
            }

            if let login = loginName(fromLoggedInLine: trimmed) {
                parsed.append(GitHubCredential(login: login, hostname: hostname, isActive: false, warnings: []))
                currentIndex = parsed.count - 1
                continue
            }

            if trimmed == "- Active account: true", let currentIndex {
                parsed[currentIndex].isActive = true
            }
        }

        if parsed.count > 1 {
            for index in parsed.indices where !parsed[index].isActive {
                parsed[index].warnings.append("Multiple GitHub CLI accounts were detected; this account is not active.")
            }
        }

        return parsed
    }

    private static func loginName(fromLoggedInLine line: String) -> String? {
        guard line.contains("Logged in to"), let range = line.range(of: " account ") else {
            return nil
        }
        let suffix = line[range.upperBound...]
        let login = suffix.split(separator: " ").first.map(String.init) ?? ""
        return login.isEmpty ? nil : login
    }
}
