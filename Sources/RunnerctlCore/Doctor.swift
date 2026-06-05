import Foundation

/// A single doctor check result.
struct DoctorCheck: Codable, Equatable {
    var id: String
    var label: String
    var severity: CheckSeverity
    var message: String
    var fix: String?
}

/// Severity for a doctor check.
enum CheckSeverity: String, Codable {
    case info
    case warn
    case fail
}

/// Summary counts for doctor output.
struct DoctorSummary: Codable, Equatable {
    var infoCount: Int
    var warnCount: Int
    var failCount: Int

    init(checks: [DoctorCheck]) {
        infoCount = checks.filter { $0.severity == .info }.count
        warnCount = checks.filter { $0.severity == .warn }.count
        failCount = checks.filter { $0.severity == .fail }.count
    }
}

/// JSON response for `doctor`.
struct DoctorResponse: Codable, Equatable {
    var schemaVersion: Int
    var command: String
    var ok: Bool
    var home: String
    var checks: [DoctorCheck]
    var summary: DoctorSummary
    var warnings: [String]
    var errors: [CommandError]
}

/// Runs host readiness checks.
struct Doctor {
    let stateStore: StateStore
    let executor: CommandExecuting

    /// Runs all checks available in the current M1 scaffold.
    func runChecks() -> [DoctorCheck] {
        var checks: [DoctorCheck] = []
        checks.append(checkHostPlatform())
        checks.append(checkLaunchd())
        checks.append(checkDiskFree())
        checks.append(checkCommandLineTools())
        checks.append(checkXcodeLicense())
        checks.append(checkGitHubNetwork())
        checks.append(checkStateDirectory())

        switch loadStateForChecks() {
        case .loaded(let state):
            checks.append(contentsOf: checkProfiles(in: state))
            checks.append(contentsOf: checkRunnerDirectories(in: state))
        case .failed(let check):
            checks.append(check)
        }

        return checks
    }

    private func checkHostPlatform() -> DoctorCheck {
        #if os(macOS)
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let architecture = executor.run("/usr/bin/uname", arguments: ["-m"]).output.trimmingCharacters(in: .whitespacesAndNewlines)
        return DoctorCheck(
            id: "host.platform",
            label: "Host platform",
            severity: .info,
            message: "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion), \(architecture)",
            fix: nil
        )
        #else
        return DoctorCheck(
            id: "host.platform",
            label: "Host platform",
            severity: .warn,
            message: "This M1 scaffold only implements macOS doctor checks.",
            fix: "Use macOS for M1 dogfooding; Linux backend lands in M4."
        )
        #endif
    }

    private func checkLaunchd() -> DoctorCheck {
        let result = executor.run("/bin/launchctl", arguments: ["print", "system"])
        if result.exitCode == 0 {
            return DoctorCheck(id: "host.launchd", label: "Service manager", severity: .info, message: "launchd is available.", fix: nil)
        }
        return DoctorCheck(id: "host.launchd", label: "Service manager", severity: .fail, message: "launchd did not respond.", fix: "Run `launchctl print system` and inspect the error.")
    }

    private func checkDiskFree() -> DoctorCheck {
        do {
            let values = try URL(fileURLWithPath: stateStore.homePath).resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            let bytes = values.volumeAvailableCapacityForImportantUsage ?? 0
            let gigabytes = Double(bytes) / 1_000_000_000
            if gigabytes < 15 {
                return DoctorCheck(id: "host.disk", label: "Disk free", severity: .fail, message: String(format: "%.1f GB available.", gigabytes), fix: "Free disk space before registering runners.")
            }
            if gigabytes < 50 {
                return DoctorCheck(id: "host.disk", label: "Disk free", severity: .warn, message: String(format: "%.1f GB available.", gigabytes), fix: "Free disk space or move RUNNERCTL_HOME to a larger volume.")
            }
            return DoctorCheck(id: "host.disk", label: "Disk free", severity: .info, message: String(format: "%.1f GB available.", gigabytes), fix: nil)
        } catch {
            return DoctorCheck(id: "host.disk", label: "Disk free", severity: .warn, message: "Could not read available disk capacity: \(error)", fix: "Check permissions for \(stateStore.homePath).")
        }
    }

