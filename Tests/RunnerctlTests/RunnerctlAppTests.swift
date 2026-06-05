import XCTest
@testable import RunnerctlCore

final class RunnerctlAppTests: XCTestCase {
    func testLoginWritesJSONAndState() throws {
        let home = temporaryHome()
        let output = CapturingOutput()
        let errorOutput = CapturingOutput()
        let executor = FakeExecutor(results: [
            "/usr/bin/env gh auth status": CommandResult(exitCode: 0, output: """
            github.com
              ✓ Logged in to github.com account vishal (/tmp/hosts.yml)
              - Active account: true
            """)
        ])
        let app = RunnerctlApp(
            output: output,
            errorOutput: errorOutput,
            executor: executor,
            environment: ["RUNNERCTL_HOME": home]
        )

        let exitCode = app.run(arguments: ["login", "--json"])

        XCTAssertEqual(exitCode, 0)
        XCTAssertTrue(output.text.contains("\"githubLogin\" : \"vishal\""))
        let state = try StateStore(homePath: home).loadOrCreate()
        XCTAssertEqual(state.profiles.first?.githubLogin, "vishal")
        XCTAssertEqual(errorOutput.text, "")
    }

    func testLoginChecksTargetRunnerPermissions() throws {
        let home = temporaryHome()
        let output = CapturingOutput()
        let errorOutput = CapturingOutput()
        let executor = FakeExecutor(results: [
            "/usr/bin/env gh auth status": CommandResult(exitCode: 0, output: """
            github.com
              ✓ Logged in to github.com account vishal (/tmp/hosts.yml)
              - Active account: true
            """),
            "/usr/bin/env gh auth token --hostname github.com --user vishal": CommandResult(exitCode: 0, output: "secret\n")
        ])
        let githubTransport = RecordingGitHubTransport(responses: [
            "GET /repos/owner/repo/actions/runners?per_page=1": GitHubAPIResponse(statusCode: 200, body: Data()),
            "POST /repos/owner/repo/actions/runners/registration-token": GitHubAPIResponse(statusCode: 201, body: Data())
        ])
        let app = RunnerctlApp(
            output: output,
            errorOutput: errorOutput,
            executor: executor,
            githubTransport: githubTransport,
            environment: ["RUNNERCTL_HOME": home]
        )

        let exitCode = app.run(arguments: ["login", "--check-target", "owner/repo", "--json"])

        XCTAssertEqual(exitCode, 0)
        XCTAssertTrue(output.text.contains("\"target\" : \"owner\\/repo\""))
        XCTAssertTrue(output.text.contains("\"createRegistrationToken\" : true"))
        XCTAssertEqual(errorOutput.text, "")
    }

    func testLoginTargetPermissionFailureWritesJSONError() {
        let home = temporaryHome()
        let output = CapturingOutput()
        let errorOutput = CapturingOutput()
        let executor = FakeExecutor(results: [
            "/usr/bin/env gh auth status": CommandResult(exitCode: 0, output: """
            github.com
              ✓ Logged in to github.com account vishal (/tmp/hosts.yml)
              - Active account: true
            """),
            "/usr/bin/env gh auth token --hostname github.com --user vishal": CommandResult(exitCode: 0, output: "secret\n")
        ])
        let githubTransport = RecordingGitHubTransport(responses: [
            "GET /orgs/acme/actions/runners?per_page=1": GitHubAPIResponse(statusCode: 403, body: Data())
        ])
        let app = RunnerctlApp(
            output: output,
            errorOutput: errorOutput,
            executor: executor,
            githubTransport: githubTransport,
            environment: ["RUNNERCTL_HOME": home]
        )

        let exitCode = app.run(arguments: ["login", "--check-target", "acme", "--scope", "org", "--json"])

        XCTAssertEqual(exitCode, 1)
        XCTAssertTrue(output.text.contains("\"code\" : \"github.permission_missing\""))
        XCTAssertTrue(output.text.contains("GitHub refused"))
        XCTAssertEqual(errorOutput.text, "")
    }

    private func temporaryHome() -> String {
        let path = "\(NSTemporaryDirectory())runnerctl-tests-\(UUID().uuidString)"
        addTeardownBlock {
            try? FileManager.default.removeItem(atPath: path)
        }
        return path
    }
}

private struct FakeExecutor: CommandExecuting {
    var results: [String: CommandResult]

    func run(_ executable: String, arguments: [String]) -> CommandResult {
        results["\(executable) \(arguments.joined(separator: " "))"] ?? CommandResult(exitCode: 127, output: "missing fake command")
    }
}
