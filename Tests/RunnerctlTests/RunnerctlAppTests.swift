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
