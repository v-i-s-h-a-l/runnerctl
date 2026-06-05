import XCTest
@testable import RunnerctlCore

final class GitHubCLIAuthTests: XCTestCase {
    func testParsesActiveCredentialFromGitHubCLIStatus() {
        let output = """
        github.com
          ✓ Logged in to github.com account v-i-s-h-a-l (/tmp/hosts.yml)
          - Active account: true
          - Git operations protocol: https

          X Failed to log in to github.com account stale (default)
          - Active account: false
        """

        let credentials = GitHubCLICredentialDetector.parseAuthStatus(output)

        XCTAssertEqual(credentials.count, 1)
        XCTAssertEqual(credentials[0].login, "v-i-s-h-a-l")
        XCTAssertEqual(credentials[0].hostname, "github.com")
        XCTAssertTrue(credentials[0].isActive)
    }
}
