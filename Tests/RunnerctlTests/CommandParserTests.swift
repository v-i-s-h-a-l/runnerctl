import XCTest
@testable import RunnerctlCore

final class CommandParserTests: XCTestCase {
    func testParsesGlobalFlagsAroundCommand() throws {
        let invocation = try CommandParser().parse(["--json", "login", "--account", "vishal", "--home", "/tmp/runnerctl"])

        XCTAssertEqual(invocation.command, "login")
        XCTAssertEqual(invocation.commandArguments, ["--account", "vishal"])
        XCTAssertTrue(invocation.global.json)
        XCTAssertEqual(invocation.global.home, "/tmp/runnerctl")
    }

    func testRequiresGlobalFlagValue() {
        XCTAssertThrowsError(try CommandParser().parse(["--home"])) { error in
            XCTAssertEqual(error as? RunnerctlError, .usage("Missing value for --home."))
        }
    }
}
