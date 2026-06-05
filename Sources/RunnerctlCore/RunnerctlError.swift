import Foundation

/// A typed command error with user-facing remediation.
enum RunnerctlError: Error, Equatable {
    case usage(String)
    case authUnavailable(String)
    case authAccountNotFound(String)
    case githubPermission(message: String, fix: String)
    case githubUnavailable(message: String, fix: String)
    case state(String)
    case unexpected(String)

    var code: String {
        switch self {
        case .usage:
            return "usage"
        case .authUnavailable:
            return "auth.unavailable"
        case .authAccountNotFound:
            return "auth.account_not_found"
        case .githubPermission:
            return "github.permission_missing"
        case .githubUnavailable:
            return "github.unavailable"
        case .state:
            return "state.error"
        case .unexpected:
            return "unexpected"
        }
    }

    var message: String {
        switch self {
        case .usage(let message), .authUnavailable(let message), .authAccountNotFound(let message), .state(let message), .unexpected(let message):
            return message
        case .githubPermission(let message, _), .githubUnavailable(let message, _):
            return message
        }
    }

    var fix: String {
        switch self {
        case .usage:
            return "Run `runnerctl --help`."
        case .authUnavailable:
            return "Run `gh auth login`, then `runnerctl login` again."
        case .authAccountNotFound:
            return "Run `gh auth status` and choose an active account with `runnerctl login --account <login>`."
        case .githubPermission(_, let fix), .githubUnavailable(_, let fix):
            return fix
        case .state:
            return "Check RUNNERCTL_HOME or pass `--home <path>` to use a writable state directory."
        case .unexpected:
            return "Re-run with --verbose or file an issue with this output."
        }
    }

    var exitCode: Int {
        switch self {
        case .usage:
            return 2
        case .authUnavailable, .githubPermission, .githubUnavailable, .state, .unexpected:
            return 1
        case .authAccountNotFound:
            return 1
        }
    }

    var rendered: String {
        """
        Problem: \(message)
        Cause:   \(code)
        Fix:     \(fix)
        """
    }
}