    private func checkCommandLineTools() -> DoctorCheck {
        let result = executor.run("/usr/bin/xcode-select", arguments: ["-p"])
        if result.exitCode == 0 {
            return DoctorCheck(id: "host.clt", label: "Command line tools", severity: .info, message: result.output.trimmingCharacters(in: .whitespacesAndNewlines), fix: nil)
        }
        return DoctorCheck(id: "host.clt", label: "Command line tools", severity: .fail, message: "Xcode command line tools are not selected.", fix: "Run `xcode-select --install`.")
    }

    private func checkXcodeLicense() -> DoctorCheck {
        let result = executor.run("/usr/bin/xcodebuild", arguments: ["-license", "check"])
        if result.exitCode == 0 {
            return DoctorCheck(id: "host.xcode_license", label: "Xcode license", severity: .info, message: "Accepted.", fix: nil)
        }
        return DoctorCheck(id: "host.xcode_license", label: "Xcode license", severity: .warn, message: "Xcode license check did not pass.", fix: "Run `sudo xcodebuild -license accept`.")
    }

    private func checkGitHubNetwork() -> DoctorCheck {
        let result = executor.run("/usr/bin/curl", arguments: ["-Is", "--max-time", "5", "https://api.github.com"])
        if result.exitCode == 0 {
            return DoctorCheck(id: "host.github_network", label: "GitHub network", severity: .info, message: "api.github.com reachable.", fix: nil)
        }
        return DoctorCheck(id: "host.github_network", label: "GitHub network", severity: .fail, message: "api.github.com is not reachable.", fix: "Check network connectivity, proxy, VPN, or firewall settings.")
    }

    private func checkStateDirectory() -> DoctorCheck {
        if FileManager.default.fileExists(atPath: stateStore.stateFilePath) {
            return DoctorCheck(id: "state.file", label: "State file", severity: .info, message: stateStore.stateFilePath, fix: nil)
        }
        return DoctorCheck(id: "state.file", label: "State file", severity: .info, message: "No state file yet at \(stateStore.stateFilePath).", fix: nil)
    }

    private enum StateLoadResult {
        case loaded(RunnerctlState?)
        case failed(DoctorCheck)
    }

    private func loadStateForChecks() -> StateLoadResult {
        do {
            return .loaded(try stateStore.loadExisting())
        } catch {
            return .failed(DoctorCheck(
                id: "state.parse",
                label: "State parse",
                severity: .fail,
                message: "Could not parse \(stateStore.stateFilePath): \(error)",
                fix: "Repair or remove \(stateStore.stateFilePath), then run `runnerctl doctor` again."
            ))
        }
    }

    private func checkRunnerDirectories(in state: RunnerctlState?) -> [DoctorCheck] {
        guard let state, !state.runners.isEmpty else {
            return [DoctorCheck(id: "runners.none", label: "Runners", severity: .info, message: "No runners registered yet.", fix: nil)]
        }

        return state.runners.flatMap { runner in
            checkRunnerDirectory(runner)
        }
    }

