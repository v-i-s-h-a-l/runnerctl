# Agent-First User Guide

## Core Idea

Runnerctl should feel like talking to an operator who knows the CLI, not like memorizing another command reference.

The user clones this repository onto the machine that should host GitHub Actions runners, opens the repository in an AI coding agent, and asks for runner lifecycle work in natural language. The agent reads `AGENTS.md`, checks the durable docs under `docs/`, and runs the underlying commands.

## Recommended User Workflow

1. Clone `runnerctl` on the runner host machine.
2. Open the repository directory in an AI coding agent.
3. Ask for the task in plain English.
4. Let the agent run checks, explain results, and ask only for genuinely missing information.

The user should not need to remember command names or flags for normal operation.

## Example Requests

### Readiness

```text
Check whether this Mac is ready to run GitHub Actions jobs.
```

Expected agent behavior:

- Run the startup routine.
- Run the current `doctor` path.
- Summarize host, state, auth, and runner readiness.
- Explain exact fixes for warnings or failures.

### GitHub Access

```text
Verify that my GitHub account can manage runners for OWNER/REPO.
```

Expected agent behavior:

- Detect or refresh the GitHub CLI profile.
- Check repository or organization runner API permissions.
- Report whether Runnerctl can list runners and create a registration token.

### Future Runner Setup

```text
Set up a self-hosted runner for OWNER/REPO.
```

Expected agent behavior once `add` is implemented:

- Confirm the target and scope.
- Check host readiness.
- Check GitHub permissions.
- Explain the planned labels and runner directory.
- Run the underlying add operation.
- Tell the user which workflow `runs-on` labels to use.

### Future Repair

```text
Repair the runner for OWNER/REPO.
```

Expected agent behavior once `repair` is implemented:

- Inspect local state and GitHub runner state.
- Identify whether the issue is auth, service, runner directory, labels, or runner binary drift.
- Run the safest repair strategy or ask before destructive cleanup.

## Direct CLI Use

Direct CLI use remains supported for power users, scripts, and debugging. It is not the preferred user-facing path.

The agent may run commands such as:

```sh
swift run runnerctl doctor --json
swift run runnerctl login --json
swift run runnerctl login --check-target OWNER/REPO --json
```

As the product matures and ships a binary, those become:

```sh
runnerctl doctor --json
runnerctl login --json
runnerctl login --check-target OWNER/REPO --json
```

## Agent Behavior Rules

- Prefer natural-language summaries over dumping command output.
- Use `--json` when running Runnerctl so results are parseable.
- Ask for only missing facts: target repository, organization scope, account choice, or destructive confirmation.
- Never hide destructive actions. Explain what will be deleted or changed before running them.
- Keep durable decisions and findings under `docs/`, not in private agent memory.
