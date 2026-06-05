# Agent Layer Decisions

This document closes the seven open questions surfaced in `agent-conventions-findings.md`. These are locked decisions; the architecture sketch, roadmap, and goals doc should be updated to reflect them.

## Decisions

### 1. Skill source layout: symlinks
If skills are ever authored, they live at a single canonical location (e.g. `/skills/<verb>/SKILL.md`) and are symlinked into per-agent vendor paths.

**Note:** per decision #5 (no deep integration), the initial scope has no skills. This decision is a forward-compatibility guideline only.

### 2. MCP server: skip for v1
We will not build a `runnerctl mcp` subcommand or ship MCP server declarations (`.mcp.json`, `.cursor/mcp.json`, `.vscode/mcp.json`, `.codex/config.toml`).

**Reasoning:** the CLI surface is intentionally small (five verbs). `AGENTS.md` + clear `--help` + first-class `--json` output is sufficient for an LLM to compose commands correctly. MCP is polish, not core. Revisit only if real friction emerges from real users.

**Implication:** the agent layer relies entirely on AGENTS.md routing plus shell exec of `runnerctl` with proper flags. The CLI's `--json` discipline (goal #14) is now load-bearing.

### 3. Adapter detection: dynamic
Per-agent adapter files (`CLAUDE.md`, `GEMINI.md`, `.github/copilot-instructions.md`, `.cursorrules`, `.clinerules`, etc.) are NOT shipped in the runnerctl source repo. Instead, the CLI provides a subcommand (working name `runnerctl agents init`) that:

- Detects which AI coding agents are installed on the current machine.
- Generates the appropriate adapter files in the current repository.
- Is idempotent: re-running updates existing adapters cleanly without clobbering user content.

**The runnerctl source repo itself ships only:**
- `AGENTS.md` — the universal source of truth
- `CLAUDE.md` — thin adapter, because the maintainer uses Claude Code daily and dogfoods every iteration there

### 4. Session-start orient behavior: terse JSON
`scripts/session-start.sh` (and any future per-agent variant) emits terse machine-readable JSON when `--agent` is set or any vendor session env var is detected (`CLAUDECODE`, `CLINE_ACTIVE`, `CURSOR_PROJECT_DIR`, `RUNNERHUB_AGENT`). No menus, no prompts, no spinners. The menu lives in AGENTS.md; the agent surfaces it on demand.

### 5. No deep integration tier
No per-agent skill authoring. No per-agent SessionStart hook configs. No `.claude/skills/`, no `.codex/skills/`, no `.cursor/skills/`, no Cline plugin. The agent layer is intentionally thin: AGENTS.md is the source of truth; the agent's own LLM does the natural-language → command routing using the table in AGENTS.md.

### 6. No telemetry
The CLI does not record `RUNNERHUB_AGENT` or any other usage data. The env var is used in-process for the agent-output contract (terse JSON mode) only, and is not persisted.

### 7. Distribution: generated dynamically
Confirmed by decision #3. No agent-specific directories are committed to the runnerctl source repo except `CLAUDE.md` and `AGENTS.md`.

## Resulting Architecture

The full agent layer reduces to:

```text
/AGENTS.md                                  # source of truth — ~150 lines, six sections
/CLAUDE.md                                  # thin adapter for maintainer's dogfooding
/scripts/session-start.sh                   # emits terse JSON when --agent or vendor env var is set
+ CLI subcommand: `runnerctl agents init`   # dynamic adapter generation in user repos
```

Removed compared to the research recommendation:

- `/skills/<verb>/SKILL.md` canonical sources and per-vendor symlinks
- `/.claude/settings.json` SessionStart hook (locked: excluded)
- `/.claude/skills/*` and `/.agents/skills/*`
- `/.codex/hooks.json`
- `runnerctl mcp` subcommand and all MCP declarations

Added:

- `runnerctl agents init` dynamic adapter generator

## What This Costs

- The agent layer's quality is now entirely dependent on AGENTS.md being well-written and the CLI being well-designed.
- Without per-agent SessionStart hooks, no agent auto-orients on session open. The agent only learns about runnerctl when the user asks a runner-related question and the agent reads AGENTS.md.
- Without typed MCP tools, the agent may occasionally compose `runnerctl` commands with wrong flags. Mitigated by: crisp CLI flag design, thorough `--help`, and explicit routing examples in AGENTS.md.

## Resolved: SessionStart Hook Excluded

The Claude Code `.claude/settings.json` SessionStart hook is excluded along with all other deep-integration files. AGENTS.md alone carries the agent layer in the runnerctl source repo. The agent learns about runnerctl when the user asks a runner-related question, not on session open. Full minimalism is locked.

## Implications For Other Docs

- `goals-and-non-goals.md` — add a new non-goal: "No agent-specific skill files, hook configs, or MCP server in v1. The agent layer is `AGENTS.md` plus a dynamic adapter-generation CLI subcommand."
- `product-roadmap.md` — fold the simplified agent layer into M1 (AGENTS.md + CLAUDE.md + session-start.sh hardening) and M2 (`runnerctl agents init` subcommand). Phase 3 (MCP) is deleted entirely.
- `architecture-sketch.md` — reflect the cross-platform backend plus the thin agent layer.
- `agent-conventions-findings.md` — keep as-is for historical record; this doc supersedes its recommendations.