    private func checkRunnerDirectory(_ runner: RunnerRecord) -> [DoctorCheck] {
        guard FileManager.default.fileExists(atPath: runner.directory) else {
            return [DoctorCheck(id: "runner.directory.\(runner.name)", label: "Runner directory", severity: .fail, message: "\(runner.target): missing \(runner.directory)", fix: "Run `runnerctl repair \(runner.target)`.")]
        }

        var checks = [
            DoctorCheck(id: "runner.directory.\(runner.name)", label: "Runner directory", severity: .info, message: "\(runner.target): \(runner.directory)", fix: nil)
        ]

        if FileManager.default.isWritableFile(atPath: runner.directory) {
            checks.append(DoctorCheck(id: "runner.directory_writable.\(runner.name)", label: "Runner directory permissions", severity: .info, message: "\(runner.target): writable.", fix: nil))
        } else {
            checks.append(DoctorCheck(id: "runner.directory_writable.\(runner.name)", label: "Runner directory permissions", severity: .fail, message: "\(runner.target): directory is not writable.", fix: "Run `chmod u+w \(runner.directory)` or move the runner with `runnerctl repair \(runner.target)`."))
        }

        let runnerExecutable = "\(runner.directory)/run.sh"
        if FileManager.default.fileExists(atPath: runnerExecutable) {
            checks.append(DoctorCheck(id: "runner.executable.\(runner.name)", label: "Runner executable", severity: .info, message: "\(runner.target): run.sh exists.", fix: nil))
        } else {
            checks.append(DoctorCheck(id: "runner.executable.\(runner.name)", label: "Runner executable", severity: .fail, message: "\(runner.target): missing run.sh.", fix: "Run `runnerctl repair \(runner.target)` to reinstall the runner binary."))
        }

        return checks
    }

    private func checkProfiles(in state: RunnerctlState?) -> [DoctorCheck] {
        guard let state, !state.profiles.isEmpty else {
            return [DoctorCheck(id: "auth.profiles_none", label: "GitHub profiles", severity: .info, message: "No GitHub profiles saved yet.", fix: nil)]
        }

        return state.profiles.map { profile in
            do {
                _ = try GitHubCLICredentialDetector(executor: executor).detectCredential(account: profile.githubLogin)
                return DoctorCheck(id: "auth.profile.\(profile.name)", label: "GitHub profile", severity: .info, message: "\(profile.name): @\(profile.githubLogin) available through gh.", fix: nil)
            } catch {
                return DoctorCheck(id: "auth.profile.\(profile.name)", label: "GitHub profile", severity: .fail, message: "\(profile.name): @\(profile.githubLogin) is not available through gh.", fix: "Run `runnerctl login --profile \(profile.name) --account \(profile.githubLogin)` after refreshing `gh auth login`.")
            }
        }
    }
}

/// Renders human-readable doctor output.
struct HumanDoctorRenderer {
    func render(_ response: DoctorResponse) -> String {
        var lines: [String] = []
        lines.append("Runnerctl doctor")
        lines.append("")
        lines.append("Home: \(response.home)")
        lines.append("")
        for group in groupedChecks(response.checks) {
            lines.append("\(group.title):")
            for check in group.checks {
                lines.append("  \(marker(for: check.severity)) \(check.label): \(check.message)")
                if let fix = check.fix {
                    lines.append("    Fix: \(fix)")
                }
            }
            lines.append("")
        }
        lines.append("Summary: \(response.summary.failCount) fail, \(response.summary.warnCount) warn, \(response.summary.infoCount) info")
        return lines.joined(separator: "\n")
    }

    private func groupedChecks(_ checks: [DoctorCheck]) -> [(title: String, checks: [DoctorCheck])] {
        let groups: [(title: String, checks: [DoctorCheck])] = [
            (title: "Host", checks: checks.filter { $0.id.hasPrefix("host.") }),
            (title: "State", checks: checks.filter { $0.id.hasPrefix("state.") }),
            (title: "Auth", checks: checks.filter { $0.id.hasPrefix("auth.") }),
            (title: "Runners", checks: checks.filter { $0.id.hasPrefix("runner.") || $0.id.hasPrefix("runners.") })
        ]
        return groups.filter { !$0.checks.isEmpty }
    }

    private func marker(for severity: CheckSeverity) -> String {
        switch severity {
        case .info:
            return "[ok]"
        case .warn:
            return "[warn]"
        case .fail:
            return "[fail]"
        }
    }
}
