import XCTest
@testable import RunnerctlCore

final class GitHubRunnerAPIClientTests: XCTestCase {
    func testChecksRepositoryRunnerPermissions() throws {
        let transport = RecordingGitHubTransport(responses: [
            "GET /repos/owner/repo/actions/runners?per_page=1": GitHubAPIResponse(statusCode: 200, body: Data()),
            "POST /repos/owner/repo/actions/runners/registration-token": GitHubAPIResponse(statusCode: 201, body: Data())
        ])
        let client = GitHubRunnerAPIClient(transport: transport)

        let check = try client.checkRunnerPermissions(for: .repository(owner: "owner", repo: "repo"), token: "token")

        XCTAssertEqual(check, TargetPermissionCheck(target: "owner/repo", scope: "repo", listRunners: true, createRegistrationToken: true))
    }

    func testPermissionFailureIsTyped() {
        let transport = RecordingGitHubTransport(responses: [
            "GET /orgs/acme/actions/runners?per_page=1": GitHubAPIResponse(statusCode: 403, body: Data())
        ])
        let client = GitHubRunnerAPIClient(transport: transport)

        XCTAssertThrowsError(try client.checkRunnerPermissions(for: .organization("acme"), token: "token")) { error in
            guard case .githubPermission(let message, let fix) = error as? RunnerctlError else {
                return XCTFail("Expected githubPermission, got \(error)")
            }
            XCTAssertTrue(message.contains("list self-hosted runners"))
            XCTAssertTrue(fix.contains("organization"))
        }
    }
}

final class RecordingGitHubTransport: GitHubAPITransport {
    var responses: [String: GitHubAPIResponse]

    init(responses: [String: GitHubAPIResponse]) {
        self.responses = responses
    }

    func send(method: String, path: String, token: String) -> GitHubAPIResponse {
        responses["\(method) \(path)"] ?? GitHubAPIResponse(statusCode: 500, body: Data())
    }
}
