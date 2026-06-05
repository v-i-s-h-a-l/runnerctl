import XCTest
@testable import RunnerctlCore

final class StateStoreTests: XCTestCase {
    func testCreatesAndRoundTripsState() throws {
        let home = temporaryHome()
        let store = StateStore(homePath: home)

        var state = try store.loadOrCreate()
        state.upsertProfile(Profile(
            name: "default",
            githubLogin: "vishal",
            hostname: "github.com",
            credentialSource: "gh",
            active: true,
            updatedAt: Date(timeIntervalSince1970: 1_700_000_000)
        ))
        try store.save(state)

        let loaded = try store.loadOrCreate()
        XCTAssertEqual(loaded.profiles.count, 1)
        XCTAssertEqual(loaded.profiles[0].githubLogin, "vishal")
        XCTAssertTrue(FileManager.default.fileExists(atPath: "\(home)/logs"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: "\(home)/cache"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: "\(home)/runners"))
    }

    private func temporaryHome() -> String {
        let path = "\(NSTemporaryDirectory())runnerctl-tests-\(UUID().uuidString)"
        addTeardownBlock {
            try? FileManager.default.removeItem(atPath: path)
        }
        return path
    }
}
