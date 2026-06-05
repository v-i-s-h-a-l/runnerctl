import XCTest
@testable import RunnerctlCore

final class GitHubTargetTests: XCTestCase {
    func testParsesRepositoryTarget() throws {
        let target = try GitHubTarget("owner/repo", scope: nil)

        XCTAssertEqual(target, .repository(owner: "owner", repo: "repo"))
        XCTAssertEqual(target.displayName, "owner/repo")
        XCTAssertEqual(target.scopeName, "repo")
        XCTAssertEqual(target.listRunnersPath, "/repos/owner/repo/actions/runners?per_page=1")
        XCTAssertEqual(target.registrationTokenPath, "/repos/owner/repo/actions/runners/registration-token")
    }

    func testParsesOrganizationTarget() throws {
        let target = try GitHubTarget("acme", scope: "org")

        XCTAssertEqual(target, .organization("acme"))
        XCTAssertEqual(target.displayName, "acme")
        XCTAssertEqual(target.scopeName, "org")
        XCTAssertEqual(target.listRunnersPath, "/orgs/acme/actions/runners?per_page=1")
        XCTAssertEqual(target.registrationTokenPath, "/orgs/acme/actions/runners/registration-token")
    }

    func testRejectsOneSegmentRepositoryTarget() {
        XCTAssertThrowsError(try GitHubTarget("repo", scope: "repo")) { error in
            XCTAssertEqual(error as? RunnerctlError, .usage("Repository targets must be written as owner/repo."))
        }
    }
}
