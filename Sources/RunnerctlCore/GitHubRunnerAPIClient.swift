import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A response returned by GitHub's REST API.
struct GitHubAPIResponse: Equatable {
    var statusCode: Int
    var body: Data
}

/// Executes GitHub API requests.
protocol GitHubAPITransport {
    /// Sends an HTTP request to GitHub.
    func send(method: String, path: String, token: String) -> GitHubAPIResponse
}

/// URLSession-backed GitHub API transport.
struct URLSessionGitHubAPITransport: GitHubAPITransport {
    var baseURL = URL(string: "https://api.github.com")!

    func send(method: String, path: String, token: String) -> GitHubAPIResponse {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            return GitHubAPIResponse(statusCode: 0, body: Data())
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("runnerctl", forHTTPHeaderField: "User-Agent")

        let semaphore = DispatchSemaphore(value: 0)
        let responseBox = GitHubAPIResponseBox()

        URLSession.shared.dataTask(with: request) { data, response, _ in
            responseBox.body = data ?? Data()
            responseBox.statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            semaphore.signal()
        }.resume()

        semaphore.wait()
        return GitHubAPIResponse(statusCode: responseBox.statusCode, body: responseBox.body)
    }
}

private final class GitHubAPIResponseBox: @unchecked Sendable {
    var statusCode = 0
    var body = Data()
}

/// Checks GitHub self-hosted runner API permissions for targets.
struct GitHubRunnerAPIClient {
    let transport: GitHubAPITransport

    /// Verifies that the token can list runners and create a registration token.
    func checkRunnerPermissions(for target: GitHubTarget, token: String) throws -> TargetPermissionCheck {
        let listResponse = transport.send(method: "GET", path: target.listRunnersPath, token: token)
        try validate(listResponse, operation: "list self-hosted runners", target: target)

        let tokenResponse = transport.send(method: "POST", path: target.registrationTokenPath, token: token)
        try validate(tokenResponse, operation: "create a registration token", target: target)

        return TargetPermissionCheck(
            target: target.displayName,
            scope: target.scopeName,
            listRunners: true,
            createRegistrationToken: true
        )
    }

    private func validate(_ response: GitHubAPIResponse, operation: String, target: GitHubTarget) throws {
        switch response.statusCode {
        case 200, 201:
            return
        case 401, 403, 404:
            throw RunnerctlError.githubPermission(
                message: "GitHub refused to \(operation) for \(target.displayName).",
                fix: permissionFix(for: target)
            )
        case 0:
            throw RunnerctlError.githubUnavailable(
                message: "Could not reach GitHub while trying to \(operation) for \(target.displayName).",
                fix: "Check network connectivity, proxy, VPN, or firewall settings."
            )
        default:
            throw RunnerctlError.githubUnavailable(
                message: "GitHub returned HTTP \(response.statusCode) while trying to \(operation) for \(target.displayName).",
                fix: "Run `runnerctl login --check-target \(target.displayName) --verbose` after confirming GitHub status."
            )
        }
    }

    private func permissionFix(for target: GitHubTarget) -> String {
        switch target {
        case .repository:
            return "Use an account with repository admin access and a token that can manage Actions self-hosted runners for this repo."
        case .organization:
            return "Use an organization admin account or a fine-grained token with organization Self-hosted runners write permission."
        }
    }
}

/// Retrieves GitHub auth tokens from `gh`.
struct GitHubCLITokenProvider {
    let executor: CommandExecuting

    /// Returns a token for a GitHub CLI account.
    func token(for credential: GitHubCredential) throws -> String {
        let result = executor.run("/usr/bin/env", arguments: [
            "gh",
            "auth",
            "token",
            "--hostname",
            credential.hostname,
            "--user",
            credential.login
        ])

        guard result.exitCode == 0 else {
            throw RunnerctlError.authUnavailable("Could not read a GitHub token for account \(credential.login).")
        }

        let token = result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !token.isEmpty else {
            throw RunnerctlError.authUnavailable("GitHub CLI returned an empty token for account \(credential.login).")
        }
        return token
    }
}
