# Runnerctl Agent Instructions

Runnerctl is meant to be operated through natural language in an AI coding agent. The CLI is the canonical execution layer, but the preferred user experience is: the user opens this repository in an agent and asks for runner lifecycle work in plain English.

## Startup

Before making changes or running lifecycle operations, read and follow:

```text
docs/00-context/agent-startup.md
```

Then run the read-only startup helper for current status:

```sh
./scripts/session-start.sh
```

All durable project memory belongs under `docs/`. Do not store important context only in one agent's private memory.

## Current Command Surface

Use `--json` for Runnerctl commands whenever possible.

Implemented now:

```sh
swift run runnerctl --help
swift run runnerctl login --json
swift run runnerctl login --check-target OWNER/REPO --json
swift run runnerctl login --check-target ORG --scope org --json
swift run runnerctl doctor --json
```

Planned but not implemented yet:

```sh
runnerctl add <target>
runnerctl list
runnerctl status [target]
runnerctl repair <target>
runnerctl remove <target>
runnerctl update runner
runnerctl update self
runnerctl agents init
```

Until a release binary exists, use `swift run runnerctl ...` from the repository root.

## Natural-Language Routing

Map user requests like this:

| User asks | Agent should do |
| --- | --- |
| "Where are we?" / "status?" | Run startup helper, inspect roadmap/status, summarize current milestone and next step. |
| "Check this Mac" / "Is this machine ready?" | Run `swift run runnerctl doctor --json`, summarize host/state/auth/runner checks and fixes. |
| "Log in" / "Use my GitHub account" | Run `swift run runnerctl login --json`; if target is mentioned, include `--check-target`. |
| "Can this account manage runners for OWNER/REPO?" | Run `swift run runnerctl login --check-target OWNER/REPO --json`. |
| "Can this account manage org runners for ORG?" | Run `swift run runnerctl login --check-target ORG --scope org --json`. |
| "Set up a runner for OWNER/REPO" | Current state: explain `add` is not implemented yet, then run `doctor` and `login --check-target OWNER/REPO` to prepare. |
| "List/status/repair/remove runners" | Current state: explain the lifecycle command is planned but not implemented, then run `doctor` for available local diagnostics. |
| "What should we build next?" | Read roadmap and recent docs, then recommend the next scoped milestone task. |

## Output Contract

- Do not make the user memorize commands.
- Explain what you ran and what it means in plain English.
- Ask only for missing target/account/destructive-confirmation details.
- For destructive future commands, show the planned local and GitHub changes before executing.
- If a command is not implemented yet, say that directly and run the closest available readiness or permission check.
