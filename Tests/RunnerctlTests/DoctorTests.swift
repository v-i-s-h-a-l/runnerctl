import XCTest
@testable import RunnerctlCore

final class DoctorTests: XCTestCase {
    func testReportsCorruptStateAsFailure() throws {
        let home = temporaryHome()
        let store = StateStore(homePath: home)
        try store.ensureDirectories()
        try "{not-json".write(toFile: store.stateFilePath, atomically: true, encoding: .utf8)

        let checks = Doctor(stateStore: store, executor: SuccessfulDoctorExecutor()).runChecks()

        XCTAssertEqual(checks.first(where: { $0.id == "state.parse" })?.severity, .fail)
        XCTAssertTrue(checks.first(where: { $0.id == "state.parse" })?.fix?.contains("Repair or remove") == true)
    }

    func testReportsMissingRunnerDirectoryAsFailure() throws {
        let home = temporaryHome()
        let missingDirectory = "\(home)/runners/missing"
        let store = StateStore(homePath: home)
        try store.save(RunnerctlState(
            schemaVersion: RunnerctlState.currentSchemaVersion,
            profiles: [],
            runners: [runnerRecord(directory: missingDirectory)],
            lastDoctorRun: nil
        ))

        let checks = Doctor(stateStore: store, executor: SuccessfulDoctorExecutor()).runChecks()

        XCTAssertEqual(checks.first(where: { $0.id == "runner.directory.mac-mini" })?.severity, .fail)
        XCTAssertTrue(checks.first(where: { $0.id == "runner.directory.mac-mini" })?.fix?.contains("runnerctl repair owner/repo") == true)
    }

    func testReportsMissingRunnerExecutableAsFailure() throws {
        let home = temporaryHome()
        let runnerDirectory = "\(home)/runners/repo"
        try FileManager.default.createDirectory(atPath: runnerDirectory, withIntermediateDirectories: true)
        let store = StateStore(homePath: home)
        try store.save(RunnerctlState(
            schemaVersion: RunnerctlState.currentSchemaVersion,
            profiles: [],
            runners: [runnerRecord(directory: runnerDirectory)],
            lastDoctorRun: nil
        ))

        let checks = Doctor(stateStore: store, executor: SuccessfulDoctorExecutor()).runChecks()

        XCTAssertEqual(checks.first(where: { $0.id == "runner.directory.mac-mini" })?.severity, .info)
        XCTAssertEqual(checks.first(where: { $0.id == "runner.executable.mac-mini" })?.severity, .fail)
        XCTAssertTrue(checks.first(where: { $0.id == "runner.executable.mac-mini" })?.fix?.contains("reinstall") == true)
    }

    func testAppDoctorExitsOneForCorruptStateJSON() throws {
        let home = temporaryHome()
        let store = StateStore(homePath: home)
        try store.ensureDirectories()
        try "{not-json".write(toFile: store.stateFilePath, atomically: true, encoding: .utf8)

        let output = CapturingOutput()
        let app = RunnerctlApp(
            output: output,
            errorOutput: CapturingOutput(),
            executor: SuccessfulDoctorExecutor(),
            environment: ["RUNNERCTL_HOME": home]
        )

        let exitCode = app.run(arguments: ["doctor", "--json"])

        XCTAssertEqual(exitCode, 1)
        XCTAssertTrue(output.text.contains("\"id\" : \"state.parse\""))
        XCTAssertTrue(output.text.contains("\"ok\" : false"))
    }

    func testReportsUnavailableSavedProfileAsFailure() throws {
        let home = temporaryHome()
        let store = StateStore(homePath: home)
        try store.save(RunnerctlState(
            schemaVersion: RunnerctlState.currentSchemaVersion,
            profiles: [
                Profile(
                    name: "work",
                    githubLogin: "octo-user",
                    hostname: "github.com",
                    credentialSource: "gh",
                    active: true,
                    updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
                )
            ],
            runners: [],
            lastDoctorRun: nil
        ))

        let checks = Doctor(stateStore: store, executor: MissingGitHubProfileExecutor()).runChecks()

        XCTAssertEqual(checks.first(where: { $0.id == "auth.profile.work" })?.severity, .fail)
        XCTAssertTrue(checks.first(where: { $0.id == "auth.profile.work" })?.fix?.contains("runnerctl login --profile work") == true)
    }

    func testHumanOutputGroupsChecks() {
        let response = DoctorResponse(
            schemaVersion: 1,
            command: "doctor",
            ok: false,
            home: "/tmp/runnerctl",
            checks: [
                DoctorCheck(id: "host.launchd", label: "Service manager", severity: .info, message: "launchd is available.", fix: nil),
                DoctorCheck(id: "state.parse", label: "State parse", severity: .fail, message: "Could not parse state.", fix: "Repair state."),
                DoctorCheck(id: "runners.none", label: "Runners", severity: .info, message: "No runners registered yet.", fix: nil)
            ],
            summary: DoctorSummary(checks: [
                DoctorCheck(id: "host.launchd", label: "Service manager", severity: .info, message: "launchd is available.", fix: nil),
                DoctorCheck(id: "state.parse", label: "State parse", severity: .fail, message: "Could not parse state.", fix: "Repair state."),
                DoctorCheck(id: "runners.none", label: "Runners", severity: .info, message: "No runners registered yet.", fix: nil)
            ]),
            warnings: [],
            errors: []
        )

        let output = HumanDoctorRenderer().render(response)

        XCTAssertTrue(output.contains("Host:"))
        XCTAssertTrue(output.contains("State:"))
        XCTAssertTrue(output.contains("Runners:"))
        XCTAssertTrue(output.contains("Fix: Repair state."))
    }

    private func runnerRecord(directory: String) -> RunnerRecord {
        RunnerRecord(
            target: "owner/repo",
            scope: "repo",
            name: "mac-mini",
            directory: directory,
            labels: ["self-hosted", "macOS", "ARM64"],
            profile: "default"
        )
    }

    private func temporaryHome() -> String {
        let path = "\(NSTemporaryDirectory())runnerctl-tests-\(UUID().uuidString)"
        addTeardownBlock {
            try? FileManager.default.removeItem(atPath: path)
        }
        return path
    }
}

private struct SuccessfulDoctorExecutor: CommandExecuting {
    func run(_ executable: String, arguments: [String]) -> CommandResult {
        switch "\(executable) \(arguments.joined(separator: " "))" {
        case "/usr/bin/uname -m":
            return CommandResult(exitCode: 0, output: "arm64\n")
        case "/bin/launchctl print system":
            return CommandResult(exitCode: 0, output: "")
        case "/usr/bin/xcode-select -p":
            return CommandResult(exitCode: 0, output: "/Applications/Xcode.app/Contents/Developer\n")
        case "/usr/bin/xcodebuild -license check":
            return CommandResult(exitCode: 0, output: "")
        case "/usr/bin/curl -Is --max-time 5 https://api.github.com":
            return CommandResult(exitCode: 0, output: "HTTP/2 200\n")
        default:
            return CommandResult(exitCode: 0, output: "")
        }
    }
}

private struct MissingGitHubProfileExecutor: CommandExecuting {
    func run(_ executable: String, arguments: [String]) -> CommandResult {
        if executable == "/usr/bin/env", arguments == ["gh", "auth", "status"] {
            return CommandResult(exitCode: 1, output: "github.com\n  X Failed to log in to github.com account octo-user\n")
        }
        return SuccessfulDoctorExecutor().run(executable, arguments: arguments)
    }
}
