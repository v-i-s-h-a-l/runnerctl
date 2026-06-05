import Foundation

/// Coordinates command parsing, command execution, and output rendering.
public struct RunnerctlApp {
    private let output: OutputWriting
    private let errorOutput: OutputWriting
    private let executor: CommandExecuting
    private let environment: [String: String]

    /// Creates a Runnerctl application using process-backed dependencies.
    public init() {
        self.output = StandardOutput()
        self.errorOutput = StandardError()
        self.executor = ProcessCommandExecutor()
        self.environment = ProcessInfo.processInfo.environment
    }

    /// Creates a Runnerctl application with injected dependencies.
    init(
        output: OutputWriting = StandardOutput(),
        errorOutput: OutputWriting = StandardError(),
        executor: CommandExecuting = ProcessCommandExecutor(),
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) {
        self.output = output
        self.errorOutput = errorOutput
        self.executor = executor
        self.environment = environment
    }

    /// Runs Runnerctl with the supplied command-line arguments.
    public func run(arguments: [String]) -> Int {
        do {
            let invocation = try CommandParser().parse(arguments)
            let home = invocation.global.home ?? environment["RUNNERCTL_HOME"] ?? "\(FileManager.default.homeDirectoryForCurrentUser.path)/.runnerctl"
            let stateStore = StateStore(homePath: home)

            switch invocation.command {
            case nil:
                output.write(Self.rootHelp)
                return 0
            case "help":
                output.write(Self.rootHelp)
                return 0
            case "--help", "-h":
                output.write(Self.rootHelp)
                return 0
            case "login":
                return runLogin(invocation: invocation, stateStore: stateStore)
            case "doctor":
                return runDoctor(invocation: invocation, stateStore: stateStore)
            case "list", "status", "add", "repair", "remove", "update", "logout", "agents":
                return printNotImplemented(command: invocation.command ?? "")
            default:
                throw RunnerctlError.usage("Unknown command '\(invocation.command ?? "")'. Run `runnerctl --help`.")
            }
        } catch let error as RunnerctlError {
            errorOutput.write(error.rendered)
            return error.exitCode
        } catch {
            errorOutput.write("Problem: Unexpected failure\nCause:   \(error)\nFix:     Re-run with --verbose or file an issue with this output.\n")
            return 1
        }
    }

    private func runLogin(invocation: ParsedInvocation, stateStore: StateStore) -> Int {
        do {
            let options = try LoginOptions.parse(invocation.commandArguments)
            let detector = GitHubCLICredentialDetector(executor: executor)
            let credential = try detector.detectCredential(account: options.account)

            var state = try stateStore.loadOrCreate()
            state.upsertProfile(Profile(
                name: invocation.global.profile ?? options.profile ?? "default",
                githubLogin: credential.login,
                hostname: credential.hostname,
                credentialSource: "gh",
                active: credential.isActive,
                updatedAt: Date()
            ))
            try stateStore.save(state)

            let response = LoginResponse(
                schemaVersion: 1,
                command: "login",
                ok: true,
                profile: invocation.global.profile ?? options.profile ?? "default",
                githubLogin: credential.login,
                hostname: credential.hostname,
                credentialSource: "gh",
                warnings: credential.warnings,
                errors: []
            )

            if invocation.global.json {
                try output.writeJSON(response)
            } else {
                output.write("""
                Saved GitHub profile.

                Profile:  \(response.profile)
                Account:  \(response.githubLogin)
                Host:     \(response.hostname)
                Source:   gh

                Next: run `runnerctl doctor`.
                """)
            }
            return 0
        } catch let error as RunnerctlError {
            return renderCommandError(error, json: invocation.global.json, command: "login")
        } catch {
            return renderCommandError(.unexpected(String(describing: error)), json: invocation.global.json, command: "login")
        }
    }

    private func runDoctor(invocation: ParsedInvocation, stateStore: StateStore) -> Int {
        do {
            _ = try stateStore.loadOrCreate()
            let doctor = Doctor(stateStore: stateStore, executor: executor)
            let checks = doctor.runChecks()
            try stateStore.updateLastDoctorRun(Date())
            let summary = DoctorSummary(checks: checks)
            let response = DoctorResponse(
                schemaVersion: 1,
                command: "doctor",
                ok: summary.failCount == 0,
                home: stateStore.homePath,
                checks: checks,
                summary: summary,
                warnings: [],
                errors: []
            )

            if invocation.global.json {
                try output.writeJSON(response)
            } else {
                output.write(HumanDoctorRenderer().render(response))
            }
            return summary.failCount == 0 ? 0 : 1
        } catch let error as RunnerctlError {
            return renderCommandError(error, json: invocation.global.json, command: "doctor")
        } catch {
            return renderCommandError(.unexpected(String(describing: error)), json: invocation.global.json, command: "doctor")
        }
    }

    private func printNotImplemented(command: String) -> Int {
        output.write("""
        `runnerctl \(command)` is part of the locked CLI surface but is not implemented in this M1 scaffold yet.

        Implemented now:
          runnerctl --help
          runnerctl login
          runnerctl doctor
        """)
        return 2
    }

    private func renderCommandError(_ error: RunnerctlError, json: Bool, command: String) -> Int {
        if json {
            let response = ErrorResponse(
                schemaVersion: 1,
                command: command,
                ok: false,
                warnings: [],
                errors: [CommandError(code: error.code, message: error.message, fix: error.fix)]
            )
            do {
                try output.writeJSON(response)
            } catch {
                errorOutput.write(error.localizedDescription)
            }
        } else {
            errorOutput.write(error.rendered)
        }
        return error.exitCode
    }

    private static let rootHelp = """
    Runnerctl - manage self-hosted GitHub Actions runners on this machine.

    Usage:
      runnerctl <command> [options]

    Commands:
      login              Save or refresh a GitHub auth profile.
      doctor             Check host readiness and local runner state.
      add <target>       Register a runner target. (planned)
      list               List local runner targets. (planned)
      status [target]    Show runner and service status. (planned)
      repair <target>    Repair a broken runner target. (planned)
      remove <target>    Remove a runner target. (planned)
      update runner      Update GitHub runner binaries. (planned)
      update self        Update the runnerctl CLI. (planned)
      agents init        Generate thin agent adapter files. (planned)

    Global options:
      --json             Print machine-readable JSON.
      --verbose          Print additional diagnostic detail.
      --dry-run          Show planned changes without mutating state.
      --yes              Skip interactive confirmations.
      --profile <name>   Use a named GitHub profile.
      --home <path>      Use an alternate runnerctl home directory.
    """
}
