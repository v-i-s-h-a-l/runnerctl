import Foundation

/// Global options shared by every command.
struct GlobalOptions: Equatable {
    var json = false
    var verbose = false
    var dryRun = false
    var yes = false
    var profile: String?
    var home: String?
}

/// A parsed command invocation.
struct ParsedInvocation: Equatable {
    var command: String?
    var commandArguments: [String]
    var global: GlobalOptions
}

/// Parses Runnerctl's lightweight command-line grammar.
struct CommandParser {
    /// Parses raw command-line arguments.
    func parse(_ arguments: [String]) throws -> ParsedInvocation {
        var global = GlobalOptions()
        var positional: [String] = []
        var index = 0

        while index < arguments.count {
            let argument = arguments[index]
            switch argument {
            case "--json":
                global.json = true
            case "--verbose":
                global.verbose = true
            case "--dry-run":
                global.dryRun = true
            case "--yes":
                global.yes = true
            case "--profile":
                index += 1
                guard index < arguments.count else {
                    throw RunnerctlError.usage("Missing value for --profile.")
                }
                global.profile = arguments[index]
            case "--home":
                index += 1
                guard index < arguments.count else {
                    throw RunnerctlError.usage("Missing value for --home.")
                }
                global.home = arguments[index]
            default:
                positional.append(argument)
            }
            index += 1
        }

        return ParsedInvocation(
            command: positional.first,
            commandArguments: Array(positional.dropFirst()),
            global: global
        )
    }
}

/// Options specific to `runnerctl login`.
struct LoginOptions: Equatable {
    var profile: String?
    var account: String?

    /// Parses login-specific options.
    static func parse(_ arguments: [String]) throws -> LoginOptions {
        var options = LoginOptions()
        var index = 0

        while index < arguments.count {
            switch arguments[index] {
            case "--profile":
                index += 1
                guard index < arguments.count else {
                    throw RunnerctlError.usage("Missing value for --profile.")
                }
                options.profile = arguments[index]
            case "--account":
                index += 1
                guard index < arguments.count else {
                    throw RunnerctlError.usage("Missing value for --account.")
                }
                options.account = arguments[index]
            case "--hostname", "--with-token", "--refresh":
                throw RunnerctlError.usage("`\(arguments[index])` is documented for login but is not implemented in this M1 scaffold.")
            default:
                throw RunnerctlError.usage("Unknown login option '\(arguments[index])'.")
            }
            index += 1
        }

        return options
    }
}
