import Foundation

/// A GitHub runner target.
enum GitHubTarget: Equatable {
    case repository(owner: String, repo: String)
    case organization(String)

    /// Creates a target from user input and optional scope.
    init(_ rawValue: String, scope: String?) throws {
        let parts = rawValue.split(separator: "/", omittingEmptySubsequences: false).map(String.init)

        switch (parts.count, scope) {
        case (2, nil), (2, "repo"):
            guard !parts[0].isEmpty, !parts[1].isEmpty else {
                throw RunnerctlError.usage("Repository targets must be written as owner/repo.")
            }
            self = .repository(owner: parts[0], repo: parts[1])
        case (1, nil), (1, "org"):
            guard !parts[0].isEmpty else {
                throw RunnerctlError.usage("Organization targets must not be empty.")
            }
            self = .organization(parts[0])
        case (1, "repo"):
            throw RunnerctlError.usage("Repository targets must be written as owner/repo.")
        case (2, "org"):
            throw RunnerctlError.usage("Organization targets must be written as a single org name.")
        default:
            throw RunnerctlError.usage("Targets must be either owner/repo or org.")
        }
    }

    /// The user-facing target string.
    var displayName: String {
        switch self {
        case .repository(let owner, let repo):
            return "\(owner)/\(repo)"
        case .organization(let org):
            return org
        }
    }

    /// The target scope as a stable string.
    var scopeName: String {
        switch self {
        case .repository:
            return "repo"
        case .organization:
            return "org"
        }
    }

    var listRunnersPath: String {
        switch self {
        case .repository(let owner, let repo):
            return "/repos/\(owner.githubPathEscaped)/\(repo.githubPathEscaped)/actions/runners?per_page=1"
        case .organization(let org):
            return "/orgs/\(org.githubPathEscaped)/actions/runners?per_page=1"
        }
    }

    var registrationTokenPath: String {
        switch self {
        case .repository(let owner, let repo):
            return "/repos/\(owner.githubPathEscaped)/\(repo.githubPathEscaped)/actions/runners/registration-token"
        case .organization(let org):
            return "/orgs/\(org.githubPathEscaped)/actions/runners/registration-token"
        }
    }
}

private extension String {
    var githubPathEscaped: String {
        addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? self
    }
}
