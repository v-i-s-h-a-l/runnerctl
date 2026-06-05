# Goals and Non-Goals

This document is the locked scope for Runnerctl. The product is intentionally minimal: what is listed here is the finished product, not a stepping stone to a larger one.

It supersedes the earlier MVP framing in `mvp-scope.md`.

## Goals

### Primary Goals

1. **Lifecycle management** — register, list, inspect, repair, and remove self-hosted runners on the local machine through a single CLI.
2. **Multi-target registration** — a single machine can host runners for any combination of personal repositories, organization repositories, and organization-scope (org-level) runners.
3. **Multi-host platform support** — macOS first-class, Linux second-class, behind one common CLI surface.
4. **Service integration** — runners run as OS-level services (launchd on macOS, systemd on Linux), survive reboot, restart on failure, log to standard locations.
5. **Idempotency** — every command is safe to re-run. Repeating `add` on an existing target is a no-op or a clean reconfiguration, never a corruption.
6. **Host readiness diagnostics (`doctor`)** — diagnose whether the host machine is ready for the kinds of jobs the user wants to run, with plain-English remediation for common failures.
7. **Runner version maintenance** — detect when the registered runner binary has fallen out of GitHub's supported window and update it cleanly.
8. **Safe defaults** — private repositories only by default, clear warnings before public-repo or fork-PR scenarios, no persistent secrets stored beyond what is strictly required.
9. **Distribution polish** — install via Homebrew (macOS) and release tarball or shell installer (Linux). A stranger can install and use it without contacting the maintainer.
10. **Agent-orchestration onboarding layer** — when a user opens this repository inside an AI coding agent (Claude Code, Cursor, Aider, Codex CLI, GitHub Copilot, Cline, and others), the agent auto-orients to the project, offers a menu of available runner-lifecycle actions, and routes natural-language intent ("set up a runner for my iOS repo") to the underlying CLI. The CLI remains the canonical execution layer; the agent layer is documentation plus light scripting (`AGENTS.md`, agent-specific skills, hooks, and an optional MCP server) that points the agent at the CLI — never a duplicate execution path.

### Secondary Goals

11. **Honest error messages** — failure modes name the underlying cause and the next concrete step.
12. **Plain-text local state** — the tool's state directory is human-readable and recoverable by hand if needed.
13. **Operational transparency** — every command can print what it is about to do (`--dry-run`) and what it did.
14. **Machine-readable output** — every command supports `--json` for scripting use.

## Non-Goals

The following are explicitly out of scope. Each one is plausible and tempting, and each one would turn this into a different product.

- **Web dashboard or native GUI.** The product is a CLI. No browser UI, no menu bar app, no Electron shell.
- **Cross-machine orchestration.** The CLI manages the machine it is installed on. It does not SSH to other machines, run a daemon that controls remote hosts, or maintain shared state across machines.
- **Workflow YAML modification.** The tool does not read, edit, or generate `.github/workflows/*.yml`. Users target self-hosted runners by editing their own workflows.
- **Workflow scanning or migration tooling.** No scanner for `runs-on: macos-latest` usage. No automated PRs against repositories.
- **Job-level observability.** GitHub Actions already shows job logs, durations, and status. The tool does not duplicate that surface.
- **Autoscaling or ephemeral runners.** Runners are persistent and the user owns the host.
- **Public pull request sandboxing.** Self-hosted runners are not safe for untrusted forked PR code. The tool warns about this scenario and refuses to make it easy.
- **Windows host support.** May be reconsidered later. Out for now.
- **Enterprise runner groups, access policies, and fleet governance.** Out of scope; this is a different product class.
- **A hosted SaaS layer.** No remote backend, no telemetry endpoint, no account system beyond the user's GitHub identity.
- **Build signing, code signing, or Xcode license automation beyond detection.** The tool reports these as readiness signals; it does not handle them.
- **Building our own AI agent, agent runtime, or LLM integration.** The agent-orchestration layer (goal 10) integrates with existing agents through their conventions. We do not host, wrap, or ship a model.
- **Agent-specific skill files, hook configs, or MCP server.** Goal 10 is delivered through `AGENTS.md` (universal source of truth) plus a dynamic adapter-generation CLI subcommand. No `.claude/skills/`, no `.codex/skills/`, no `.cursor/skills/`, no SessionStart hooks, no `runnerctl mcp` server. May be revisited only if real users surface friction.

## Supported Hosts

- macOS, Apple Silicon (`arm64`) — first-class
- macOS, Intel (`x86_64`) — first-class
- Linux, `x86_64`, modern systemd distributions (Ubuntu LTS, Debian stable, Fedora) — second-class
- Linux, `arm64`, same distributions — second-class
- Anything else — not supported

## Definition Of Done

The product is considered finished when:

- A new user on a supported host can install the CLI, authenticate with GitHub, register runners against a mix of repos and orgs, and see jobs running, without consulting external documentation beyond the tool's own help output.
- `doctor` correctly diagnoses the common readiness failures (Xcode license, missing command line tools, low disk, broken service plist or unit, runner version drift, network reachability) on both supported host families.
- All lifecycle commands (`add`, `list`, `status`, `repair`, `remove`, `update`) are idempotent and safe to re-run.
- Both macOS and Linux backends pass the same end-to-end acceptance suite.
- The README is sufficient for a stranger to onboard without contacting the maintainer.

There is no roadmap beyond "finished." Future direction, if any, would be a different product.
