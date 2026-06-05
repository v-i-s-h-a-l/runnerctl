# Architecture Sketch

## System Shape

```text
GitHub API
   |
   | auth, repo/org discovery, registration tokens, runner listing
   v
runnerctl CLI (per-machine, host-agnostic core)
   |
   |--- host backend abstraction
   |       hosts/macos/    (launchd, Xcode/CLT-aware doctor)  [first-class, M1+]
   |       hosts/linux/    (systemd, distro-aware doctor)     [stub until M4]
   |
   |--- local state
   |       ~/.runnerctl/state.json
   |       ~/.runnerctl/runners/<target>/
   |
   |--- agent onboarding layer
           AGENTS.md, CLAUDE.md (shipped in this repo)
           scripts/session-start.sh (terse JSON when --agent set)
           runnerctl agents init (generates per-agent adapters in user repos)
```

## Local Components

- **`runnerctl` CLI** — single binary per machine; scriptable setup, status, repair, lifecycle.
- **Host backend abstraction** — `hosts/macos/` and `hosts/linux/` implementing one common interface. Linux is a stub until M4.
- **Local state directory** — records registered repos/orgs, runner directories, labels, service names, last health check. Plain-text, human-readable, versioned schema.
- **Health checker (`doctor`)** — host-specific readiness diagnostics with copy-pasteable remediation.
- **Service manager** — wraps OS-native service install / start / stop / uninstall through the host backend.
- **Agent onboarding layer** — `AGENTS.md` and `CLAUDE.md` shipped in the runnerctl source repo; `runnerctl agents init` generates per-agent adapters in user target repos based on detected agents.

## GitHub Integration

Authentication uses one or more of (final decision in `cli-ux-decisions.md`):

- Reuse the `gh` CLI session if present.
- OAuth device flow.
- Personal access token paste.

A GitHub App is explicitly **not** in scope — it would add an account-system layer that conflicts with the "single trusted machine" framing.

## Runner Registration Model

GitHub supports two scopes the CLI must handle as one unified surface:

- **Repository-scope** — per-repo registration; no shared runners across repos.
- **Organization-scope** — one runner serves all repos in the organization.

The CLI handles both as `runnerctl add <target>`, disambiguating repo vs org from the target string format (or via an explicit `--scope` flag when ambiguous).

## Host Backend Abstraction

```text
hosts/
  macos/       # launchd, Xcode/CLT/Homebrew detection, simulator awareness — first-class, M1+
  linux/       # systemd, package-manager detection (apt/dnf), glibc check — stub until M4
```

Each backend implements:

- `install_service(runner_id, runner_dir, labels)`
- `start_service(runner_id)` / `stop_service(runner_id)`
- `uninstall_service(runner_id)`
- `service_status(runner_id)`
- `host_doctor_checks() -> [Check]` — host-specific readiness signals

The core CLI logic (GitHub API, state, lifecycle, label management) is host-agnostic.

## Runner Directory Layout

```text
~/.runnerctl/
  state.json                     # versioned local state schema
  runners/
    repo-owner-repo-a/
    org-example/
```

On Linux, the user-config base honors XDG conventions when set; final path locked in `cli-ux-decisions.md`.

Each runner registration gets its own working directory, OS service, and label set. The product does not enable parallel runners on one machine by default; concurrency is opt-in.

## Agent Onboarding Layer

The agent-orchestration goal (#10) is delivered through:

- **`AGENTS.md` at repo root** — universal cross-agent source of truth. Six fixed sections: project identity, hard safety rules, canonical command menu, NL→command routing table, agent-output contract, pointer to canonical context.
- **`CLAUDE.md` at repo root** — thin adapter pointing at `docs/00-context/agent-startup.md` (mirrors the existing convention).
- **`scripts/session-start.sh`** — emits terse JSON status when `--agent` is set or any vendor session env var is detected (`CLAUDECODE`, `CLINE_ACTIVE`, `CURSOR_PROJECT_DIR`, `RUNNERHUB_AGENT`).
- **`runnerctl agents init`** — CLI subcommand that detects installed AI coding agents (Claude Code, Cursor, Codex CLI, GitHub Copilot, Cline, Aider) on the current machine and generates per-agent adapter files in the user's current repository. Idempotent.

Explicitly absent (see `agent-layer-decisions.md`): skill files, SessionStart hooks for any agent, MCP server.

The CLI's `--json` output discipline (goal #14) is now load-bearing for the agent layer — without typed MCP tools, agents shell out for everything and rely on parseable output.

## Security Model

- Default to private repositories only.
- Warn before connecting public repositories.
- Warn about fork-PR workflows on self-hosted runners.
- Never store GitHub registration tokens after use.
- Local state stores only least-sensitive metadata.
- Treat runner workspaces as persistent unless explicitly cleaned.
- `--dry-run` available on every command (goal #13).
- `remove` and other destructive ops require confirmation unless `--yes` is passed.
- Provide cleanup commands for workspaces, caches, and logs.
- No telemetry; `RUNNERHUB_AGENT` is used in-process only and not persisted.
